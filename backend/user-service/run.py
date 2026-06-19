from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.auth_routes import router as auth_router
from app.database import init_db # Import hàm tạo DB

app = FastAPI(title="User Service - NestFinder")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 👉 TỰ ĐỘNG KHỞI TẠO BẢNG KHI BẬT SERVER
@app.on_event("startup")
def on_startup():
    print("Đang kiểm tra và khởi tạo cấu trúc Database...")
    init_db()
    print("Database đã sẵn sàng!")

app.include_router(auth_router)

if __name__ == "__main__":
    uvicorn.run("run:app", host="0.0.0.0", port=8001, reload=True)