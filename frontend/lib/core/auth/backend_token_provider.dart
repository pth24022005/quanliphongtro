import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider này sẽ lục trong bộ nhớ máy xem có Token không
final backendTokenProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null || token.isEmpty) {
    throw Exception(
        'Không tìm thấy Token'); // Ép văng lỗi nếu chưa đăng nhập thật sự
  }

  return token;
});
