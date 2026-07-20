const pool = require("../config/db");

// Trả toàn bộ admin_boundaries dạng GeoJSON FeatureCollection để FE vẽ polygon.
exports.getAllBoundaries = async (req, res) => {
    try {
        const { rows } = await pool.query(
            `
            SELECT
                id,
                name,
                type,
                ST_AsGeoJSON(geom) AS geojson
            FROM admin_boundaries
            `
        );

        const features = rows.map((row) => ({
            type: "Feature",
            properties: {
                id: row.id,
                name: row.name,
                boundaryType: row.type, // "Phường", "Quận"...
            },
            geometry: JSON.parse(row.geojson),
        }));

        res.json({
            type: "FeatureCollection",
            features,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};