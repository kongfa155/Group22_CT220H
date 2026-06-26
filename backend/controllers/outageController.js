const pool = require("../config/db");

function parseDate(text) {
    const match = text.match(
        /(\d+)\s*tháng\s*(\d+)\s*năm\s*(\d+)/
    );

    if (!match) return null;

    const day = match[1].padStart(2, "0");
    const month = match[2].padStart(2, "0");
    const year = match[3];

    return `${year}-${month}-${day}`;
}

function parseTime(text) {
    const match = text.match(
        /(\d{1,2}:\d{2}).*(\d{1,2}:\d{2})/
    );

    if (!match) {
        return {
            start: null,
            end: null
        };
    }

    return {
        start: `${match[1]}:00`,
        end: `${match[2]}:00`
    };
}

exports.createRawOutage = async (req, res) => {
    try {
        const {
            powerCompany,
            date,
            time,
            area,
            reason,
            status
        } = req.body;

        const outageDate =
            parseDate(date);

        const {
            start,
            end
        } = parseTime(time);

        await pool.query(
            `
            INSERT INTO electric_outages_raw(
                power_company,
                area_text,
                reason,
                status,
                outage_date,
                start_time,
                end_time
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7)
            `,
            [
                powerCompany,
                area,
                reason,
                status,
                outageDate,
                start,
                end
            ]
        );

        res.json({
            message: "Saved successfully"
        });

    } catch (err) {
        console.error(err);

        res.status(500).json({
            message: err.message
        });
    }
};