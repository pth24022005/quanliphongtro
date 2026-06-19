# Sử dụng Python 3.11 làm base image
FROM python:3.11-slim

# Thiết lập thư mục làm việc
WORKDIR /app

# Cài đặt các thư viện cần thiết để build psycopg (nếu cần)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && rm -rf /var/lib/apt/lists/*

# Copy file requirements (Nếu bạn chưa có, hãy tạo file này chứa: flask, flask-cors, psycopg)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ source code vào container
COPY . .

# Mở port 5003
EXPOSE 5003

# Lệnh chạy ứng dụng
CMD ["python", "app.py"]