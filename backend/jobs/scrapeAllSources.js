//File này tổng hợp tất cả các file thực hiện cào dữ liệu

require("dotenv").config();
//Kết nối db
const pool = require("../config/db"); 
const { fetchAllSources } = require("../services/sourceFetcher");
const { extractRecords } = require("../services/recordExtractor");
const { toPostgresDate, toPostgresTime } = require("../utils/parseNormalizedDatetime");
const { computeContentHash } = require("../utils/contentHash");
// 
//  Insert 1 record đã parse vào electric_outages_raw.
//  Dùng ON CONFLICT DO NOTHING theo content_hash (xem sql/001_add_dedup_hash.sql) để 3 nguồn không tạo trùng lặp khi cùng đưa tin 1 outage giống hệt nhau, và để chạy job nhiều lần/ngày không bị nhân đôi dữ liệu.
//  
async function insertRecord(record, source) {
    const outageDate = toPostgresDate(record.date);
    const startTime = toPostgresTime(record.time_start);
    const endTime = toPostgresTime(record.time_end);

// Tính hash ở đây, TRƯỚC khi insert 
    const contentHash = computeContentHash({
        powerCompany: record.power_company,
        areaText: record.area,
        outageDate,
        startTime,
        reason: record.reason,
    });


    await pool.query(
        `
                INSERT INTO electric_outages_raw(
                    source, power_company, area_text, reason, status,
                    outage_date, start_time, end_time, content_hash, processed
                )
                VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9, FALSE)
                ON CONFLICT (content_hash) DO NOTHING
                `,
        [
            source,
            record.power_company || null,
            record.area || null,
            record.reason || null,
            record.status || null,
            outageDate,
            startTime,
            endTime,
            contentHash,
        ]
    );
}

async function run() {
    console.log("[scrapeAllSources] Bắt đầu fetch cả 3 nguồn...");
    const chunks = await fetchAllSources(); //Fetch dữ liệu từ web
    console.log(`[scrapeAllSources] Fetch xong, có ${chunks.length} chunk cần trích xuất`);

    let totalRecords = 0;
    let failedChunks = 0;

    // Xử lý tuần tự để không spam Gemini API cùng lúc (giống job xử lý staging)
    for (const chunk of chunks) {
        try {
            //Duyệt từng chunk và gọi gemini
            const records = await extractRecords(chunk.rawText);

            for (const record of records) {
                //Duyệt từng record và thêm vào csdl
                await insertRecord(record, chunk.source);
                totalRecords++;
            }

            console.log(
                `[scrapeAllSources] ${chunk.source}${chunk.districtHint ? " - " + chunk.districtHint : ""}: ${records.length} record`
            );
        } catch (err) {
            failedChunks++;
            console.error(
                `[scrapeAllSources] Lỗi xử lý chunk (source=${chunk.source}, huyện=${chunk.districtHint}):`,
                err.message
            );
        }
    }

    console.log(
        `[scrapeAllSources] Hoàn tất: ${totalRecords} record đã lưu, ${failedChunks} chunk lỗi / ${chunks.length} chunk`
    );
}

//Nếu có lỡ import từ file khác thì nó sẽ không tự chạy hàm, chỉ khi đích thân hàm được gọi thì mới chạy
//Khá giống __main__ của python
if (require.main === module) {
    run()
        .then(() => pool.end())
        .catch((err) => {
            console.error("[scrapeAllSources] Lỗi không xử lý được:", err);
            pool.end();
            process.exit(1);
        });
}

module.exports = { run };