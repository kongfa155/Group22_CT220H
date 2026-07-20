require("dotenv").config();

const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

//Các dữ liệu được chuyển sẽ có các dạng như là
// 11/07/2026

// 06:30 - 17:30

// Điện lực Quận Cái Răng

// Đường Trần Chiên...

// Lý do: Bảo trì...

//Gửi thông tin cho AI để nó chuẩn hóa thành dạng JSON theo mẫu
// [
//   {
//     power_company: "Điện lực Quận Cái Răng",
//     date: "11/07/2026",
//     time_start: "06:30",
//     time_end: "17:30",
//     area: "Đường Trần Chiên...",
//     reason: "Bảo trì...",
//     status: "Đã duyệt",
//     district_hint: "Cái Răng",
//   },
// ];
const SYSTEM_PROMPT = `
Bạn nhận được đoạn text cào từ một trang web lịch cúp điện tại Cần Thơ, Việt Nam.
Đoạn text có thể chứa NHIỀU record cúp điện liên tiếp, và có thể có nội dung nhiễu
xen giữa (menu, quảng cáo, link không liên quan, tên các trang/chủ đề ngẫu nhiên
như "Vật lý", "Bóng đá", "Khám phá thêm"...). Nhiệm vụ của bạn là bỏ qua hoàn toàn
nội dung nhiễu đó và chỉ trích xuất các record cúp điện thật sự.

Mỗi record luôn có các trường (dù thứ tự hoặc cách trình bày có thể khác nhau
giữa các nguồn): đơn vị điện lực, ngày, khung giờ, khu vực bị cúp, lý do,
trạng thái (nếu có).

Trả về JSON là MỘT MẢNG (array), mỗi phần tử có schema:
{
  "power_company": string,
  "date": string,        // giữ nguyên định dạng dd/mm/yyyy như trong text gốc
  "time_start": string,  // định dạng "HH:MM" (24h), tự suy luận từ text dù viết kiểu nào
  "time_end": string,    // định dạng "HH:MM"
  "area": string,        // giữ nguyên mô tả khu vực, không tự rút gọn hay diễn giải lại
  "reason": string | null,
  "status": string | null,     // "Đã duyệt", "Đang thực hiện"... nếu có, null nếu không thấy
  "district_hint": string | null  // chỉ điền nếu text có ghi rõ tên quận/huyện (vd sau nhãn "Huyện:")
}

Nếu không có record nào hợp lệ trong đoạn text, trả về mảng rỗng [].
CHỈ trả JSON thuần, không kèm markdown, không giải thích thêm.

Ví dụ 1 (nhiều record, có noise xen giữa - PHẢI bỏ qua noise):
Input: "Điện lực: Điện lực Huyện Phong Điền (PĐ)\\nNgày: 04/07/2026\\nThời gian: Từ 07:30 đến 17:00\\nMáy tính và đồ điện tử\\nKhu vực: Khu vực Mỹ Phước; một phần khu vực Mỹ Ái – Phường An Bình\\nLý do: Bảo trì, sửa chữa lưới điện\\nKhám phá thêm\\nDịch vụ khách hàng\\nVật lý\\nBóng đá\\nĐiện lực: Điện lực Huyện Phong Điền (PĐ)\\nNgày: 04/07/2026\\nThời gian: Từ 07:30 đến 08:00\\nKhu vực: Các ấp Nhơn Thọ 1, Nhơn Thọ 1A - xã Nhơn Ái\\nLý do: Bảo trì, sửa chữa lưới điện"
Output: [
  {"power_company":"Điện lực Huyện Phong Điền (PĐ)","date":"04/07/2026","time_start":"07:30","time_end":"17:00","area":"Khu vực Mỹ Phước; một phần khu vực Mỹ Ái – Phường An Bình","reason":"Bảo trì, sửa chữa lưới điện","status":null,"district_hint":"Phong Điền"},
  {"power_company":"Điện lực Huyện Phong Điền (PĐ)","date":"04/07/2026","time_start":"07:30","time_end":"08:00","area":"Các ấp Nhơn Thọ 1, Nhơn Thọ 1A - xã Nhơn Ái","reason":"Bảo trì, sửa chữa lưới điện","status":null,"district_hint":"Phong Điền"}
]

Ví dụ 2 (nguồn có label rõ ràng, có trạng thái):
Input: "11/07/2026\\n06:30 - 17:30 Đã duyệt\\nHuyện: Quận Cái Răng\\nĐơn vị: Điện lực Quận Cái Răng\\nKhu vực: Đường Trần Chiên - P. Cái Răng-Cần Thơ\\nLý do: Bảo trì, sửa chữa lưới điện"
Output: [
  {"power_company":"Điện lực Quận Cái Răng","date":"11/07/2026","time_start":"06:30","time_end":"17:30","area":"Đường Trần Chiên - P. Cái Răng-Cần Thơ","reason":"Bảo trì, sửa chữa lưới điện","status":"Đã duyệt","district_hint":"Cái Răng"}
]
`.trim();

async function extractRecords(rawText, { maxRetries = 3 } = {}) {
    const body = {
        contents: [
            {
                role: "user",
                parts: [{ text: `${SYSTEM_PROMPT}\n\nInput: ${JSON.stringify(rawText)}\nOutput:` }],
            },
        ],
        generationConfig: {
            temperature: 0, //Thuộc tính bắt AI phụ thuộc vào nội dung của người cung cấp, không sáng tạo thêm
            responseMimeType: "application/json",
        },
    };

    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const response = await fetch(GEMINI_URL, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "x-goog-api-key": process.env.GEMINI_API_KEY,
                },
                body: JSON.stringify(body),
            });

            if (!response.ok) {
                const errText = await response.text();

                // 503 = server Gemini quá tải tạm thời, đáng để thử lại.
                // Các lỗi khác (401/403/400...) là lỗi cấu hình/quyền - thử lại vô ích, throw ngay để không tốn thời gian retry vô nghĩa.
                if (response.status === 503 && attempt < maxRetries) {
                    const delayMs = attempt * 2000; // 2s, 4s, 6s...
                    console.warn(
                        `[recordExtractor] Gemini 503 (lần ${attempt}/${maxRetries}), thử lại sau ${delayMs}ms...`
                    );
                    await new Promise((resolve) => setTimeout(resolve, delayMs));
                    continue;
                }

                throw new Error(`Gemini API lỗi ${response.status}: ${errText}`);
            }

            const data = await response.json();
            const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;

            if (!text) {
                throw new Error("Gemini không trả về nội dung hợp lệ");
            }

            let parsed;
            try {
                parsed = JSON.parse(text);
            } catch (e) {
                throw new Error(`Không parse được JSON từ Gemini: ${text}`);
            }

            if (!Array.isArray(parsed)) {
                throw new Error(`Gemini trả về không phải mảng: ${text}`);
            }

            return parsed;
        } catch (err) {
            lastError = err;
            // Lỗi network (không phải từ response.ok check ở trên) cũng đáng retry
            if (attempt < maxRetries && err.message.includes("503")) {
                continue;
            }
            if (attempt === maxRetries) break;
        }
    }

    throw lastError;
}

module.exports = { extractRecords };