from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel
from psycopg2.extras import RealDictCursor
import jwt

from .database import get_db_connection
from .security import verify_password, hash_password, create_jwt_token, SECRET_KEY, ALGORITHM

router = APIRouter()

# ==========================================
# SCHEMAS (Định nghĩa dữ liệu đầu vào)
# ==========================================
class LoginRequest(BaseModel):
    phone: str
    password: str

class RegisterRequest(BaseModel):
    phone: str
    password: str
    full_name: str
    role: str = "tenant" # Mặc định tạo ra là người thuê

# ==========================================
# 1. API ĐĂNG NHẬP (Cấp Token)
# ==========================================
@router.post("/api/v1/auth/login")
def login(request: LoginRequest):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("SELECT id, phone, password_hash, role FROM users WHERE phone = %s", (request.phone,))
        user = cursor.fetchone()
        
        if not user or not verify_password(request.password, user['password_hash']):
            raise HTTPException(status_code=401, detail="Sai số điện thoại hoặc mật khẩu")
            
        token_data = {"user_id": str(user['id']), "phone": user['phone'], "role": user['role']}
        return {"access_token": create_jwt_token(token_data), "token_type": "bearer"}
    finally:
        cursor.close()
        conn.close()

# ==========================================
# 2. API TẠO TÀI KHOẢN (Đăng ký khách thuê)
# ==========================================
@router.post("/api/v1/auth/register")
def register(request: RegisterRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Băm mật khẩu thô ngay lập tức
        hashed_pwd = hash_password(request.password)
        
        cursor.execute(
            """
            INSERT INTO users (phone, password_hash, full_name, role)
            VALUES (%s, %s, %s, %s) RETURNING id;
            """, 
            (request.phone, hashed_pwd, request.full_name, request.role)
        )
        new_user_id = cursor.fetchone()[0]
        conn.commit()
        return {"message": "Tạo tài khoản thành công!", "user_id": new_user_id}
    except Exception as e:
        conn.rollback()
        # Bắt lỗi trùng số điện thoại
        if "unique constraint" in str(e).lower():
            raise HTTPException(status_code=400, detail="Số điện thoại này đã được sử dụng")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

# ==========================================
# 3. API LẤY THÔNG TIN CÁ NHÂN (Profile)
# ==========================================
@router.get("/api/v1/users/me")
def get_my_profile(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Thiếu hoặc sai định dạng Token")
    
    token = authorization.split(" ")[1]
    
    try:
        # Giải mã Token để biết ai đang gọi API
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("SELECT id, phone, full_name, role, created_at FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not user:
            raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")
            
        return user
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token đã hết hạn, vui lòng đăng nhập lại")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Token không hợp lệ")