require("dotenv").config();

const pool = require("../config/db");
const { extractAreaInfo } = require("../services/geminiExtractor");

const BATCH_SIZE = Number(process.env.STAGING_BATCH_SIZE || 20);

// Xử lý 1 record: gọi Gemini, ghi vào staging, đánh dấu raw.processed = TRUE.
// Lỗi ở 1 record không throw ra ngoài vòng lặp chính - chỉ log lại,
// record đó vẫn còn processed = FALSE và được thử lại ở lần chạy job kế tiếp.
async function processOneRecord(rawRow) {
    const extraction = await extractAreaInfo(rawRow.area_text);

    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        await client.query(
            `
            INSERT INTO electric_outages_staging(
                raw_id,
                normalized_area,
                ward_name,
                subarea_name,
                road_name,
                extraction_result,
                processed_at
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
                rawRow.id,
                rawRow.area_text,
                extraction.ward || null,
                extraction.subarea || null,
                (extraction.streets && extraction.streets[0]) || null,
                JSON.stringify(extraction)
            ]
        );

        await client.query(
            `UPDATE electric_outages_raw SET processed = TRUE WHERE id = $1`,
            [rawRow.id]
        );

        await client.query("COMMIT");
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
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
    console.log(
        `[processRawToStaging] Do giới hạn 5 request/phút của Gemini free tier, ` +
        `ước tính mất khoảng ${Math.ceil((unprocessed.length * 13) / 60)} phút để xử lý hết batch này.`
    );

    let success = 0;
    let failed = 0;

    // Xử lý tuần tự (không Promise.all) để tránh spam Gemini API cùng lúc
    for (const row of unprocessed) {
        try {
            await processOneRecord(row);
            success++;
        } catch (err) {
            failed++;
            console.error(`[processRawToStaging] Lỗi xử lý raw_id=${row.id}:`, err.message);
        }
    }

    console.log(`[processRawToStaging] Hoàn tất: ${success} thành công, ${failed} thất bại`);
}

// Cho phép chạy trực tiếp: node jobs/processRawToStaging.js (dùng với cron 2 lần/ngày)
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