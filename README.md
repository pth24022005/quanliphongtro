# NestFinder - Ứng dụng Quản lý Phòng trọ

NestFinder là một hệ thống quản lý phòng trọ toàn diện, được xây dựng theo kiến trúc Microservices. Dự án bao gồm một ứng dụng frontend cho quản trị viên (chủ trọ) và một hệ thống backend mạnh mẽ để xử lý logic nghiệp vụ, dữ liệu và giao tiếp giữa các thành phần.

## ✨ Tính năng chính

- **Bảng điều khiển (Dashboard):** Giao diện tổng quan trực quan hiển thị các chỉ số tài chính quan trọng như doanh thu dự kiến, đã thu, và còn lại trong tháng.
- **Quản lý Phòng:** Quản lý danh sách phòng, thêm, sửa, xóa thông tin chi tiết từng phòng (diện tích, giá thuê, trạng thái).
- **Quản lý Khách thuê:** Quản lý thông tin khách thuê trọ, bao gồm thông tin cá nhân và lịch sử thuê.
- **Quản lý Hóa đơn:** Tự động hoặc thủ công tạo hóa đơn hàng tháng (tiền phòng, điện, nước, dịch vụ), theo dõi trạng thái thanh toán (`chưa thanh toán`, `đã thanh toán`).
- **Thông báo:** Hệ thống thông báo cho quản trị viên về các sự kiện quan trọng như khách thuê xác nhận thanh toán, hợp đồng sắp hết hạn.
- **Xác thực & Phân quyền:** Phân quyền người dùng (Admin, Tenant) sử dụng JWT (JSON Web Tokens).

## 🏗️ Kiến trúc Hệ thống

Dự án áp dụng kiến trúc **Microservices** để đảm bảo tính linh hoạt, khả năng mở rộng và bảo trì dễ dàng.

- **Nginx:** Đóng vai trò là Reverse Proxy, là cổng vào duy nhất (`localhost:80`) cho tất cả các yêu cầu từ bên ngoài, sau đó điều hướng đến API Gateway.
- **API Gateway:** Chịu trách nhiệm xác thực JWT, định tuyến các yêu cầu đến các microservice tương ứng.
- **Backend Services:**
    - **User Service:** Quản lý thông tin người dùng và quá trình xác thực, đăng nhập, tạo token.
    - **Room Service:** Xử lý tất cả các nghiệp vụ liên quan đến phòng trọ và khách thuê.
    - **Billing Service:** Quản lý hóa đơn, tính toán chi phí và theo dõi thanh toán.
    - **Notification Service:** Gửi và quản lý các thông báo trong hệ thống.
- **Database:** Sử dụng **PostgreSQL** làm cơ sở dữ liệu quan hệ chính cho các service.
- **Message Broker:** **RabbitMQ** được sử dụng để giao tiếp bất đồng bộ giữa các service, giúp giảm sự phụ thuộc và tăng khả năng chịu lỗi.
- **Frontend:** Ứng dụng **Flutter** đa nền tảng (web, mobile) cung cấp giao diện người dùng cho quản trị viên.

## 🛠️ Công nghệ sử dụng (Tech Stack)

- **Frontend:**
    - Ngôn ngữ: **Dart**
    - Framework: **Flutter**
    - Quản lý trạng thái: **Riverpod**
- **Backend:**
    - Ngôn ngữ: **Python**
    - Framework: **Flask**
    - ORM: **SQLAlchemy**
    - Database Driver: **Psycopg**
- **Database:** **PostgreSQL**
- **Infrastructure & DevOps:**
    - Containerization: **Docker, Docker Compose**
    - Web Server / Reverse Proxy: **Nginx**
    - Message Broker: **RabbitMQ**

## 🚀 Hướng dẫn Cài đặt & Khởi chạy

### Yêu cầu

- Flutter SDK (phiên bản 3.x)
- Docker
- Docker Compose

### 1. Cài đặt Backend

1.  Di chuyển vào thư mục `backend`:
    ```sh
    cd backend
    ```
2.  Khởi chạy tất cả các service bằng Docker Compose:
    ```sh
    docker-compose up --build -d
    ```
    Lệnh này sẽ build image cho từng service và khởi chạy chúng trong background. Các service sẽ giao tiếp với nhau qua mạng ảo do Docker tạo ra.
    - API Gateway sẽ chạy tại `http://localhost` (thông qua Nginx port 80).
    - Các service khác sẽ được expose trên các port tương ứng (ví dụ: User Service ở `8001`, Room Service ở `5002`,...) nhưng chỉ nên được truy cập thông qua Gateway.

### 2. Cài đặt Frontend

1.  Mở một cửa sổ terminal khác, di chuyển vào thư mục `frontend`:
    ```sh
    cd frontend
    ```
2.  Cài đặt các dependency của Flutter:
    ```sh
    flutter pub get
    ```
3.  Chạy ứng dụng (ví dụ cho nền tảng web trên Chrome):
    ```sh
    flutter run -d chrome
    ```
    Ứng dụng Flutter sẽ tự động kết nối đến các API backend đang chạy trên Docker.

## 📂 Cấu trúc Thư mục

```
.
├── backend/
│   ├── api-gateway/        # Gateway định tuyến và xác thực
│   ├── billing-service/    # Service quản lý hóa đơn
│   ├── notification-service/ # Service quản lý thông báo
│   ├── room-service/       # Service quản lý phòng và khách thuê
│   ├── user-service/       # Service quản lý người dùng
│   ├── docker-compose.yml  # File điều phối các container
│   └── nginx/              # Cấu hình Nginx reverse proxy
└── frontend/
    ├── lib/
    │   ├── core/             # Các thành phần cốt lõi (router, theme,...)
    │   ├── features/         # Các module tính năng (auth, dashboard,...)
    │   └── main.dart         # Điểm khởi đầu của ứng dụng
    └── pubspec.yaml        # Quản lý các gói phụ thuộc của Flutter
```

---

Chúc bạn có một trải nghiệm tốt với NestFinder!
