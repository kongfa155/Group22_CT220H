async function fetchHtml(url, { timeoutMs = 10000 } = {}) {
    const controller = new AbortController(); //Dùng để hủy yêu cầu, nếu bị treo
    const timer = setTimeout(() => controller.abort(), timeoutMs); //Tạo time out
    //Gửi http get đến link
    try {
        const res = await fetch(url, {
            signal: controller.signal,
            headers: {
                "User-Agent":
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36",
                "Accept":
                    "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7",
                // Một số cache/CDN phân biệt response theo có/không có header này
                "Cache-Control": "no-cache",
                "Pragma": "no-cache",
            },
        });
        //Trả kết ủa nếu fetch thành công
        if (!res.ok) {
            throw new Error(`HTTP ${res.status} khi fetch ${url}`);
        }

        return await res.text();
    } finally {
        clearTimeout(timer);
    }
}

module.exports = { fetchHtml };