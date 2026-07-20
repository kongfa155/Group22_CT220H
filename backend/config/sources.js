module.exports = {
    lichcupdien_org: {
        type: "org_selector",
        url: "https://lichcupdien.org/lich-cup-dien-can-tho",
        coverage: "week_range",
        // Cào theo mẫu cũ vì đã hoạt động
        // mỗi outage được chia thành 6 div liên tiếp cùng class này.
        itemSelector: ".item_content_lcd_wrapper",
    },

    // lichcupdien_vn: ĐÃ BỎ - server dùng cache (LiteSpeed) trả dữ liệu không
    // nhất quán giữa các lần gọi, đã thử header/cache-busting/chờ revalidate
    // đều không khắc phục được.

    vietnambiz_com: {
        type: "news_listing",
        coverage: "today_or_tomorrow", // bài đăng trước ~12h trưa: lịch ngày mai; sau đó: lịch hôm nay
        listingUrl: "https://vietnambiz.vn/lich-cup-dien-can-tho.html",
        // Link bài viết luôn có prefix này và đuôi .htm (khác đuôi .html của
        // chính trang danh mục) - dùng để lọc link bài mới nhất không cần CSS class.
       articleUrlPattern: /\/lich-cup-dien-can-tho-.*\.htm$/,
    },

    xemlichcatdien_com: {
        type: "aggregator_marker",
        coverage: "today_only",
        url: "https://xemlichcatdien.com/lich-cup-dien-can-tho/",
    },
};