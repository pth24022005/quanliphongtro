import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/billing_repository.dart';
import '../data/room_repository.dart'; // 👉 Đã import để sử dụng roomListStreamProvider

// Provider quản lý logic chi tiết phòng
final roomDetailControllerProvider = Provider<RoomDetailController>((ref) {
  return RoomDetailController(ref); // 👉 Đã truyền ref vào đây
});

final latestInvoiceFutureProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, roomId) async {
  return await ref
      .read(billingRepositoryProvider)
      .getLatestInvoiceByRoom(roomId);
});

class RoomDetailController {
  final Ref ref; // 👉 Khai báo biến ref để sử dụng trong toàn class

  RoomDetailController(this.ref); // 👉 Đón nhận ref từ Provider truyền vào

  static const String billingUrl = 'http://localhost:5003/api/v1/billing';
  static const String roomUrl = 'http://localhost:5002/api/v1/rooms';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>?> getLatestInvoice(String roomId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$billingUrl/invoices/room/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty ? data.first as Map<String, dynamic> : null;
      }
      return null;
    } catch (e) {
      // Đã gỡ bỏ lệnh print để tránh cảnh báo (avoid_print) của Flutter
      return null;
    }
  }

  Future<String?> checkoutRoom(String roomId) async {
    try {
      final token = await _getToken();
      if (token == null) return 'Lỗi xác thực. Vui lòng đăng nhập lại.';

      // Bộ dữ liệu trả phòng: Đưa mọi thứ về Rỗng / 0
      final clearData = {
        'status': 'available',
        'tenantName': '',
        'tenantPhone': '',
        'tenantCCCD': '',
        'tenantAddress': '',
        'contractDeposit': 0,
        'contractStartDate': null,
        'contractEndDate': null,
      };

      final response = await http.put(
        Uri.parse('$roomUrl/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(clearData),
      );

      if (response.statusCode == 200) {
        // 👉 Xóa dữ liệu cũ, tải lại danh sách phòng ngay lập tức khi trả phòng
        ref.invalidate(roomListStreamProvider);
        return null; // Thành công
      } else {
        return 'Lỗi server (${response.statusCode})';
      }
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }
}
