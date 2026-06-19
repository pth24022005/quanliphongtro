from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from app.config import Config

# Khởi tạo instance của DB (chưa gắn vào app vội)
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Gắn DB vào app
    db.init_app(app)
    
    # Import Model để SQLAlchemy nhận diện cấu trúc
    from app import models
    
    # Đăng ký Blueprint cho Routes
    from app.routes import room_bp
    app.register_blueprint(room_bp, url_prefix='/api/v1/rooms')
    
    # Tự động tạo bảng nếu chưa có
    with app.app_context():
        db.create_all()
        
    return app