from flask import Blueprint, request, jsonify
from app.models import Room
from app import db

# Tạo Blueprint thay vì dùng app.route thẳng
room_bp = Blueprint('room_bp', __name__)

@room_bp.route('', methods=['GET'])
def get_rooms():
    rooms = Room.query.order_by(Room.id.desc()).all()
    return jsonify([room.to_dict() for room in rooms]), 200

@room_bp.route('', methods=['POST'])
def create_room():
    data = request.json
    if not data or 'name' not in data or 'price' not in data:
        return jsonify({'error': 'Thiếu thông tin bắt buộc (name, price)'}), 400

    new_room = Room(
        name=data['name'], 
        price=data['price'], 
        status=data.get('status', 'available'),
        area=data.get('area'),
        floor=data.get('floor', 'Tầng 1'),
        furniture=data.get('furniture'),
        description=data.get('description'),
    )
    db.session.add(new_room)
    db.session.commit()
    return jsonify(new_room.to_dict()), 201

@room_bp.route('/<int:room_id>', methods=['PUT'])
def update_room(room_id):
    room = Room.query.get(room_id)
    if not room:
        return jsonify({'error': 'Không tìm thấy phòng'}), 404

    data = request.json
    print("👉 DỮ LIỆU FLUTTER GỬI LÊN:", data) # In ra màn hình để bắt tại trận

    # 1. Cập nhật thông tin cơ bản
    basic_keys = ['name', 'price', 'status', 'area', 'floor', 'furniture', 'description']
    for key in basic_keys:
        if key in data:
            setattr(room, key, data[key])

    # 2. CẬP NHẬT THÔNG TIN KHÁCH (Bao bọc cả camelCase lẫn snake_case)
    if 'tenantName' in data: room.tenantName = data['tenantName']
    elif 'tenant_name' in data: room.tenantName = data['tenant_name']

    if 'tenantPhone' in data: room.tenantPhone = data['tenantPhone']
    elif 'tenant_phone' in data: room.tenantPhone = data['tenant_phone']

    if 'tenantCCCD' in data: room.tenantCCCD = data['tenantCCCD']
    elif 'tenant_cccd' in data: room.tenantCCCD = data['tenant_cccd']

    if 'tenantAddress' in data: room.tenantAddress = data['tenantAddress']
    elif 'tenant_address' in data: room.tenantAddress = data['tenant_address']

    if 'contractDeposit' in data: room.contractDeposit = data['contractDeposit']
    elif 'contract_deposit' in data: room.contractDeposit = data['contract_deposit']

    if 'contractStartDate' in data: room.contractStartDate = data['contractStartDate']
    elif 'contract_start_date' in data: room.contractStartDate = data['contract_start_date']

    if 'contractEndDate' in data: room.contractEndDate = data['contractEndDate']
    elif 'contract_end_date' in data: room.contractEndDate = data['contract_end_date']

    try:
        db.session.commit()
        return jsonify(room.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        print("LỖI DATABASE:", str(e))
        return jsonify({'error': 'Lỗi lưu Database'}), 500

@room_bp.route('/<int:room_id>', methods=['DELETE'])
def delete_room(room_id):
    room = Room.query.get(room_id)
    if not room:
        return jsonify({'error': 'Không tìm thấy phòng'}), 404

    db.session.delete(room)
    db.session.commit()
    return jsonify({'message': 'Đã xóa phòng'}), 200