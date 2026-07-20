require("dotenv").config();
const pool = require("../config/db");
const { normalizeVnText } = require("../utils/normalizeVnText");
const { geocodeGeometry } = require("../services/geocodeService");

// Lấy tất cả cặp (road_name, ward_name) và (subarea_name, ward_name) duy nhất
// đang có trong staging mà chưa có geometry tương ứng trong road_segments /
// place_geometries - tránh gọi geocode lại cho những gì đã xử lý trước đó.
async function findMissingRoads() {
    const { rows } = await pool.query(
        `
        SELECT DISTINCT s.road_name, s.ward_name
        FROM electric_outages_staging s
        WHERE s.road_name IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM road_segments rs
              WHERE rs.normalized_name = LOWER(unaccent_fallback(s.road_name))
          )
        `
    );
    return rows;
}

// unaccent_fallback không tồn tại thật trong Postgres - dùng normalize ở JS
// thay vì SQL để tránh phụ thuộc extension unaccent (memory: có thể thiếu
// quyền trên DB hosting). Nên thực ra query trên cần viết lại bằng cách lấy
// hết rồi lọc ở Node - xem hàm run() bên dưới.

async function run() {
    // --- ROADS ---
    const { rows: distinctRoads } = await pool.query(
        `SELECT DISTINCT road_name, ward_name FROM electric_outages_staging WHERE road_name IS NOT NULL`
    );

    const { rows: existingRoads } = await pool.query(`SELECT normalized_name FROM road_segments`);
    const existingRoadKeys = new Set(existingRoads.map((r) => r.normalized_name));

    let roadsAdded = 0;
    let roadsFailed = 0;

    for (const { road_name, ward_name } of distinctRoads) {
        const normKey = normalizeVnText(road_name);
        if (existingRoadKeys.has(normKey)) continue; // đã có, bỏ qua

        const query = `${road_name}, ${ward_name || ""}, Cần Thơ, Việt Nam`;
        try {
            const result = await geocodeGeometry(query);

            if (result) {
                await pool.query(
                    `
                    INSERT INTO road_segments(name, normalized_name, parent_name, geom)
                    VALUES ($1, $2, $3, ST_SetSRID(ST_GeomFromGeoJSON($4), 4326))
                    `,
                    [road_name, normKey, ward_name, JSON.stringify(result.geometry)]
                );
                console.log(`[resolveGeometries] Đã thêm đường: "${road_name}" (${result.geometry.type})`);
                roadsAdded++;
                existingRoadKeys.add(normKey);
            } else {
                console.warn(`[resolveGeometries] KHÔNG tìm được đường (cần nhập tay): "${query}"`);
                roadsFailed++;
            }
        } catch (err) {
            console.error(`[resolveGeometries] Lỗi geocode đường "${query}":`, err.message);
            roadsFailed++;
        }
    }

    // --- PLACES (khu vực/công ty) ---
    const { rows: distinctPlaces } = await pool.query(
        `SELECT DISTINCT subarea_name, ward_name FROM electric_outages_staging WHERE subarea_name IS NOT NULL AND road_name IS NULL`
    );

    const { rows: existingPlaces } = await pool.query(`SELECT normalized_name FROM place_geometries`);
    const existingPlaceKeys = new Set(existingPlaces.map((p) => p.normalized_name));

    // Cần parent_id (id trong admin_boundaries) - build map tra cứu theo ward
    const { rows: boundaries } = await pool.query(`SELECT id, normalized_name FROM admin_boundaries`);
    const boundaryIdByNormName = new Map(boundaries.map((b) => [b.normalized_name, b.id]));

    let placesAdded = 0;
    let placesFailed = 0;

    for (const { subarea_name, ward_name } of distinctPlaces) {
        const normKey = normalizeVnText(subarea_name);
        if (existingPlaceKeys.has(normKey)) continue;

        const query = `${subarea_name}, ${ward_name || ""}, Cần Thơ, Việt Nam`;
        try {
            const result = await geocodeGeometry(query);

            if (result) {
                const parentId = boundaryIdByNormName.get(normalizeVnText(ward_name)) || null;
                await pool.query(
                    `
                    INSERT INTO place_geometries(name, normalized_name, type, parent_id, geom)
                    VALUES ($1, $2, 'poi', $3, ST_SetSRID(ST_GeomFromGeoJSON($4), 4326))
                    `,
                    [subarea_name, normKey, parentId, JSON.stringify(result.geometry)]
                );
                console.log(`[resolveGeometries] Đã thêm địa điểm: "${subarea_name}"`);
                placesAdded++;
                existingPlaceKeys.add(normKey);
            } else {
                console.warn(`[resolveGeometries] KHÔNG tìm được địa điểm (cần nhập tay): "${query}"`);
                placesFailed++;
            }
        } catch (err) {
            console.error(`[resolveGeometries] Lỗi geocode địa điểm "${query}":`, err.message);
            placesFailed++;
        }
    }

    console.log(
        `\n[resolveGeometries] Hoàn tất: roads +${roadsAdded}/-${roadsFailed} thất bại, places +${placesAdded}/-${placesFailed} thất bại`
    );
}

if (require.main === module) {
    run()
        .then(() => pool.end())
        .catch((err) => {
            console.error(err);
            pool.end();
            process.exit(1);
        });
}

module.exports = { run };