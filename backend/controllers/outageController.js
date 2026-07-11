const pool = require("../config/db");
const { computeContentHash } = require("../utils/contentHash"); // <-- MỚI

function parseDate(text) {
    if (!text) return null; // guard đã thêm ở review trước

    const match = text.match(/(\d+)\s*tháng\s*(\d+)\s*năm\s*(\d+)/);
    if (!match) return null;

    const day = match[1].padStart(2, "0");
    const month = match[2].padStart(2, "0");
    const year = match[3];

    return `${year}-${month}-${day}`;
}

function parseTime(text) {
    if (!text) return { start: null, end: null }; // guard đã thêm ở review trước

    const match = text.match(/(\d{1,2}:\d{2}).*(\d{1,2}:\d{2})/);
    if (!match) return { start: null, end: null };

    return {
        start: `${match[1]}:00`,
        end: `${match[2]}:00`,
    };
}

exports.createRawOutage = async (req, res) => {
    try {
        const { powerCompany, date, time, area, reason, status } = req.body;

        const outageDate = parseDate(date);
        const { start, end } = parseTime(time);

        // Tính hash ở đây, TRƯỚC khi insert - thay cho GENERATED COLUMN cũ
        const contentHash = computeContentHash({
            powerCompany,
            areaText: area,
            outageDate,
            startTime: start,
            reason,
        });

        const result = await pool.query(
            `
            INSERT INTO electric_outages_raw(
                power_company, area_text, reason, status,
                outage_date, start_time, end_time, content_hash
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            ON CONFLICT (content_hash) DO NOTHING
            RETURNING id
            `,
            [powerCompany, area, reason, status, outageDate, start, end, contentHash]
        );

        res.json({
            message: result.rows.length ? "Saved successfully" : "Duplicate skipped",
            id: result.rows[0]?.id ?? null,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};