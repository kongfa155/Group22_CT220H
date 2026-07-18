require("dotenv").config();

const pool = require("../config/db");
const { extractAreaInfoBatch } = require("../services/geminiExtractor");

const BATCH_SIZE = Number(process.env.STAGING_BATCH_SIZE || 80);
// Số area_text gộp vào 1 request Gemini. Free tier chỉ 20 request/ngày,
// nên batch càng lớn càng tiết kiệm quota - nhưng batch quá lớn dễ bị
// Gemini trả sai số lượng phần tử. 15-20 là mức an toàn.
const AI_BATCH_SIZE = Number(process.env.GEMINI_AI_BATCH_SIZE || 15);

/**
 * Tìm kết quả extraction ĐÃ CÓ SẴN cho area_text giống hệt (đã xử lý
 * trước đó, kể cả từ record khác) - tái sử dụng thay vì gọi AI lại.
 * Rất hiệu quả vì nhiều outage lặp lại cùng 1 khu vực qua các ngày.
 */
async function findCachedExtractions(areaTexts) {
    if (areaTexts.length === 0) return new Map();

    const { rows } = await pool.query(
        `
        SELECT DISTINCT ON (r.area_text) r.area_text, s.extraction_result
        FROM electric_outages_raw r
        JOIN electric_outages_staging s ON s.raw_id = r.id
        WHERE r.area_text = ANY($1::text[])
        ORDER BY r.area_text, s.processed_at DESC
        `,
        [areaTexts]
    );

    const cache = new Map();
    for (const row of rows) {
        cache.set(row.area_text, row.extraction_result);
    }
    return cache;
}

async function saveExtraction(rawId, areaText, extraction) {
    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        await client.query(
            `
            INSERT INTO electric_outages_staging(
                raw_id, normalized_area, ward_name, subarea_name,
                road_name, extraction_result, processed_at
            )
            VALUES ($1,$2,$3,$4,$5,$6, now())
            ON CONFLICT (raw_id) DO UPDATE SET
                normalized_area = EXCLUDED.normalized_area,
                ward_name = EXCLUDED.ward_name,
                subarea_name = EXCLUDED.subarea_name,
                road_name = EXCLUDED.road_name,
                extraction_result = EXCLUDED.extraction_result,
                processed_at = now()
            `,
            [
                rawId,
                areaText,
                extraction.ward || null,
                extraction.subarea || null,
                (extraction.streets && extraction.streets[0]) || null,
                JSON.stringify(extraction)
            ]
        );

        await client.query(`UPDATE electric_outages_raw SET processed = TRUE WHERE id = $1`, [rawId]);
        await client.query("COMMIT");
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
}

/**
 * Xử lý 1 lô (batch) record: tách phần đã có cache (dùng lại luôn,
 * không tốn request AI) và phần chưa có (gộp vào 1 request Gemini).
 */
async function processBatch(rows) {
    let success = 0;
    let failed = 0;

    const areaTexts = rows.map((r) => r.area_text);
    const cache = await findCachedExtractions(areaTexts);

    const toCall = []; // record chưa có cache, cần gọi AI

    for (const row of rows) {
        if (cache.has(row.area_text)) {
            try {
                await saveExtraction(row.id, row.area_text, cache.get(row.area_text));
                success++;
                console.log(`[processRawToStaging] raw_id=${row.id}: dùng lại cache (không tốn request AI)`);
            } catch (err) {
                failed++;
                console.error(`[processRawToStaging] Lỗi lưu cache raw_id=${row.id}:`, err.message);
            }
        } else {
            toCall.push(row);
        }
    }

    // Gộp phần còn lại thành các lô nhỏ gửi Gemini (AI_BATCH_SIZE record/request)
    for (let i = 0; i < toCall.length; i += AI_BATCH_SIZE) {
        const chunk = toCall.slice(i, i + AI_BATCH_SIZE);
        try {
            const extractions = await extractAreaInfoBatch(chunk.map((r) => r.area_text));

            for (let j = 0; j < chunk.length; j++) {
                try {
                    await saveExtraction(chunk[j].id, chunk[j].area_text, extractions[j]);
                    success++;
                } catch (err) {
                    failed++;
                    console.error(`[processRawToStaging] Lỗi lưu raw_id=${chunk[j].id}:`, err.message);
                }
            }
        } catch (err) {
            // Cả lô lỗi (VD Gemini trả sai số lượng) - thử lại từng record
            // riêng lẻ trong lô này thay vì bỏ hết, để không mất toàn bộ lô
            // chỉ vì 1 record có nội dung lạ làm Gemini trả sai định dạng.
            console.error(
                `[processRawToStaging] Lỗi xử lý lô ${chunk.length} record, thử lại từng record riêng:`,
                err.message
            );
            const { extractAreaInfo } = require("../services/geminiExtractor");
            for (const row of chunk) {
                try {
                    const extraction = await extractAreaInfo(row.area_text);
                    await saveExtraction(row.id, row.area_text, extraction);
                    success++;
                } catch (innerErr) {
                    failed++;
                    console.error(`[processRawToStaging] Lỗi xử lý raw_id=${row.id}:`, innerErr.message);
                }
            }
        }
    }

    return { success, failed, cachedCount: rows.length - toCall.length, aiCalledCount: toCall.length };
}

async function run() {
    const { rows: unprocessed } = await pool.query(
        `
        SELECT id, area_text FROM electric_outages_raw
        WHERE processed = FALSE
        ORDER BY scraped_at ASC
        LIMIT $1
        `,
        [BATCH_SIZE]
    );

    console.log(`[processRawToStaging] Tìm thấy ${unprocessed.length} record chưa xử lý`);

    const result = await processBatch(unprocessed);

    const estimatedRequests = Math.ceil(result.aiCalledCount / AI_BATCH_SIZE);
    console.log(
        `[processRawToStaging] Hoàn tất: ${result.success} thành công, ${result.failed} thất bại ` +
        `(${result.cachedCount} dùng cache, ${result.aiCalledCount} gọi AI qua ~${estimatedRequests} request)`
    );
}

if (require.main === module) {
    run()
        .then(() => pool.end())
        .catch((err) => {
            console.error("[processRawToStaging] Lỗi không xử lý được:", err);
            pool.end();
            process.exit(1);
        });
}

module.exports = { run };