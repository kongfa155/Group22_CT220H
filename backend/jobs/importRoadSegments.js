require("dotenv").config();
const fs = require("fs");
const pool = require("../config/db");

async function run() {
    const filePath = process.argv[2];
    if (!filePath) {
        console.error("Cách dùng: node jobs/importRoadSegments.js <đường-dẫn-file.json>");
        process.exit(1);
    }

    const raw = fs.readFileSync(filePath, "utf8");
    let entries = JSON.parse(raw);
    if (!Array.isArray(entries)) entries = [entries];

    let added = 0;
    let skipped = 0;

    for (const entry of entries) {
        try {
            await pool.query(
                `
                INSERT INTO road_segments(name, normalized_name, aliases, parent_name, geom)
                VALUES ($1, $2, $3, $4, ST_SetSRID(ST_GeomFromGeoJSON($5), 4326))
                ON CONFLICT (normalized_name) DO NOTHING
                `,
                [entry.name, entry.normalized_name, entry.aliases || [], entry.parent_name, JSON.stringify(entry.geom)]
            );
            console.log(`[importRoadSegments] Đã thêm: "${entry.name}"`);
            added++;
        } catch (err) {
            console.error(`[importRoadSegments] Lỗi thêm "${entry.name}":`, err.message);
            skipped++;
        }
    }

    console.log(`\n[importRoadSegments] Hoàn tất: ${added} thêm, ${skipped} bỏ qua`);
}

run()
    .then(() => pool.end())
    .catch((err) => {
        console.error(err);
        pool.end();
        process.exit(1);
    });