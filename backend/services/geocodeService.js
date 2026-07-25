const THROTTLE_MS = Number(process.env.NOMINATIM_MIN_INTERVAL_MS || 1100);
let lastCallAt = 0;

async function throttle() {
    const now = Date.now();
    const wait = lastCallAt + THROTTLE_MS - now;
    if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait));
    lastCallAt = Date.now();
}

async function geocodeGeometry(query) {
    await throttle();

    const url =
        "https://nominatim.openstreetmap.org/search?" +
        new URLSearchParams({
            q: query,
            format: "geojson",
            polygon_geojson: "1",
            limit: "3", // lấy vài kết quả để có cái mà lọc, thay vì chỉ 1
            countrycodes: "vn",
        });

    const response = await fetch(url, {
        headers: { "User-Agent": "CanThoOutageMapApp/1.0 (do an CT220H)" },
    });

    if (!response.ok) throw new Error(`Nominatim lỗi ${response.status}`);

    const geojson = await response.json();
    if (!geojson.features || geojson.features.length === 0) return null;

    return geojson.features.map((f) => ({
        geometry: f.geometry,
        displayName: f.properties?.display_name || null,
        osmClass: f.properties?.class || null, // "highway", "place", "landuse", "building"...
    }));
}

module.exports = { geocodeGeometry };