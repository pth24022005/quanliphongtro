import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room_model.dart';

// Cung cấp Repository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

// Provider lấy danh sách phòng
final roomListStreamProvider = FutureProvider<List<RoomModel>>((ref) async {
  final repo = ref.read(roomRepositoryProvider);
  return await repo.getRooms();
});

class RoomRepository {
  static const String baseUrl = 'http://localhost:5002/api/v1/rooms';

  // ==========================================
  // HÀM LẤY TOKEN MỚI TỪ KÉT SẮT
  // ==========================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 1. GET: LẤY DANH SÁCH PHÒNG
  Future<List<RoomModel>> getRooms() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Lỗi xác thực: Không tìm thấy Token trong hệ thống');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> dataList = jsonDecode(response.body);

      return dataList.map((data) {
        RoomStatus parsedStatus = RoomStatus.available;
        if (data['status'] == 'rented') parsedStatus = RoomStatus.rented;
        if (data['status'] == 'maintenance') {
          parsedStatus = RoomStatus.maintenance;
        }

        return RoomModel(
          id: data['id']?.toString() ?? '',
          name: data['name']?.toString() ?? 'Phòng trống',
          status: parsedStatus,
          price: double.tryParse(data['price']?.toString() ?? '') ?? 0.0,
          area: double.tryParse(data['area']?.toString() ?? ''),
          furniture: data['furniture']?.toString(),
          description: data['description']?.toString(),
          tenantName: data['tenantName']?.toString(),
          tenantPhone: data['tenantPhone']?.toString(),
          tenantCCCD: data['tenantCCCD']?.toString(),
          tenantAddress: data['tenantAddress']?.toString(),
          contractDeposit:
              double.tryParse(data['contractDeposit']?.toString() ?? ''),
          contractStartDate: data['contractStartDate'] != null
              ? DateTime.tryParse(data['contractStartDate'].toString())
              : null,
          contractEndDate: data['contractEndDate'] != null
              ? DateTime.tryParse(data['contractEndDate'].toString())
              : null,
          electricityIndex:
              int.tryParse(data['electricityIndex']?.toString() ?? ''),
          waterIndex: int.tryParse(data['waterIndex']?.toString() ?? ''),
          electricityPrice:
              double.tryParse(data['electricityPrice']?.toString() ?? ''),
          waterPrice: double.tryParse(data['waterPrice']?.toString() ?? ''),
          internetPrice:
              double.tryParse(data['internetPrice']?.toString() ?? ''),
          servicePrice: double.tryParse(data['servicePrice']?.toString() ?? ''),
        );
      }).toList();
    } else {
      throw Exception(
          'Không thể tải danh sách phòng (Mã lỗi: ${response.statusCode})');
    }
  }

  // 2. DELETE: XÓA PHÒNG
  Future<void> deleteRoom(String roomId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$roomId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Không thể xóa phòng (Lỗi Server: ${response.statusCode})');
    }
  }

  // 3. PUT: CẬP NHẬT PHÒNG
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$roomId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Không thể cập nhật phòng (Lỗi Server: ${response.statusCode})');
    }
  }

  // ==============================================================
  // 👉 4. POST: THÊM PHÒNG MỚI (CHÍNH LÀ PHẦN BỊ THIẾU GÂY RA LỖI)
  // ==============================================================
  Future<void> createRoom(Map<String, dynamic> data) async {
    final token = await _getToken();

    // Kiểm tra vé vào cửa
    if (token == null || token.isEmpty) {
      throw Exception('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer $token', // 👉 Gắn Token vào đây để qua cửa bảo vệ
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Không thể tạo phòng mới (Lỗi Server: ${response.statusCode} - ${response.body})');
    }
  }
}
