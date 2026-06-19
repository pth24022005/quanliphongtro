from app import create_app
from flask_cors import CORS  # 👉 THÊM DÒNG NÀY

# Gốc của ứng dụng được build từ nhà máy
app = create_app()

# 👉 THÊM DÒNG NÀY: Mở khóa CORS cho toàn bộ API, cho phép Flutter Web gọi vào
CORS(app, resources={r"/api/*": {"origins": "*"}})

if __name__ == '__main__':
    print("🏠 Room Service (Chuẩn Enterprise) khởi chạy tại Port 5002...")
    app.run(host='0.0.0.0', port=5002, debug=True)