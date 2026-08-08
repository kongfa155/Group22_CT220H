# Các địa điểm chưa thể xác định tọa độ an toàn

Danh sách này chỉ ghi các mục không đủ rõ ràng để gán tọa độ mà không suy đoán. Các
`coordinates: []` tương ứng được giữ nguyên có chủ ý.

## Place

- `Hồ Hoàn Kiếm` — `Cần Thơ`: tên trùng với địa danh nổi tiếng ở Hà Nội, không có
  thông tin cấp dưới hoặc địa chỉ để xác định một địa điểm tương ứng tại Cần Thơ.
- `Cty TNHH KD TMDV Vinfast` — `Thốt Nốt, Cần Thơ`: thiếu địa chỉ cơ sở cụ thể.
- `Khu vực Trường Trung, Ấp Trường Đông` — `Phước Thới, Cần Thơ`: một record chứa
  hai địa danh, không rõ cần một vùng chung hay hai vùng riêng.
- `Công ty CP Cara Group - Chung cư Công ty 8` — `Cái Răng, Cần Thơ`: tên ghép hai
  đối tượng và thiếu địa chỉ cụ thể.
- `Ấp Trường Thọ A, Trường Thọ 1` — `Trường Long, Cần Thơ`: một record chứa hai
  địa danh, không rõ ranh giới cần lấy.
- `ấp Phụng Thạnh, ấp E1` — `Thạnh Quới, Cần Thơ`: một record chứa hai ấp, không
  rõ ranh giới cần lấy.
- `Khu dân cư 586 (Vạn Phát)` — `Hưng Phú, Cần Thơ`: chưa có nguồn đủ chắc chắn
  để phân biệt đúng khu/ranh giới với các tên thương mại tương tự.
- `ấp B1` — `Thạnh An, Cần Thơ`: tên quá ngắn và thiếu dữ liệu phân biệt.
- `Khu vực 1`, `Khu vực 2`, `Khu vực 3`, `Khu vực 4`, `Khu vực 6`: tên lặp lại ở
  nhiều đơn vị hành chính; một số `parent_adm` hiện cũng chứa nhiều địa danh ghép.
- Các record tên cá nhân/doanh nghiệp như `HKD Quân Hằng`, `HKD Lê Thị Ngọc Vân`,
  `Cơ sở Võ Thị Chọn`, `Cơ sở NTTS Lê Thị Thùy Linh`, `Cty TNHH Đại Tây Dương 3`:
  thiếu địa chỉ chính xác nên không tạo hình vuông 50 m.

## Road

Các đường còn `coordinates: []` chưa được gán bằng tuyến gần đúng. Đặc biệt các
tên `đường số 3`, `đường số 6` và `đường trục chính KCN Trà Nóc 2` cần xác nhận
đúng nhánh/tuyến trước khi thêm LineString.

## Quy ước khi bổ sung thủ công

- GeoJSON dùng thứ tự `[longitude, latitude]`.
- Place dạng điểm phải đổi thành `MultiPolygon` là hình vuông cạnh xấp xỉ 50 m,
  khép kín bằng cách lặp lại đỉnh đầu ở cuối.
- Place đã có ranh giới thật thì giữ ranh giới đó, không thay bằng hình vuông.
- Road đã có `coordinates` thì giữ nguyên.
