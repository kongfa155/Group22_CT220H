const pool = require("../config/db");
const { normalizeVnText, normalizeRoadKey } = require("../utils/normalizeVnText");
const { extractDistrictHint } = require("../utils/extractDistrictHint");

const WARD_LEVEL_TYPES = new Set(["Phường", "Xã", "Thị trấn"]);
const DISTRICT_LEVEL_TYPE = "Quận/Huyện";

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
            pool.query(`SELECT normalized_name, ST_AsGeoJSON(geom) AS geojson FROM road_segments`),
            pool.query(`SELECT normalized_name, ST_AsGeoJSON(geom) AS geojson FROM place_geometries`),
            pool.query(
                `SELECT id, name, normalized_name, type, ST_AsGeoJSON(ST_Centroid(geom)) AS centroid_geojson FROM admin_boundaries`
            ),
        ]);

const roadByNormName = new Map(
    roadRows.map((r) => [normalizeRoadKey(r.normalized_name), JSON.parse(r.geojson)])
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

        const points = []; // {lat,lng,label,outages:[]}
        const roads = []; // {geometry, color, label, outages:[]}
        const pointGroups = new Map(); // gộp outage trùng vị trí (ward centroid hoặc place) vào 1 marker

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

            // --- Ưu tiên 1: có road_name và đã có geometry đường ---
            if (row.road_name) {
                const geometry = roadByNormName.get(normalizeRoadKey(row.road_name));
                if (geometry) {
                    const extraction = row.extraction_result || {};
                    // Có mốc bắt đầu/kết thúc => chỉ 1 đoạn (một phần đường) => cam
                    // Không có mốc nào => toàn bộ đường => vàng
                    const isPartial = !!(extraction.from_landmark || extraction.to_landmark);

                    roads.push({
                        geometry,
                        color: isPartial ? "orange" : "yellow",
                        label: row.road_name,
                        outage: outagePayload,
                    });
                    continue;
                }
            }

            // --- Ưu tiên 2: có subarea_name và đã có geometry điểm ---
            if (row.subarea_name) {
                const geometry = placeByNormName.get(normalizeVnText(row.subarea_name));
                if (geometry && geometry.type === "Point") {
                    const key = `place:${normalizeVnText(row.subarea_name)}`;
                    if (!pointGroups.has(key)) {
                        pointGroups.set(key, {
                            lat: geometry.coordinates[1],
                            lng: geometry.coordinates[0],
                            label: row.subarea_name,
                            precision: "point",
                            outages: [],
                        });
                    }
                    pointGroups.get(key).outages.push(outagePayload);
                    continue;
                }
            }

            // --- Ưu tiên 3: fallback centroid ward ---
            let boundary = row.ward_name ? wardByNormName.get(normalizeVnText(row.ward_name)) : null;
            let precision = boundary ? "ward" : null;

            // --- Ưu tiên 4: fallback centroid quận/huyện qua power_company ---
            if (!boundary) {
                const districtHint = extractDistrictHint(row.power_company);
                if (districtHint) {
                    boundary = districtByNormName.get(normalizeVnText(districtHint));
                    if (boundary) precision = "district";
                }
            }

            if (!boundary) {
                console.warn(`[outageMapController] Không xác định được vị trí: "${row.area_text}"`);
                continue;
            }

            const key = `ward:${boundary.id}`;
            if (!pointGroups.has(key)) {
                pointGroups.set(key, {
                    lat: boundary.lat,
                    lng: boundary.lng,
                    label: boundary.name,
                    precision,
                    outages: [],
                });
            }
            pointGroups.get(key).outages.push(outagePayload);
        }

        res.json({
            date,
            points: [...pointGroups.values()],
            roads,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};