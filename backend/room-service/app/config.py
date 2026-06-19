import os

class Config:
    # Lấy từ biến môi trường nếu có, không thì dùng mặc định
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'postgresql://admin:password123@postgres_db:5432/nestfinder_core')
    SQLALCHEMY_TRACK_MODIFICATIONS = False