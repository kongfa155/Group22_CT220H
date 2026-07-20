const cheerio = require("cheerio");
const { fetchHtml } = require("./httpFetcher");
const sources = require("../../config/sources");


//Tìm đúng trong đoạn giữa để lấy đúng phần cần, không láy dư
const START_MARKER_REGEX = /Lịch cúp điện Cần Thơ ngày \d{2}\/\d{2}\/\d{4}/;
const END_MARKER_REGEX = /Việc cập nhật/;

//Tự gắn sẵn huyện nên chỉ cần lưu lại, sau này lọc sang dạng data tọa độ dễ hơn, không cần truyền sang AI phức tạp
//  Trả về { text } duy nhất (không tách theo huyện ở bước fetch này) vì
//  dữ liệu vốn đã trộn chung theo đúng cấu trúc gốc của trang.

async function fetchXemlichcatdien() {
    const config = sources.xemlichcatdien_com; //Lấy url
    //Lấy dữ liệu mới không lấy cache cũ
    const bustedUrl = `${config.url}?_cb=${Date.now()}`;
    const html = await fetchHtml(bustedUrl);
    const $ = cheerio.load(html);
    const bodyText = $("body").text().replace(/\s+/g, " ").trim();

    const endMatch = bodyText.match(END_MARKER_REGEX);
    //Không tìm được điểm cắt thì gửi toàn bộ trang cho AI cho AI xử lý
    if (!endMatch) {
        console.warn(
            "[xemlichcatdienFetcher] Không tìm thấy marker kết thúc - fallback gửi toàn trang cho AI"
        );
        const withoutSpamFooter = bodyText.split(/\|\s*\[/)[0];
        return { text: withoutSpamFooter };
    }

//Lấy lần cuối cụm xuất hiện vì ở trên có danh mục, nguy cơ nó liệt kê phần đó vào => truy xuất html dư
    const startMatches = [...bodyText.matchAll(new RegExp(START_MARKER_REGEX, "g"))].filter(
        (m) => m.index < endMatch.index
    );

    if (startMatches.length === 0) {
        console.warn(
            "[xemlichcatdienFetcher] Không tìm thấy marker bắt đầu trước marker kết thúc - fallback gửi toàn trang cho AI"
        );
        const withoutSpamFooter = bodyText.split(/\|\s*\[/)[0];
        return { text: withoutSpamFooter };
    }

    const startMatch = startMatches[startMatches.length - 1];
    const section = bodyText.slice(startMatch.index, endMatch.index).trim();
    return { text: section };
}

module.exports = { fetchXemlichcatdien };