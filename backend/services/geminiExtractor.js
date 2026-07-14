require("dotenv").config();

const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// System prompt: định nghĩa rõ 3 nhãn scale, ép model trả JSON thuần.
const SYSTEM_PROMPT = `
Bạn là bộ máy trích xuất thông tin địa lý từ mô tả khu vực cúp điện tại Cần Thơ (tiếng Việt).
Văn bản đầu vào có thể sai chính tả nhẹ, viết tắt, hoặc thiếu thông tin. Nhiệm vụ của bạn:

1. Phân loại "scale" vào đúng 1 trong 3 nhãn:
   - "admin": chỉ nêu tên phường/quận/khu vực dân gian, KHÔNG có tên đường cụ thể.
   - "road": có tên đường/hẻm cụ thể (kể cả khi có chữ "một phần" đứng trước tên đường -
     "một phần" ở đây bổ nghĩa cho đoạn đường, không phải cho cả khu vực).
   - "vague": không đủ thông tin định vị rõ ràng (ví dụ chỉ nói "một phần khu vực",
     "thuộc nhánh sông" mà không có tên đường/mốc cụ thể nào).

2. Tự sửa lỗi chính tả nhẹ trong tên đường/phường nếu rõ ràng là lỗi gõ, nhưng
   KHÔNG được bịa thêm thông tin không có trong văn bản gốc.

3. Trả về "confidence":
   - "exact" nếu khu vực đủ cụ thể để tin cậy khung giờ đã cho.
   - "approximate" nếu khu vực mơ hồ (scale="vague" luôn đi kèm confidence="approximate").

CHỈ trả về JSON thuần, không kèm markdown, không giải thích thêm, đúng schema:
{
  "scale": "admin" | "road" | "vague",
  "ward": string | null,
  "subarea": string | null,
  "streets": string[],
  "from_landmark": string | null,
  "to_landmark": string | null,
  "confidence": "exact" | "approximate"
}

Ví dụ:
Input: "toàn bộ Khu vực Cồn Khương Phường Cái Khế TPCT"
Output: {"scale":"admin","ward":"Cái Khế","subarea":"Cồn Khương","streets":[],"from_landmark":null,"to_landmark":null,"confidence":"exact"}

Input: "Một phần đường Nguyễn Trãi từ đầu đường Trần Văn Khéo đi đến đường Trần Quang Khải, đến hẻm 10, 20, 24, 164 rẽ phải qua đường Trần Phú đến hẻm 42, 56 và đến đầu đường Ung Văn Khiêm. Phường Cái Khế TPCT"
Output: {"scale":"road","ward":"Cái Khế","subarea":null,"streets":["Nguyễn Trãi","Trần Phú"],"from_landmark":"đường Trần Văn Khéo","to_landmark":"đường Ung Văn Khiêm","confidence":"exact"}
`.trim();

// Free tier Gemini giới hạn 5 request/phút cho gemini-2.5-flash.
// Giãn cách tối thiểu giữa các lần gọi để không vượt limit ngay từ đầu -
// 60000ms / 5 = 12000ms, cộng thêm biên an toàn thành 13000ms.
const MIN_INTERVAL_MS = Number(process.env.GEMINI_MIN_INTERVAL_MS || 13000);
let lastCallAt = 0;

async function throttle() {
    const now = Date.now();
    const wait = lastCallAt + MIN_INTERVAL_MS - now;
    if (wait > 0) {
        await new Promise((resolve) => setTimeout(resolve, wait));
    }
    lastCallAt = Date.now();
}

/**
 * Đọc số giây "retryDelay" mà Google đề xuất trong response lỗi 429,
 * ví dụ: { "@type": "...RetryInfo", "retryDelay": "56s" }.
 * Trả về null nếu không tìm thấy (dùng backoff mặc định thay thế).
 */
function parseRetryDelaySeconds(errText) {
    try {
        const parsed = JSON.parse(errText);
        const detail = parsed?.error?.details?.find((d) => d.retryDelay);
        if (detail?.retryDelay) {
            return parseFloat(detail.retryDelay.replace("s", ""));
        }
    } catch (e) {
        // errText không phải JSON hợp lệ - bỏ qua, dùng backoff mặc định
    }
    return null;
}

async function extractAreaInfo(areaText, { maxRetries = 5 } = {}) {
    const body = {
        contents: [
            {
                role: "user",
                parts: [{ text: `${SYSTEM_PROMPT}\n\nInput: "${areaText}"\nOutput:` }]
            }
        ],
        generationConfig: {
            temperature: 0,
            responseMimeType: "application/json"
        }
    };

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        await throttle(); // luôn giãn cách trước mỗi lần gọi, kể cả lần đầu

        const response = await fetch(GEMINI_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-goog-api-key": process.env.GEMINI_API_KEY
            },
            body: JSON.stringify(body)
        });

        if (!response.ok) {
            const errText = await response.text();

            // 429 (rate limit) hoặc 503 (quá tải tạm thời) đáng để thử lại
            if ((response.status === 429 || response.status === 503) && attempt < maxRetries) {
                const suggestedDelay = parseRetryDelaySeconds(errText);
                const delayMs = suggestedDelay
                    ? Math.ceil(suggestedDelay * 1000) + 1000 // +1s đệm an toàn
                    : attempt * 5000; // fallback nếu không đọc được retryDelay

                console.warn(
                    `[geminiExtractor] Lỗi ${response.status} (lần ${attempt}/${maxRetries}), đợi ${delayMs}ms rồi thử lại...`
                );
                await new Promise((resolve) => setTimeout(resolve, delayMs));
                continue;
            }

            throw new Error(`Gemini API lỗi ${response.status}: ${errText}`);
        }

        const data = await response.json();
        const rawText = data?.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!rawText) {
            throw new Error("Gemini không trả về nội dung hợp lệ");
        }

        try {
            return JSON.parse(rawText);
        } catch (e) {
            throw new Error(`Không parse được JSON từ Gemini: ${rawText}`);
        }
    }

    throw new Error(`Vượt quá số lần thử lại (${maxRetries}) cho area_text: ${areaText}`);
}

module.exports = { extractAreaInfo };