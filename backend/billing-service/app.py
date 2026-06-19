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
DB_PASS = os.environ.get('DB_PASSWORD', 'postgres') # Thay bằng pass của bạn

def get_db_connection():
    # Sử dụng psycopg v3 và dict_row thay cho psycopg2
    return psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        row_factory=dict_row
    )

# =====================================================================
# API ENDPOINTS
# =====================================================================

@app.route('/api/v1/billing/invoices', methods=['POST'])
def create_invoice():
    """Tạo hóa đơn mới (Dùng cho quá trình dọn dữ liệu & chốt số hằng tháng)"""
    data = request.json
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        query = """
            INSERT INTO invoices (
                room_id, room_name, tenant_name, month, year, 
                rent_cost, electricity_usage, electricity_cost, 
                water_usage, water_cost, internet_cost, service_cost, 
                total_amount, status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) 
            RETURNING id;
        """
        
        # [FIX] Ép kiểu dữ liệu đầu vào để đảm bảo lưu đúng định dạng trong DB.
        # Điều này sẽ ngăn lỗi phát sinh ngay từ gốc, giả sử cột trong DB là kiểu số.
        cur.execute(query, (
            data.get('roomId'), 
            data.get('roomName'), 
            data.get('tenantName'),
            int(data.get('month')) if data.get('month') is not None else None, 
            int(data.get('year')) if data.get('year') is not None else None, 
            float(data.get('rentCost', 0.0)),
            int(data.get('electricityUsage', 0)), 
            float(data.get('electricityCost', 0.0)),
            int(data.get('waterUsage', 0)), 
            float(data.get('waterCost', 0.0)),
            float(data.get('internetCost', 0.0)), 
            float(data.get('serviceCost', 0.0)),
            float(data.get('totalAmount', 0.0)), 
            data.get('status', 'unpaid')
        ))
        
        new_id = cur.fetchone()['id']
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Tạo hóa đơn thành công', 'id': new_id}), 201
        
    except Exception as e:
        print(f"Lỗi Database: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/v1/billing/invoices/room/<room_id>', methods=['GET'])
def get_invoices_by_room(room_id):
    """Lấy danh sách hóa đơn theo ID phòng (Flutter sẽ dùng API này để tính tổng nợ)"""
    status_filter = request.args.get('status') # Có thể truyền ?status=unpaid
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        if status_filter:
            cur.execute(
                "SELECT * FROM invoices WHERE room_id = %s AND status = %s ORDER BY created_at DESC", 
                (room_id, status_filter)
            )
        else:
            cur.execute(
                "SELECT * FROM invoices WHERE room_id = %s ORDER BY created_at DESC", 
                (room_id,)
            )
            
        invoices = cur.fetchall()
        
        # Format lại datetime và ép kiểu các trường số để đảm bảo tính nhất quán
        for inv in invoices:
            if inv.get('created_at'):
                inv['created_at'] = inv['created_at'].isoformat()

            # [FIX] Ép kiểu các trường số để tránh lỗi type 'String' is not a subtype of type 'int' trên Flutter.
            # Nguyên nhân: Dữ liệu số (tháng, tiền điện,...) có thể đang được lưu dưới dạng text trong DB.
            int_keys = ['id', 'month', 'year', 'electricity_usage', 'water_usage']
            float_keys = [
                'rent_cost', 'electricity_cost', 'water_cost', 'internet_cost', 
                'service_cost', 'total_amount'
            ]

            for key in int_keys:
                if inv.get(key) is not None:
                    try:
                        inv[key] = int(inv[key])
                    except (ValueError, TypeError):
                        pass # Bỏ qua nếu không chuyển đổi được

            for key in float_keys:
                if inv.get(key) is not None:
                    try:
                        inv[key] = float(inv[key])
                    except (ValueError, TypeError):
                        pass # Bỏ qua nếu không chuyển đổi được

        cur.close()
        conn.close()
        
        return jsonify(invoices), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/billing/invoices', methods=['GET'])
def get_all_invoices():
    """Lấy danh sách TẤT CẢ hóa đơn (Dùng cho Trang Tổng quan tính doanh thu)"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Lấy tất cả hóa đơn, mới nhất lên đầu
        cur.execute("SELECT * FROM invoices ORDER BY created_at DESC")
        invoices = cur.fetchall()
        
        # Format lại datetime và ép kiểu (Y hệt hàm get_invoices_by_room)
        for inv in invoices:
            if inv.get('created_at'):
                inv['created_at'] = inv['created_at'].isoformat()

            int_keys = ['id', 'month', 'year', 'electricity_usage', 'water_usage']
            float_keys = [
                'rent_cost', 'electricity_cost', 'water_cost', 'internet_cost', 
                'service_cost', 'total_amount'
            ]

            for key in int_keys:
                if inv.get(key) is not None:
                    try: inv[key] = int(inv[key])
                    except: pass

            for key in float_keys:
                if inv.get(key) is not None:
                    try: inv[key] = float(inv[key])
                    except: pass

        cur.close()
        conn.close()
        
        return jsonify(invoices), 200
        
    except Exception as e:
        print(f"❌ Lỗi lấy tất cả hóa đơn: {e}")
        return jsonify({'error': str(e)}), 500
    
@app.route('/api/v1/billing/invoices/<int:invoice_id>/status', methods=['PUT'])
def update_invoice_status(invoice_id):
    """Cập nhật trạng thái thanh toán của Hóa đơn (unpaid -> paid)"""
    data = request.json
    new_status = data.get('status', 'unpaid')
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute(
            "UPDATE invoices SET status = %s WHERE id = %s;", 
            (new_status, invoice_id)
        )
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': f'Hóa đơn đã được chuyển sang trạng thái {new_status}'}), 200
    except Exception as e:
        print(f"❌ Lỗi cập nhật hóa đơn: {e}")
        return jsonify({'error': str(e)}), 500
    
if __name__ == '__main__':
    print("💰 Billing Service đang chạy tại Port 5003...")
    app.run(host='0.0.0.0', port=5003, debug=True)