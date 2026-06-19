# Sử dụng Python 3.10 bản nhẹ (slim) để tối ưu dung lượng
FROM python:3.10-slim

# Đặt thư mục làm việc bên trong container
WORKDIR /app

# Copy file requirements vào trước để cài đặt thư viện
COPY requirements.txt .

# Cài đặt thư viện (không lưu cache để giảm dung lượng)
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ mã nguồn còn lại vào container
COPY . .

# Lệnh khởi chạy ứng dụng khi container nổ máy
CMD ["python", "app.py"]