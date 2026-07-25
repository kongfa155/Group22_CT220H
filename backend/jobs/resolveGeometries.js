require("dotenv").config();
const pool = require("../config/db");
const { normalizeVnText } = require("../utils/normalizeVnText");
const { geocodeGeometry } = require("../services/geocodeService");

async function run() {
    // --- ROADS ---
    const { rows: distinctRoads } = await pool.query(
        `SELECT DISTINCT road_name, ward_name FROM electric_outages_staging WHERE road_name IS NOT NULL`
    );
    const { rows: existingRoads } = await pool.query(`SELECT normalized_name FROM road_segments`);
    const existingRoadKeys = new Set(existingRoads.map((r) => r.normalized_name));

    let roadsAdded = 0, roadsFailed = 0;

    for (const { road_name, ward_name } of distinctRoads) {
        const normKey = normalizeVnText(road_name);
        if (existingRoadKeys.has(normKey)) continue;

        const query = `${road_name}, ${ward_name || ""}, Cần Thơ, Việt Nam`;
        try {
            const results = await geocodeGeometry(query);

            // Chỉ chấp nhận kết quả đúng là "đường" (class=highway) VÀ đúng
            // kiểu hình học LineString - tránh nhầm sang polygon của
            // công viên/lô đất trùng tên.
            const best = results?.find(
                (r) => r.osmClass === "highway" && r.geometry.type === "LineString"
            );

            if (best) {
                await pool.query(
                    `INSERT INTO road_segments(name, normalized_name, parent_name, geom)
                     VALUES ($1, $2, $3, ST_SetSRID(ST_GeomFromGeoJSON($4), 4326))`,
                    [road_name, normKey, ward_name, JSON.stringify(best.geometry)]
                );
                console.log(`[resolveGeometries] Đã thêm đường: "${road_name}"`);
                roadsAdded++;
                existingRoadKeys.add(normKey);
            } else {
                console.warn(`[resolveGeometries] KHÔNG match đúng loại "đường" (cần nhập tay): "${query}"`);
                roadsFailed++;
            }
        } catch (err) {
            console.error(`[resolveGeometries] Lỗi geocode đường "${query}":`, err.message);
            roadsFailed++;
        }
    }

    // --- PLACES ---
    const { rows: distinctPlaces } = await pool.query(
        `SELECT DISTINCT subarea_name, ward_name FROM electric_outages_staging WHERE subarea_name IS NOT NULL AND road_name IS NULL`
    );
    const { rows: existingPlaces } = await pool.query(`SELECT normalized_name FROM place_geometries`);
    const existingPlaceKeys = new Set(existingPlaces.map((p) => p.normalized_name));
    const { rows: boundaries } = await pool.query(`SELECT id, normalized_name FROM admin_boundaries`);
    const boundaryIdByNormName = new Map(boundaries.map((b) => [b.normalized_name, b.id]));

    let placesAdded = 0, placesFailed = 0;

    for (const { subarea_name, ward_name } of distinctPlaces) {
        const normKey = normalizeVnText(subarea_name);
        if (existingPlaceKeys.has(normKey)) continue;

        const query = `${subarea_name}, ${ward_name || ""}, Cần Thơ, Việt Nam`;
        try {
            const results = await geocodeGeometry(query);
            if (!results) {
                console.warn(`[resolveGeometries] KHÔNG tìm được địa điểm (cần nhập tay): "${query}"`);
                placesFailed++;
                continue;
            }

            const polygonMatch = results.find(
                (r) => r.geometry.type === "Polygon" || r.geometry.type === "MultiPolygon"
            );
            const pointMatch = results.find((r) => r.geometry.type === "Point");
            const parentId = boundaryIdByNormName.get(normalizeVnText(ward_name)) || null;

            if (polygonMatch) {
                await pool.query(
                    `INSERT INTO place_geometries(name, normalized_name, type, parent_id, geom)
                     VALUES ($1, $2, 'poi', $3, ST_SetSRID(ST_Multi(ST_GeomFromGeoJSON($4)), 4326))`,
                    [subarea_name, normKey, parentId, JSON.stringify(polygonMatch.geometry)]
                );
                console.log(`[resolveGeometries] Đã thêm địa điểm (polygon thật): "${subarea_name}"`);
                placesAdded++;
                existingPlaceKeys.add(normKey);
            } else if (pointMatch) {
                // Không có polygon thật - tự tạo 1 vùng đệm nhỏ (~30m) quanh
                // điểm để vẫn lưu được vào cột MultiPolygon, thay vì bỏ phí
                // kết quả geocode đã tìm đúng vị trí.
                const [lng, lat] = pointMatch.geometry.coordinates;
                await pool.query(
                    `INSERT INTO place_geometries(name, normalized_name, type, parent_id, geom)
                     VALUES ($1, $2, 'poi', $3,
                         ST_Multi(ST_Buffer(ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography, 30)::geometry)
                     )`,
                    [subarea_name, normKey, parentId, lng, lat]
                );
                console.log(`[resolveGeometries] Đã thêm địa điểm (buffer quanh điểm): "${subarea_name}"`);
                placesAdded++;
                existingPlaceKeys.add(normKey);
            } else {
                console.warn(`[resolveGeometries] Kết quả không phù hợp (cần nhập tay): "${query}"`);
                placesFailed++;
            }
        } catch (err) {
            console.error(`[resolveGeometries] Lỗi geocode địa điểm "${query}":`, err.message);
            placesFailed++;
        }
    }

    console.log(`\n[resolveGeometries] Hoàn tất: roads +${roadsAdded}/-${roadsFailed}, places +${placesAdded}/-${placesFailed}`);
}

if (require.main === module) {
    run().then(() => pool.end()).catch((err) => {
        console.error(err);
        pool.end();
        process.exit(1);
    });
}

module.exports = { run };