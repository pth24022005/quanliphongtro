import os
import psycopg
from psycopg.rows import dict_row
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import requests
import jwt
import datetime
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)

# =====================================================================
# 1. CẤU HÌNH KẾT NỐI POSTGRESQL TẬP TRUNG
# =====================================================================
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_PORT = os.environ.get('DB_PORT', '5432')
DB_NAME = os.environ.get('DB_NAME', 'nestfinder_core')
DB_USER = os.environ.get('DB_USER', 'postgres')
DB_PASS = os.environ.get('DB_PASSWORD', 'postgres')

def get_db_connection():
    return psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        row_factory=dict_row
    )

# Secret Key để mã hóa JWT nội bộ
JWT_SECRET = 'NestFinder_Super_Secret_Key_2026'
JWT_REFRESH_SECRET = 'NestFinder_Super_Refresh_Secret_Key_2026'

# Địa chỉ các Microservices nội bộ trong hệ thống Docker
SERVICES = {
    'users': 'http://user_service:5001/api/v1/users',
    'rooms': 'http://room_service:5002/api/v1/rooms',
    'billing': 'http://billing_service:5003/api/v1/billing',
    'incidents': 'http://incident_service:5004/api/v1/incidents',
    'notifications': 'http://notification_service:5005/api/v1/notifications'
}

# =====================================================================
# 2. ENDPOINT AUTH: ĐĂNG KÝ, ĐĂNG NHẬP & LÀM MỚI TOKEN
# =====================================================================

@app.route('/api/v1/auth/register', methods=['POST'])
def register_user():
    """Tạo tài khoản tự động cho khách thuê khi thêm Hợp đồng thành công"""
    data = request.json
    phone = data.get('phone') 
    raw_password = data.get('password') 
    name = data.get('full_name')
    role = data.get('role', 'tenant')

    # Mã hóa mật khẩu
    hashed_password = generate_password_hash(raw_password)

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # 👉 Tự động sinh ID và thời gian để chống lỗi Constraint của Database
        new_id = str(uuid.uuid4())
        now = datetime.now()

        cur.execute(
            """
            INSERT INTO users (id, phone, password_hash, full_name, role, created_at, is_active) 
            VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id;
            """,
            (new_id, phone, hashed_password, name, role, now, True)
        )
        
        inserted_id = cur.fetchone()['id']
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Tạo tài khoản thành công', 'id': inserted_id}), 201

    except Exception as e:
        print(f"❌ Lỗi DB khi tạo tài khoản: {e}")
        return jsonify({'error': f'Số điện thoại đã tồn tại hoặc lỗi hệ thống ({str(e)})'}), 400


