// Bỏ dấu tiếng Việt + lowercase, dùng để match ward_name (có dấu, "Cái Khế")
// với admin_boundaries.normalized_name (không dấu, "cai khe") mà không cần
// phụ thuộc extension `unaccent` của Postgres (memory: có thể thiếu quyền
// trên DB hosting).
function normalizeVnText(text) {
    if (!text) return "";
    return text
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "") // bỏ dấu thanh
        .replace(/đ/g, "d")
        .replace(/Đ/g, "D")
        .toLowerCase()
        .trim();
}

function normalizeRoadKey(text) {
    return normalizeVnText(text).replace(/^duong\s+/, "").trim();
}

module.exports = { normalizeVnText, normalizeRoadKey};