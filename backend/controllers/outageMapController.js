const pool = require("../config/db");
const { normalizeVnText } = require("../utils/normalizeVnText");
const { extractDistrictHint } = require("../utils/extractDistrictHint");

const WARD_LEVEL_TYPES = new Set(["Phường", "Xã", "Thị trấn"]);
const DISTRICT_LEVEL_TYPE = "Quận/Huyện";

exports.getOutagesByWard = async (req, res) => {
    try {
        const date = req.query.date || new Date().toISOString().slice(0, 10);

        const { rows: outageRows } = await pool.query(
            `
            SELECT
                s.ward_name,
                s.subarea_name,
                s.road_name,
                r.power_company,
                r.area_text,
                r.reason,
                r.status,
                r.outage_date,
                r.start_time,
                r.end_time
            FROM electric_outages_staging s
            JOIN electric_outages_raw r ON r.id = s.raw_id
            WHERE r.outage_date = $1
            ORDER BY s.ward_name
            `,
            [date]
        );

        const { rows: boundaryRows } = await pool.query(
            `
            SELECT
                id,
                name,
                normalized_name,
                type,
                ST_AsGeoJSON(ST_Centroid(geom)) AS centroid_geojson
            FROM admin_boundaries
            `
        );

        // Tách riêng 2 map tra cứu theo cấp - tránh match nhầm khi tên
        // phường trùng tên quận/huyện (hiếm nhưng có thể xảy ra ở VN).
        const wardByNormName = new Map();
        const districtByNormName = new Map();

        for (const b of boundaryRows) {
            const centroid = JSON.parse(b.centroid_geojson);
            const entry = {
                id: b.id,
                name: b.name,
                type: b.type,
                lat: centroid.coordinates[1],
                lng: centroid.coordinates[0],
            };

            if (WARD_LEVEL_TYPES.has(b.type)) {
                wardByNormName.set(b.normalized_name, entry);
            } else if (b.type === DISTRICT_LEVEL_TYPE) {
                districtByNormName.set(b.normalized_name, entry);
            }
        }

        const groups = new Map();
        const unmatched = [];

        for (const row of outageRows) {
            let boundary = null;
            let matchedVia = null;

            // 1) Ưu tiên match theo ward_name ở cấp phường/xã (chính xác nhất)
            if (row.ward_name) {
                const normWard = normalizeVnText(row.ward_name);
                boundary = wardByNormName.get(normWard);
                if (boundary) matchedVia = "ward";
            }

            // 2) Fallback: suy ra quận/huyện từ power_company, match ở cấp quận/huyện
            if (!boundary) {
                const districtHint = extractDistrictHint(row.power_company);
                if (districtHint) {
                    const normDistrict = normalizeVnText(districtHint);
                    boundary = districtByNormName.get(normDistrict);
                    if (boundary) matchedVia = "company_fallback";
                }
            }

            if (!boundary) {
                unmatched.push({
                    powerCompany: row.power_company,
                    wardName: row.ward_name,
                    areaText: row.area_text,
                });
                continue;
            }

            if (!groups.has(boundary.id)) {
                groups.set(boundary.id, {
                    boundaryId: boundary.id,
                    wardName: boundary.name,
                    lat: boundary.lat,
                    lng: boundary.lng,
                    isApproximateLocation: matchedVia === "company_fallback",
                    outages: [],
                });
            }

            groups.get(boundary.id).outages.push({
                subareaName: row.subarea_name,
                roadName: row.road_name,
                powerCompany: row.power_company,
                areaText: row.area_text,
                reason: row.reason,
                status: row.status,
                startTime: row.start_time,
                endTime: row.end_time,
            });
        }

        if (unmatched.length > 0) {
            console.warn(
                `[outageMapController] ${unmatched.length} record không match được:`,
                unmatched.map((u) => `${u.powerCompany} | ${u.wardName}`)
            );
        }

        res.json({
            date,
            wards: [...groups.values()],
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};