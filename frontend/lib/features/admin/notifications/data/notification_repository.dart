import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 👉 NHỚ IMPORT FILE NÀY: Thay đổi đường dẫn cho đúng với project của bạn
import '../../../../core/auth/backend_token_provider.dart';

// =====================================================================
// PROVIDERS
// =====================================================================

// Provider cung cấp Repository, truyền `ref` vào để lấy token tập trung
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref);
});

// Provider watch danh sách thông báo realtime/future từ Postgres
final notificationListProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return await repo.fetchNotifications();
});

// =====================================================================
// REPOSITORY CLASS
// =====================================================================
class NotificationRepository {
  final Ref ref;
  NotificationRepository(this.ref);

  // Gọi qua cổng 80 của Nginx, Nginx sẽ tự đẩy qua Gateway vào Port 5005
  static const String baseUrl = 'http://localhost/api/v1/notifications';

  // 👉 ĐÃ THAY MÁU: Lấy token tập trung từ bộ nhớ tạm, tuyệt đối KHÔNG GỌI API POST nữa
  Future<String?> _getToken() async {
    return await ref.read(backendTokenProvider.future);
  }

  // =======================================================
  // Lấy danh sách thông báo
  // =======================================================
  Future<List<dynamic>> fetchNotifications() async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tải thông báo');
    }
  }

  // =======================================================
  // Gọi API cập nhật trạng thái đã đọc lên Postgres
  // =======================================================
  Future<void> markAsRead(String notifId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực');

    final response = await http.put(
      Uri.parse('$baseUrl/$notifId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể cập nhật trạng thái đọc thông báo');
    }
  }
}
