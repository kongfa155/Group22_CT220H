//Chuyển đổi dữ liệu ngày giờ của AI sang đúng chuẩn của postGres
function toPostgresDate(dateStr) {
    if (!dateStr) return null;
    const match = dateStr.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
    if (!match) return null;

    const [, d, m, y] = match;
    return `${y}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
}

function toPostgresTime(timeStr) {
    if (!timeStr) return null;
    const match = timeStr.match(/^(\d{1,2}):(\d{2})$/);
    if (!match) return null;

    const [, h, m] = match;
    return `${h.padStart(2, "0")}:${m}:00`;
}

module.exports = { toPostgresDate, toPostgresTime };