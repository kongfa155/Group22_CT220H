// Trích tên quận/huyện từ power_company để dùng làm fallback khi
// ward_name không xác định được (VD Gemini gặp mô tả nhiều xã/mơ hồ).
// "Điện lực Quận Cái Răng" -> "Cái Răng"
// "Điện lực Huyện Phong Điền (PĐ)" -> "Phong Điền"
function extractDistrictHint(powerCompany) {
    if (!powerCompany) return null;

    let text = powerCompany.replace(/^Điện lực\s*/i, "").trim();
    text = text.replace(/\(.*?\)\s*$/, "").trim(); // bỏ hậu tố viết tắt "(PĐ)"
    text = text.replace(/^(Quận|Huyện|Thành phố|TP\.?|Thị xã)\s+/i, "").trim();

    return text || null;
}

module.exports = { extractDistrictHint };