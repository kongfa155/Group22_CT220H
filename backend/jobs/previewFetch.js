require("dotenv").config();
const fs = require("fs");
const path = require("path");

const { fetchAllSources } = require("../services/sourceFetcher");

//Hàm này cho phép chạy thử mà không gọi AI, để check xem dữ liệu có ổn không
async function run() {
    console.log("[previewFetch] Bắt đầu fetch cả 3 nguồn (không gọi AI)...\n");

    const chunks = await fetchAllSources();

    console.log(`Tổng cộng ${chunks.length} chunk:\n`);

    chunks.forEach((chunk, i) => {
        console.log(`--- Chunk ${i + 1}/${chunks.length} ---`);
        console.log(`source: ${chunk.source}`);
        console.log(`districtHint: ${chunk.districtHint}`);
        console.log(`coverage: ${chunk.coverage}`);
        console.log(`rawText (${chunk.rawText.length} ký tự):`);
        console.log(chunk.rawText.slice(0, 500) + (chunk.rawText.length > 500 ? "..." : ""));
        console.log("");
    });

    // Lưu full nội dung (không cắt bớt) ra file để xem chi tiết từng chunk
    const outputPath = path.join(__dirname, "..", "preview-fetch-output.json");
    fs.writeFileSync(outputPath, JSON.stringify(chunks, null, 2), "utf8");
    console.log(`Đã lưu toàn bộ dữ liệu (không cắt bớt) vào: ${outputPath}`);
}

run().catch((err) => {
    console.error("[previewFetch] Lỗi:", err);
    process.exit(1);
});