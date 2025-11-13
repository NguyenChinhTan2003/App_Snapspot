# SnapSpot App

**SnapSpot** là ứng dụng Flutter được phát triển nhằm tạo ra một nền tảng chia sẻ vị trí và cảm xúc, nơi người dùng có thể check-in, đăng ảnh, ghi lại trải nghiệm và khám phá các checkin xung quanh.  
Ứng dụng được xây dựng với **Mapbox**, **Firebase**, và **GetX**, tập trung vào hiệu năng, trải nghiệm bản đồ tương tác và khả năng mở rộng.

---

## ⚙️ Các module chức năng chính

### 🗺️ Bản đồ (Map Feature)
- Sử dụng **`mapbox_maps_flutter`** để hiển thị bản đồ và marker.
- Tích hợp **Mapbox Directions API** để **vẽ đường đi** từ vị trí hiện tại đến điểm đích (spot).
- Cho phép **chuyển đổi giữa chế độ bản đồ vệ tinh và bản đồ đường đi**.
- Quản lý marker động (spot) dựa trên dữ liệu từ Firestore.

---

### 🔐 Xác thực người dùng (Authentication)
- Đăng nhập bằng **Google Account** thông qua **`firebase_auth`** và **`google_sign_in`**.
- Sau khi xác thực, dữ liệu người dùng (avatar, tên hiển thị, email, v.v.) được lưu vào **Firestore**.
- Hỗ trợ cập nhật thông tin người dùng:
  - Đổi **avatar** (Firebase Storage)
  - Đổi **tên hiển thị** (Firestore update)

---

### 📝 Check-in Management
- Mỗi check-in bao gồm:
  - `spotId`, `name`, `vibe`, `category`, `content`, `images`, `userId`, `createdAt` , `reactions`,  `latitude` , `longitude` 
- Người dùng chọn vị trí trên bản đồ → mở giao diện tạo check-in.
- Cho phép:
  - **Chụp ảnh** hoặc **chọn ảnh từ thư viện** (`image_picker`, `wechat_assets_picker`)
  - **Lưu dữ liệu check-in** lên **Firestore**
  - Ảnh upload lên **Firebase Storage** 
- Cho phép **sửa (update)** và **xóa (delete)** check-in trong **lịch sử checkin**.

---

### ❤️ Tương tác check-in
- Khi người dùng nhấn vào marker trên bản đồ:
  - Ứng dụng hiển thị danh sách check-in tại spot đó.
  - Mỗi check-in có thể **được like hoặc dislike** 
- Hiển thị ảnh bằng `photo_view` để xem ảnh toàn màn hình (zoom/pan).

---

### 🚗 Vẽ đường đi (Routing)
- Tích hợp **Mapbox Directions API** để tạo tuyến đường từ vị trí hiện tại đến spot.
- Dữ liệu trả về dạng GeoJSON, được parse và hiển thị trên bản đồ bằng polyline layer.
- Logic xử lý được đóng gói trong `mapbox_service.dart`.

---

### 🔍 Tìm kiếm & Lọc dữ liệu
- Tìm kiếm **theo tên địa điểm** hoặc **lọc theo danh mục (category)**.
- Dùng package **`diacritic`** để loại bỏ dấu tiếng Việt, giúp tìm kiếm “không phân biệt dấu”.
  - Ví dụ: gõ “ca phe” vẫn khớp với “Cà Phê Góc Nhỏ”.

---

### 🧭 Xử lý vị trí & quyền truy cập
- **`geolocator`**: lấy vị trí hiện tại của thiết bị.
- **`permission_handler`**: xin quyền vị trí và thư viện ảnh trước khi sử dụng.

---

## 🔧 Công nghệ & Package chính

| Package | Mục đích |
|----------|----------|
| `get` | State management & routing |
| `mapbox_maps_flutter` | Bản đồ và tương tác marker |
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Hạ tầng backend |
| `google_sign_in` | Đăng nhập Google |
| `image_picker`, `wechat_assets_picker`, `photo_manager`, `photo_view` | Xử lý ảnh |
| `geolocator` | Lấy vị trí |
| `permission_handler` | Xử lý quyền |
| `diacritic` | Tìm kiếm không dấu |
| `http` | Gọi Mapbox Directions API |
| `uuid` | Sinh ID duy nhất cho ảnh & check-in |

---

## 🛠️ File demo 
https://drive.google.com/drive/folders/1LgcZGrx2Rl5BGVt3u08iqDaahC_1-iPw?usp=sharing

---

## Cấu trúc dự án 

