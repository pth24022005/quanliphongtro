# 1. Chọn hệ điều hành gốc có sẵn Python 3.10 (Bản slim cho nhẹ)
FROM python:3.10-slim

# 2. Đặt thư mục làm việc bên trong Container
WORKDIR /app

# 3. Copy file requirements.txt vào trước để cài đặt thư viện
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy toàn bộ code (app.py, serviceAccountKey.json) vào Container
COPY . .

# 5. Mở cổng 5000 để giao tiếp nội bộ
EXPOSE 5000

# 6. Khởi chạy Gunicorn với 4 Workers khi Container bật lên
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]