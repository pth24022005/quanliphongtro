# 1. Sử dụng môi trường Python tĩnh, nhẹ (Linux)
FROM python:3.11-slim

# 2. Cài đặt các công cụ thư viện C cơ bản của Linux 
# (Thuốc đặc trị để cài psycopg2 và bcrypt mượt mà, không bị văng lỗi)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Thiết lập thư mục làm việc bên trong Container
WORKDIR /app

# 4. Copy file cấu hình thư viện vào trước (Để tận dụng bộ nhớ đệm của Docker)
COPY requirements.txt .

# 5. Yêu cầu pip cài đặt các thư viện (Không dùng cache để giảm dung lượng image)
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copy toàn bộ code từ máy bạn vào trong Container
COPY . .

# 7. Mở cổng 8001 (khớp với port cấu hình trong file run.py của bạn)
EXPOSE 8001

# 8. Lệnh mặc định để khởi động Server khi Container chạy
CMD ["python", "run.py"]