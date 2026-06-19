from passlib.context import CryptContext
import jwt
from datetime import datetime, timedelta

# Cấu hình băm mật khẩu
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Cấu hình JWT Token
SECRET_KEY = "Nestfinder_Super_Secret_Key_2026" # Mã bí mật để ký Token
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # Token có hạn 7 ngày

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_jwt_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt