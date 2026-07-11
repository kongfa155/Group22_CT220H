const cheerio = require("cheerio");
const { fetchHtml } = require("./httpFetcher");
const sources = require("../../config/sources");

const START_MARKER_REGEX = /Chi tiết như sau:/;
const END_MARKER_REGEX = /Lý do cúp điện/;

//Tìm link lịch cúp điện của 2 ngày gần nhất (hôm nay và mai)
async function findRelevantArticleUrls() {
    const config = sources.vietnambiz_com;
    const html = await fetchHtml(config.listingUrl);
    const $ = cheerio.load(html);
    //Lấy tất cả link có trong thẻ a, và lọc những cái bắt đầu với lịch cúp điện cần thơ 
    const hrefs = $("a[href]")
        .map((_, el) => $(el).attr("href"))
        .get()
        .filter((href) => config.articleUrlPattern.test(href))
        .map((href) => (href.startsWith("http") ? href : new URL(href, "https://vietnambiz.vn").href));
    // Loại bỏ trùng lặp với ảnh và tiêu đề
    const uniqueHrefs = [...new Set(hrefs)];

    if (uniqueHrefs.length === 0) {
        throw new Error("Không tìm thấy link bài viết nào khớp pattern trên trang danh mục");
    }

    //Tính ngày
    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(today.getDate() - 1);

    // Mọi bài đăng đều có định dạng ngày mai dù tiêu đề hiển thị là hôm nay
        const todayPattern = `ngay-mai-${today.getDate()}${today.getMonth() + 1}`;
        const yesterdayPattern = `ngay-mai-${yesterday.getDate()}${yesterday.getMonth() + 1}`;

        const resultUrls = [];

        // Lọc bài cho lịch ngày mai (nếu tòa soạn đã lên bài hôm nay)
        const todayArticle = uniqueHrefs.find(href => href.includes(todayPattern));
        if (todayArticle) resultUrls.push(todayArticle);

        // Lọc bài cho lịch hôm nay (chính là bài đăng từ ngày hôm qua)
        const yesterdayArticle = uniqueHrefs.find(href => href.includes(yesterdayPattern));
        if (yesterdayArticle) resultUrls.push(yesterdayArticle);

        if (resultUrls.length === 0) {
            throw new Error("Không tìm thấy bài viết VietnamBiz nào cho hôm nay hoặc hôm qua.");
        }

        return resultUrls; // Trả về mảng chứa tối đa 2 link

}

//Lấy nội dung trong từng bài viết
async function fetchVietnambiz() {
    const articleUrls = await findRelevantArticleUrls();
    const results = [];

    for (const url of articleUrls) {
        try {
            const html = await fetchHtml(url);
            const $ = cheerio.load(html);
            const bodyText = $("body").text().replace(/\s+/g, " ").trim();

            const startMatch = bodyText.match(START_MARKER_REGEX);
            const endMatch = bodyText.match(END_MARKER_REGEX);

            let text;
            if (!startMatch || !endMatch || endMatch.index <= startMatch.index) {
                text = bodyText;
            } else {
                text = bodyText.slice(startMatch.index, endMatch.index).trim();
            }

            results.push({ text, articleUrl: url });
        } catch (err) {
            console.error(`[vietnambizFetcher] Lỗi khi fetch bài ${url}:`, err.message);
        }
    }

    // Trả về mảng các bài viết đã bóc tách text
    return results;
}

module.exports = { fetchVietnambiz };