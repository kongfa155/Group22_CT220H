const pool = require("../config/db");

exports.createOutage = async (req, res) => {

    try {

        const {
            company,
            date,
            time,
            area,
            reason,
            status,
            latitude,
            longitude
        } = req.body;

        await pool.query(
            `
            INSERT INTO electric_outages(
                company,
                outage_date,
                outage_time,
                area,
                reason,
                status,
                latitude,
                longitude,
                geom
            )
            VALUES(
                $1,$2,$3,$4,$5,$6,$7,$8,
                ST_SetSRID(ST_MakePoint($8,$7),4326)
            )
            `,
            [
                company,
                date,
                time,
                area,
                reason,
                status,
                latitude,
                longitude
            ]
        );

        res.json({
            message: "Saved successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json(err);

    }

}