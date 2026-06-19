import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../admin/properties/models/room_model.dart';
import '../../../admin/properties/data/room_repository.dart';

// =====================================================================
// 1. PROVIDER LẤY PHÒNG (ĐÃ SỬA: TỰ BẺ KHÓA TOKEN ĐỂ LẤY SĐT)
// =====================================================================
final currentTenantRoomProvider = FutureProvider<RoomModel?>((ref) async {
  try {
    // 👉 1. Tự mở két sắt lấy Token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) return null;

    // 👉 2. Tự giải mã JWT để lấy chắc chắn 100% số điện thoại
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    final decodedData = jsonDecode(resp);

    final String phone = decodedData['phone'] ?? '';

    print('=== ĐANG TÌM PHÒNG CHO KHÁCH: $phone ===');

    if (phone.isEmpty) return null;

    // 👉 3. Lấy danh sách phòng và lọc
    final rooms = await ref.read(roomRepositoryProvider).getRooms();

    // Dùng try-catch bọc hàm firstWhere để nếu không thấy thì không bị văng app
    final myRoom = rooms.firstWhere(
      (room) => room.tenantPhone == phone && room.status == RoomStatus.rented,
    );

    print('🎉 Đã tìm thấy phòng: ${myRoom.name}');
    return myRoom;
  } catch (e) {
    print('❌ Khách này chưa có phòng hoặc lỗi tìm kiếm: $e');
    return null;
  }
});

// =====================================================================
// 2. PROVIDER LẤY HÓA ĐƠN MỚI NHẤT
// =====================================================================
final tenantLatestInvoiceProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, roomId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = 'http://localhost:8001/api/v1/billing/invoices/room/$roomId';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        if (decoded.isNotEmpty) {
          return decoded.first as Map<String, dynamic>;
        }
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('error')) return null;
        return decoded;
      }
    }
    return null;
  } catch (e) {
    print('❌ Lỗi tải hóa đơn: $e');
    return null;
  }
});
