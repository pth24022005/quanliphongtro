import os
import psycopg
from psycopg.rows import dict_row
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# =====================================================================
# CẤU HÌNH KẾT NỐI POSTGRESQL
# =====================================================================
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_PORT = os.environ.get('DB_PORT', '5432')
DB_NAME = os.environ.get('DB_NAME', 'nestfinder_core')
DB_USER = os.environ.get('DB_USER', 'postgres')
DB_PASS = os.environ.get('DB_PASSWORD', 'postgres') # Nhớ thay pass của bạn!

def get_db_connection():
    return psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        row_factory=dict_row
    )

# =====================================================================
# API THÔNG BÁO
# =====================================================================

@app.route('/api/v1/notifications', methods=['POST'])
def create_notification():
    """Tạo thông báo mới (Dùng cho cả lúc dọn dữ liệu)"""
    data = request.json
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        query = """
            INSERT INTO notifications (title, message, type, is_read, recipient_id, room_id, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id;
        """
        cur.execute(query, (
            data.get('title', 'Thông báo'),
            data.get('message', ''),
            data.get('type', 'info'),
            data.get('is_read', False),
            data.get('recipient_id'),
            data.get('room_id'),
            data.get('created_at') # Nếu là dọn dữ liệu thì truyền vào, không thì Postgres tự lấy giờ hiện tại
        ))
        
        new_id = cur.fetchone()['id']
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Tạo thông báo thành công', 'id': new_id}), 201
    except Exception as e:
        print(f"Lỗi Database: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/notifications', methods=['GET'])
def get_notifications():
    """Lấy danh sách thông báo"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Sắp xếp mới nhất lên đầu
        cur.execute("SELECT * FROM notifications ORDER BY created_at DESC")
        notifs = cur.fetchall()
        
        for n in notifs:
            if n['created_at']:
                n['created_at'] = n['created_at'].isoformat()
                
        cur.close()
        conn.close()
        
        return jsonify(notifs), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/notifications/<int:notif_id>/read', methods=['PUT'])
def mark_notification_as_read(notif_id):
    """Đánh dấu một thông báo là đã đọc trong Postgres"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Chuyển trạng thái is_read thành True
        cur.execute(
            "UPDATE notifications SET is_read = TRUE WHERE id = %s;", 
            (notif_id,)
        )
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Đã đánh dấu đọc thông báo thành công'}), 200
    except Exception as e:
        print(f"❌ Lỗi cập nhật thông báo: {e}")
        return jsonify({'error': str(e)}), 500
    
if __name__ == '__main__':
    print("🔔 Notification Service đang chạy tại Port 5005...")
    app.run(host='0.0.0.0', port=5005, debug=True)