@app.route('/api/v1/auth/login', methods=['POST'])
def login():
    """Đăng nhập bằng SĐT và Mật khẩu chuẩn mã hóa hash"""
    data = request.json
    phone = data.get('phone')
    password = data.get('password')
    if not phone or not password:
        return jsonify({'error': 'Thiếu số điện thoại hoặc mật khẩu'}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # 👉 Query chính xác cột password_hash từ bảng dữ liệu
        cur.execute("SELECT id, phone, password_hash, role FROM users WHERE phone = %s", (phone,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        # 👉 Kiểm tra mật khẩu gốc gửi lên với chuỗi hash mã hóa dưới DB
        if not user or not check_password_hash(user['password_hash'], password):
            return jsonify({'error': 'Sai số điện thoại hoặc mật khẩu'}), 401

        uid = str(user['id'])
        role = user['role']

        # Tạo Access Token chứa đầy đủ thông tin phân quyền cho Flutter đọc công khai
        access_payload = {
            'uid': uid,
            'phone': phone,
            'role': role,
            'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
        }
        access_token = jwt.encode(access_payload, JWT_SECRET, algorithm='HS256')

        # Tạo Refresh Token duy trì phiên
        refresh_payload = {
            'uid': uid,
            'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
        }
        refresh_token = jwt.encode(refresh_payload, JWT_REFRESH_SECRET, algorithm='HS256')

        return jsonify({
            'message': 'Đăng nhập thành công',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': 900
        }), 200

    except Exception as e:
        print(f"❌ Lỗi xử lý đăng nhập hệ thống: {e}")
        return jsonify({'error': 'Lỗi hệ thống', 'details': str(e)}), 500


@app.route('/api/v1/auth/refresh', methods=['POST'])
def refresh_token():
    """Cấp Access Token mới khi vé cũ hết hạn 15 phút"""
    data = request.json
    refresh_token = data.get('refresh_token')

    if not refresh_token:
        return jsonify({'error': 'Thiếu refresh_token'}), 400

    try:
        decoded_refresh = jwt.decode(refresh_token, JWT_REFRESH_SECRET, algorithms=['HS256'])
        uid = decoded_refresh.get('uid')

        # Đọc thông tin quyền hạn để tái cấp vé mới
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT phone, role FROM users WHERE id = %s", (uid,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if not user:
            return jsonify({'error': 'Tài khoản không tồn tại trên hệ thống'}), 401

        new_access_payload = {
            'uid': uid,
            'phone': user['phone'],
            'role': user['role'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
        }
        new_access_token = jwt.encode(new_access_payload, JWT_SECRET, algorithm='HS256')

        return jsonify({
            'access_token': new_access_token,
            'expires_in': 900
        }), 200

    except jwt.ExpiredSignatureError:
        return jsonify({'error': 'Refresh Token đã hết hạn. Vui lòng đăng nhập lại.'}), 401
    except Exception as e:
        return jsonify({'error': 'Refresh Token không hợp lệ.'}), 401


# =====================================================================
# 3. HÀM KIỂM TRA ACCESS TOKEN KHI GỌI SANG CÁC DỊCH VỤ CON
# =====================================================================
def verify_custom_access_token(auth_header):
    if not auth_header or not auth_header.startswith('Bearer '):
        return False, "Thiếu hoặc sai định dạng Authorization header."
    
    token = auth_header.split(" ")[1]
    
    try:
        decoded_token = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        return True, decoded_token
    except jwt.ExpiredSignatureError:
        return False, "Access Token đã hết hạn. Vui lòng gọi API /refresh."
    except jwt.InvalidTokenError:
        return False, "Access Token không hợp lệ."


# =====================================================================
# 4. REVERSE PROXY (ĐỊNH TUYẾN THÔNG MINH ĐẾN MICROSERVICES)
# =====================================================================
@app.route('/api/v1/<service_name>', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
@app.route('/api/v1/<service_name>/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
def gateway_proxy(service_name, path):
    if request.method == 'OPTIONS':
        return Response(status=200)

    if service_name not in SERVICES:
        return jsonify({'error': 'Service không tồn tại'}), 404

    auth_header = request.headers.get('Authorization')
    is_valid, token_data = verify_custom_access_token(auth_header)

    if not is_valid:
        return jsonify({'error': 'Unauthorized', 'message': token_data}), 401

    target_url = f"{SERVICES[service_name]}/{path}" if path else SERVICES[service_name]
    if request.query_string:
        target_url = f"{target_url}?{request.query_string.decode('utf-8')}"

    try:
        headers = {k: v for k, v in request.headers if k.lower() != 'host'}
        headers['X-User-UID'] = token_data.get('uid')

        resp = requests.request(
            method=request.method,
            url=target_url,
            headers=headers,
            data=request.get_data(),
            cookies=request.cookies,
            allow_redirects=False,
            timeout=10
        )

        excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
        resp_headers = [(name, value) for (name, value) in resp.raw.headers.items() if name.lower() not in excluded_headers]
        
        return Response(resp.content, resp.status_code, resp_headers)

    except requests.exceptions.ConnectionError:
        return jsonify({'error': 'Service Unavailable'}), 503


if __name__ == '__main__':
    print("🚀 API Gateway NestFinder khởi chạy tại Port 5000 (Auth Postgres Ready)...")
    app.run(host='0.0.0.0', port=5000, debug=True)