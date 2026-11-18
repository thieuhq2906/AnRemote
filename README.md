# AnRemote

Điều khiển điều hòa Toshiba bằng iPhone khi mất remote.

iPhone không phát được tín hiệu hồng ngoại của remote, nên hệ thống gồm hai phần:

```
iPhone (app AnRemote)  --Wi-Fi nhà-->  mạch ESP + LED hồng ngoại  --IR-->  điều hòa
```

| Thư mục | Nội dung |
|---|---|
| `ios/` | App iPhone (SwiftUI, iOS 15 trở lên) |
| `firmware/` | Chương trình cho mạch ESP8266 / ESP32 (PlatformIO) |
| `.github/workflows/build.yml` | Build `.ipa` chưa ký và firmware `.bin` trên GitHub Actions |

## 1. Phần cứng

Cần mua (khoảng 100.000 đ):

- 1 mạch **Wemos D1 mini** hoặc NodeMCU (ESP8266), hoặc ESP32 DevKit
- 1 **module phát hồng ngoại** (loại KY-005 hoặc module "IR transmitter" 3 chân), hoặc LED hồng ngoại 940 nm rời
- Cáp USB và củ sạc 5 V

Đấu dây với module 3 chân:

| Module IR | Mạch ESP |
|---|---|
| S / DAT | D2 (GPIO4) |
| VCC / + | 3V3 |
| GND / − | GND |

Nếu dùng LED rời: `GPIO4 → điện trở 100 Ω → chân dài LED`, `chân ngắn LED → GND`. Cách này phát được khoảng 1–2 m. Muốn xa hơn thì dùng module có sẵn transistor.

## 2. Nạp firmware

Cài [PlatformIO](https://platformio.org/install), cắm mạch vào máy tính rồi chạy:

```
cd firmware
pio run -e d1_mini -t upload
```

Đổi `d1_mini` thành `nodemcuv2` hoặc `esp32dev` tùy mạch.

Kết nối Wi-Fi lần đầu:

1. Mạch phát ra Wi-Fi tên **AnRemote-Setup**. Dùng iPhone vào Wi-Fi đó.
2. Trang cấu hình tự mở. Chọn Wi-Fi nhà, nhập mật khẩu, lưu.
3. Mạch khởi động lại và có địa chỉ `http://anremote.local`.

Thử nhanh bằng trình duyệt, điều hòa phải kêu "bíp":

```
http://anremote.local/api/set?power=1&mode=cool&temp=25
```

## 3. App iPhone

File `.ipa` được build chưa ký trên GitHub Actions (tab **Actions** → lần chạy mới nhất → artifact **AnRemote-ipa**). Ký và cài bằng công cụ bạn quen dùng (Sideloadly, AltStore, ESign...).

Lần đầu mở app, chọn **Cho phép** khi iOS hỏi quyền tìm thiết bị trong mạng nội bộ. Nếu app báo không tìm thấy bộ phát, vào **Cài đặt** (biểu tượng bánh răng) và nhập địa chỉ IP của mạch thay cho `anremote.local`.

## API của mạch

| Lệnh | Ý nghĩa |
|---|---|
| `GET /api/state` | Trạng thái mạch đang nhớ |
| `GET` hoặc `POST /api/set` | Đổi trạng thái và phát lệnh IR |

Tham số của `/api/set` (bỏ tham số nào thì giữ giá trị cũ):

| Tham số | Giá trị |
|---|---|
| `power` | `1` / `0` |
| `mode` | `auto`, `cool`, `dry`, `heat`, `fan` |
| `temp` | `17` đến `30` |
| `fan` | `0` (tự động) đến `5` |
| `swing` | `1` / `0` |
| `turbo` | `1` / `0` (Hi-Power) |
| `econo` | `1` / `0` (Eco) |

## Giới hạn

- Remote hồng ngoại chỉ gửi một chiều. App hiển thị trạng thái của lệnh gửi gần nhất, không đọc được trạng thái thật của điều hòa.
- Mạch nhớ trạng thái trong RAM, mất điện sẽ về mặc định (tắt, làm lạnh, 25 °C).
- Firmware dùng giao thức `TOSHIBA_AC` của thư viện IRremoteESP8266, khớp với phần lớn điều hòa treo tường Toshiba. Một số dòng không có Hi-Power, Eco hoặc sưởi; khi đó nút tương ứng không có tác dụng.
