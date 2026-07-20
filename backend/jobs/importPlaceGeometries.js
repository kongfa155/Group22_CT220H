require("dotenv").config();
const fs = require("fs");
const pool = require("../config/db");
const { normalizeVnText } = require("../utils/normalizeVnText");

// Trích ward/phường/xã ra khỏi chuỗi parent_adm dạng
// "Phường An Khánh, Quận Ninh Kiều, Thành phố Cần Thơ" -> "An Khánh"
function extractWardFromParentAdm(parentAdm) {
    if (!parentAdm) return null;
    const firstPart = parentAdm.split(",")[0].trim();
    return firstPart.replace(/^(Phường|Xã|Thị trấn)\s+/i, "").trim();
}

async function run() {
    const filePath = process.argv[2];
    if (!filePath) {
        console.error("Cách dùng: node jobs/importPlaceGeometries.js <đường-dẫn-file.json>");
        process.exit(1);
    }

    const raw = fs.readFileSync(filePath, "utf8");
    let entries = JSON.parse(raw);
    if (!Array.isArray(entries)) entries = [entries]; // cho phép file chỉ có 1 object

    const { rows: boundaries } = await pool.query(`SELECT id, normalized_name FROM admin_boundaries`);
    const boundaryIdByNormName = new Map(boundaries.map((b) => [b.normalized_name, b.id]));

    let added = 0;
    let skipped = 0;

    for (const entry of entries) {
        const wardName = extractWardFromParentAdm(entry.parent_adm);
        const parentId = wardName ? boundaryIdByNormName.get(normalizeVnText(wardName)) : null;

        if (!parentId) {
            console.warn(
                `[importPlaceGeometries] Bỏ qua "${entry.name}": không tìm được parent_id cho "${wardName}"`
            );
            skipped++;
            continue;
        }

        try {
            await pool.query(
                `
                INSERT INTO place_geometries(name, normalized_name, aliases, type, parent_id, geom)
                VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_Multi(ST_GeomFromGeoJSON($6)), 4326))
                ON CONFLICT (normalized_name) DO NOTHING
                `,
                [
                    entry.name,
                    entry.normalized_name,
                    entry.aliases || [],
                    entry.type,
                    parentId,
                    JSON.stringify(entry.geom),
                ]
            );
            console.log(`[importPlaceGeometries] Đã thêm: "${entry.name}" (parent_id=${parentId})`);
            added++;
        } catch (err) {
            console.error(`[importPlaceGeometries] Lỗi thêm "${entry.name}":`, err.message);
            skipped++;
        }
    }

    console.log(`\n[importPlaceGeometries] Hoàn tất: ${added} thêm, ${skipped} bỏ qua`);
}

run()
    .then(() => pool.end())
    .catch((err) => {
        console.error(err);
        pool.end();
        process.exit(1);
    });