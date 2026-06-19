FROM python:3.10-slim

WORKDIR /app

# Cài đặt thư viện lõi của Linux để hỗ trợ psycopg2 (PostgreSQL)
RUN apt-get update && apt-get install -y libpq-dev gcc

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Mở port 5002 cho Room Service
EXPOSE 5002

# Chạy bằng Gunicorn với 2 Workers
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5002", "run:app"]