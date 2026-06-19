import psycopg2
from psycopg2.extras import RealDictCursor
import os

# 👉 Import thêm hàm băm mật khẩu từ file security
from .security import hash_password

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "nestfinder_core")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "password123") # Đảm bảo đúng pass Postgres của bạn

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                phone VARCHAR(20) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                full_name VARCHAR(100),
                role VARCHAR(20) DEFAULT 'tenant',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT TRUE
            );
        ''')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);')

        # ========================================================
        # TỰ ĐỘNG TẠO TÀI KHOẢN ADMIN NẾU CHƯA TỒN TẠI
        # ========================================================
        cursor.execute("SELECT id FROM users WHERE phone = 'admin'")
        if not cursor.fetchone(): # Nếu không tìm thấy ai có tài khoản là 'admin'
            admin_pwd = hash_password("admin123") # Băm cái pass admin123 ra
            cursor.execute(
                """
                INSERT INTO users (phone, password_hash, full_name, role) 
                VALUES (%s, %s, %s, %s)
                """,
                ('admin', admin_pwd, 'Quản trị viên', 'admin')
            )
            print("🌟 Đã tự động khởi tạo tài khoản Admin: admin / admin123")

        conn.commit()
    except Exception as e:
        print(f"Lỗi khởi tạo DB: {e}")
        conn.rollback() # Trả lại trạng thái nếu lỗi
    finally:
        cursor.close()
        conn.close()