import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum AuthState {
  loading, // 👉 THÊM MỚI: Trạng thái chờ mở két lấy Token
  unauthenticated, // Chưa đăng nhập
  admin, // Chủ trọ/Quản lý
  tenant, // Khách thuê
}

class AuthController extends Notifier<AuthState> {
  String? currentTenantPhone;

  @override
  AuthState build() {
    // 👉 KÍCH HOẠT: Tự động chạy hàm mở két sắt ngay khi vừa bật app/F5
    _checkSavedToken();

    // Báo cho Router biết: "Từ từ, tao đang mở két, khoan hãy đuổi!"
    return AuthState.loading;
  }

  // ====================================================================
  // 👉 HÀM MỚI: TỰ ĐỘNG ĐỌC KÉT SẮT KIỂM TRA TOKEN KHI F5
  // ====================================================================
  Future<void> _checkSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken != null && accessToken.isNotEmpty) {
        // Có vé -> Giải mã xem là Admin hay Tenant
        final decodedToken = _decodeJwt(accessToken);
        final String role = decodedToken['role'] ?? 'tenant';
        currentTenantPhone = decodedToken['phone'];

        // Cập nhật State để Router mở cửa cho vào
        if (role == 'admin') {
          state = AuthState.admin;
        } else {
          state = AuthState.tenant;
        }
      } else {
        // Không có vé (Hoặc vé rỗng)
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      // Nếu giải mã lỗi (token hỏng/hết hạn) -> Đuổi ra Login
      state = AuthState.unauthenticated;
    }
  }

  // ====================================================================
  // HÀM PHỤ: Giải mã JWT Token (GIỮ NGUYÊN)
  // ====================================================================
  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token không đúng chuẩn JWT');
    }
    final payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(resp);
  }

  // ====================================================================
  // HÀM ĐĂNG NHẬP CHUẨN POSTGRESQL + JWT (GIỮ NGUYÊN)
  // ====================================================================
  Future<bool> login(String phone, String password) async {
    try {
      const String apiUrl = 'http://localhost:8001/api/v1/auth/login';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String accessToken = responseData['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);

        final decodedToken = _decodeJwt(accessToken);
        final String role = decodedToken['role'] ?? 'tenant';
        final String tokenPhone = decodedToken['phone'] ?? phone;

        currentTenantPhone = tokenPhone;

        if (role == 'admin') {
          state = AuthState.admin;
        } else {
          state = AuthState.tenant;
        }

        return true;
      } else {
        print('Lỗi đăng nhập từ Server: ${response.body}');
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối Backend: $e");
      return false;
    }
  }

  // ====================================================================
  // HÀM ĐĂNG XUẤT (GIỮ NGUYÊN)
  // ====================================================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    currentTenantPhone = null;
    state = AuthState.unauthenticated;
  }
}

// ====================================================================
// PROVIDERS KHỞI TẠO VÀ LẮNG NGHE (GIỮ NGUYÊN)
// ====================================================================
final authProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

final currentUserPhoneProvider = Provider<String>((ref) {
  return ref.read(authProvider.notifier).currentTenantPhone ?? '';
});
