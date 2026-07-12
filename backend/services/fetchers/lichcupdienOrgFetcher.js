const cheerio = require("cheerio");
const { fetchHtml } = require("./httpFetcher");
const sources = require("../../config/sources");
//Cào dữ liệu từ trang lichcupdien Org

// Trả về mảng các "raw text chunk" - mỗi chunk là 1 outage đã gom đủ 6 dòng (company/date/time/area/reason/status), y hệt cấu trúc mà scraper Flutter cũ đã dùng (.item_content_lcd_wrapper lặp 6 lần cho mỗi outage).
//
//  Lưu ý: nếu selector này ngày nào đó không còn khớp (site đổi class),
//  hàm trả về mảng rỗng thay vì throw - để job gọi hàm này biết mà fallback
//  (ví dụ gửi nguyên `$('body').text()` cho AI) thay vì crash cả batch.

async function fetchLichcupdienOrg({ batchSize = 30 } = {}) {
    const config = sources.lichcupdien_org;
    //Busted cache dùng để thêm tham số thời gian nhằm lấy dữ liệu mới nhất, đề phòng việc lấy dữ liệu cũ
    const bustedUrl = `${config.url}?_cb=${Date.now()}`;
    const html = await fetchHtml(bustedUrl);
    const $ = cheerio.load(html); //Lưu html = cheerio
    //Truy vấn dữ liệu với cheerio để lấy ra các dữ liệu cần
    //Nếu xui rủi sao này bên web có đổi tên class. Có thể cập nhật lại trong sources class cần lấy mà không cần đổi code
    const items = $(config.itemSelector)
        .map((_, el) => $(el).text().trim())
        .get()
        .filter((text) => text.length > 0);

    if (items.length === 0) {
        console.warn(
            `[lichcupdienOrgFetcher] Selector "${config.itemSelector}" không khớp phần tử nào - site có thể đã đổi cấu trúc`
        );
        return { chunks: [], fallbackFullText: $("body").text().replace(/\s+/g, " ").trim() };
    }

    // Gom mỗi 6 dòng liên tiếp thành 1 chunk (company, date, time, area, reason, status)
    const outages = [];
    for (let i = 0; i + 5 < items.length; i += 6) {
        outages.push(items.slice(i, i + 6).join("\n"));
    }

    // gộp nhiều outage thành 1 chunk lớn, cách nhau bằng dòng trống để AI dễ phân biệt ranh giới giữa các outage khi đọc.
    const chunks = [];
    for (let i = 0; i < outages.length; i += batchSize) {
        chunks.push(outages.slice(i, i + batchSize).join("\n\n"));
    }
    return { chunks, fallbackFullText: null };
}

module.exports = { fetchLichcupdienOrg };