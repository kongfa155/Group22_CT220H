const crypto = require("crypto");

//Mã hóa thông tin thành một mã độc nhất, sau này trùng thì sẽ không cập nhật lại
//  QUAN TRỌNG: outageDate và startTime phải là string đã format sẵn
//  (vd "2026-06-22", "08:00:00") - KHÔNG truyền object Date của JS vào đây,
//  vì Date.toString() phụ thuộc timezone máy chạy, sẽ làm hash không ổn định giữa các lần chạy/các máy khác nhau.
//  
function computeContentHash({ powerCompany, areaText, outageDate, startTime, reason }) {
    const raw = [
        powerCompany || "",
        areaText || "",
        outageDate || "",
        startTime || "",
        reason || "",
    ].join("|");
    //Ghép chuỗi dữ liệu sau đó đem đi hash theo chuẩn md5
    return crypto.createHash("md5").update(raw, "utf8").digest("hex");
}

module.exports = { computeContentHash };