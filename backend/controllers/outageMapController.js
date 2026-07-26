const pool = require("../config/db");
const { normalizeVnText, normalizeRoadKey } = require("../utils/normalizeVnText");
const { extractDistrictHint } = require("../utils/extractDistrictHint");

const WARD_LEVEL_TYPES = new Set(["Phường", "Xã", "Thị trấn"]);
const DISTRICT_LEVEL_TYPE = "Quận/Huyện";
const ROAD_BUFFER_METERS = 10;

exports.getOutagesByWard = async (req, res) => {
    try {
        const date = req.query.date || new Date().toISOString().slice(0, 10);

        const { rows: outageRows } = await pool.query(
            `
            SELECT
                s.ward_name, s.subarea_name, s.road_name, s.extraction_result,
                r.power_company, r.area_text, r.reason, r.status,
                r.outage_date, r.start_time, r.end_time
            FROM electric_outages_staging s
            JOIN electric_outages_raw r ON r.id = s.raw_id
            WHERE r.outage_date = $1
            `,
            [date]
        );

        const [{ rows: roadRows }, { rows: placeRows }, { rows: boundaryRows }] = await Promise.all([
            // Buffer sẵn 10m mỗi bên NGAY TRONG QUERY - tính 1 lần cho mỗi
            // đường (không phải mỗi outage), đỡ tốn CPU lặp lại.
            pool.query(
                `SELECT normalized_name,
                        ST_AsGeoJSON(ST_Buffer(geom::geography, $1)::geometry) AS buffered_geojson
                 FROM road_segments`,
                [ROAD_BUFFER_METERS]
            ),
            pool.query(`SELECT normalized_name, ST_AsGeoJSON(geom) AS geojson FROM place_geometries`),
            pool.query(
                `SELECT id, name, normalized_name, type,
                        ST_AsGeoJSON(ST_Centroid(geom)) AS centroid_geojson
                 FROM admin_boundaries`
            ),
        ]);

        const roadByNormName = new Map(
            roadRows.map((r) => [normalizeRoadKey(r.normalized_name), JSON.parse(r.buffered_geojson)])
        );
        const placeByNormName = new Map(placeRows.map((p) => [p.normalized_name, JSON.parse(p.geojson)]));

        const wardByNormName = new Map();
        const districtByNormName = new Map();
        for (const b of boundaryRows) {
            const centroid = JSON.parse(b.centroid_geojson);
            const entry = { id: b.id, name: b.name, lat: centroid.coordinates[1], lng: centroid.coordinates[0] };
            if (WARD_LEVEL_TYPES.has(b.type)) wardByNormName.set(b.normalized_name, entry);
            else if (b.type === DISTRICT_LEVEL_TYPE) districtByNormName.set(b.normalized_name, entry);
        }

        const roadAreas = [];
        const placeAreas = [];
        const fallbackPoints = new Map(); // dùng khi zoom sâu nhưng không có road/place cụ thể
        const wardSummaries = new Map(); // dùng khi zoom xa - marker gộp cả phường

        for (const row of outageRows) {
            const outagePayload = {
                subareaName: row.subarea_name,
                roadName: row.road_name,
                powerCompany: row.power_company,
                areaText: row.area_text,
                reason: row.reason,
                status: row.status,
                startTime: row.start_time,
                endTime: row.end_time,
            };

            // --- Xác định phường/quận để GỘP VÀO wardSummaries -----------
            // Luôn làm bước này cho MỌI outage, kể cả outage đã match được
            // road/place cụ thể - vì marker tổng hợp cấp phường (lúc zoom xa)
            // cần liệt kê TẤT CẢ outage trong phường đó, không chỉ phần
            // "chưa xác định vị trí".
            let boundary = row.ward_name ? wardByNormName.get(normalizeVnText(row.ward_name)) : null;
            if (!boundary) {
                const districtHint = extractDistrictHint(row.power_company);
                if (districtHint) boundary = districtByNormName.get(normalizeVnText(districtHint));
            }

            if (boundary) {
                const key = `ward:${boundary.id}`;
                if (!wardSummaries.has(key)) {
                    wardSummaries.set(key, {
                        boundaryId: boundary.id,
                        label: boundary.name,
                        lat: boundary.lat,
                        lng: boundary.lng,
                        outages: [],
                    });
                }
                wardSummaries.get(key).outages.push(outagePayload);
            } else {
                console.warn(`[outageMapController] Không xác định được ward cho: "${row.area_text}"`);
            }

            // --- Xác định hiển thị CHI TIẾT (dùng khi zoom sâu) ----------
                        // Đọc TOÀN BỘ mảng streets[] trong extraction_result (JSONB đã
                        // có sẵn), thay vì chỉ đọc road_name (chỉ lưu 1 đường đầu tiên).
                        // Với outage nhiều đường (VD khu trung tâm cắt điện đồng loạt),
                        // vòng lặp này giúp tô màu TẤT CẢ đường đã có trong road_segments,
                        // không chỉ 1 đường đại diện.
                        const extraction = row.extraction_result || {};
                        const streetList = Array.isArray(extraction.streets) && extraction.streets.length > 0
                            ? extraction.streets
                            : (row.road_name ? [row.road_name] : []);

                        let matchedAnyRoad = false;

                        for (const streetName of streetList) {
                            const geometry = roadByNormName.get(normalizeRoadKey(streetName));
                            if (geometry) {
                                const isPartial = !!(extraction.from_landmark || extraction.to_landmark);
                                roadAreas.push({
                                    geometry,
                                    color: isPartial ? "orange" : "yellow",
                                    label: streetName,
                                    outage: outagePayload,
                                });
                                matchedAnyRoad = true;
                            }
                        }

                        if (matchedAnyRoad) continue;

            if (row.subarea_name) {
                const geometry = placeByNormName.get(normalizeVnText(row.subarea_name));
                if (geometry) {
                    placeAreas.push({
                        geometry,
                        color: "yellow",
                        label: row.subarea_name,
                        outage: outagePayload,
                    });
                    continue;
                }
            }

            // --- Không match road/place cụ thể -> fallback điểm centroid -
            if (boundary) {
                const key = `point:${boundary.id}`;
                if (!fallbackPoints.has(key)) {
                    fallbackPoints.set(key, {
                        label: boundary.name,
                        lat: boundary.lat,
                        lng: boundary.lng,
                        outages: [],
                    });
                }
                fallbackPoints.get(key).outages.push(outagePayload);
            }
        }

        res.json({
            date,
            wardSummaries: [...wardSummaries.values()], // dùng khi ZOOM XA
            roadAreas, // dùng khi ZOOM SÂU
            placeAreas, // dùng khi ZOOM SÂU
            points: [...fallbackPoints.values()], // dùng khi ZOOM SÂU (fallback)
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};