import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provider để cung cấp controller này cho UI sử dụng
final roomControllerProvider = Provider<RoomController>((ref) {
  return RoomController();
});

class RoomController {
  // Địa chỉ API Gateway (dùng localhost vì đang chạy trên Chrome)
  static const String baseUrl = 'http://localhost/api/v1/rooms';

  /// Trả về null nếu thêm thành công, ngược lại trả về chuỗi báo lỗi
  Future<String?> addRoom(Map<String, dynamic> roomData) async {
    try {
      // 1. Lấy Token xịn từ Firebase để qua cửa Nginx & Gateway
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.';
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 2. CHECK TRÙNG LẶP: Gọi GET để lấy danh sách kiểm tra (Giống logic cũ của bạn)
      final getResponse = await http.get(Uri.parse(baseUrl), headers: headers);
      if (getResponse.statusCode == 200) {
        final List<dynamic> existingRooms = jsonDecode(getResponse.body);
        final bool isDuplicate = existingRooms.any((r) => r['name'] == roomData['name']);
        
        if (isDuplicate) {
          return 'Phòng "${roomData['name']}" đã tồn tại trên hệ thống!';
        }
      }

      // 3. TIẾN HÀNH LƯU DỮ LIỆU: Gọi POST xuống Room Service
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(roomData),
      );

      // Trạng thái 201 Created từ backend trả về nghĩa là lưu DB thành công
      if (response.statusCode == 201) {
        return null; 
      } else {
        return 'Lỗi Server (${response.statusCode}): Không thể lưu dữ liệu.';
      }
    } catch (e) {
      return 'Lỗi kết nối tới máy chủ Backend: $e';
    }
  }
}