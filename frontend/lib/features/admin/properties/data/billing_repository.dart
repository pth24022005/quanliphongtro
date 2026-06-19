import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👉 Nhập thư viện mở két sắt

// =====================================================================
// PROVIDERS
// =====================================================================

// Provider truyền `ref` vào Repository để dùng token tập trung
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref);
});

// Provider watch danh sách TẤT CẢ hóa đơn
final allInvoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(billingRepositoryProvider).fetchAllInvoices();
});

// =====================================================================
// REPOSITORY CLASS
// =====================================================================
class BillingRepository {
  final Ref ref;
  BillingRepository(this.ref);

  // 👉 ĐÃ SỬA CỔNG: Trỏ thẳng vào cổng 5003 của nhà Billing Service
  static const String baseUrl = 'http://localhost:5003/api/v1/billing';

  // 👉 ĐÃ SỬA CÁCH LẤY TOKEN: Rút thẳng JWT từ két sắt, y hệt RoomRepository
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // =========================================================================
  // BỘ CHUYỂN ĐỔI SIÊU CẤP: Chống lỗi lệch kiểu dữ liệu (String/Int/Double)
  // và chấp nhận cả snake_case & camelCase
  // =========================================================================
  Map<String, dynamic> _normalizeInvoice(Map<String, dynamic> dbData) {
    int parseInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double parseDouble(dynamic v) => v is double
        ? v
        : (v is int
            ? v.toDouble()
            : double.tryParse(v?.toString() ?? '0') ?? 0.0);

    return {
      'id': dbData['id']?.toString() ?? '',
      'roomId':
          dbData['room_id']?.toString() ?? dbData['roomId']?.toString() ?? '',
      'roomName': dbData['room_name'] ?? dbData['roomName'] ?? 'Phòng',
      'tenantName': dbData['tenant_name'] ?? dbData['tenantName'] ?? 'Khách',
      'month': parseInt(dbData['month']),
      'year': parseInt(dbData['year']),
      'rentCost': parseDouble(dbData['rent_cost'] ?? dbData['rentCost']),
      'electricityUsage':
          parseInt(dbData['electricity_usage'] ?? dbData['electricityUsage']),
      'electricityCost':
          parseDouble(dbData['electricity_cost'] ?? dbData['electricityCost']),
      'waterUsage': parseInt(dbData['water_usage'] ?? dbData['waterUsage']),
      'waterCost': parseDouble(dbData['water_cost'] ?? dbData['waterCost']),
      'internetCost':
          parseDouble(dbData['internet_cost'] ?? dbData['internetCost']),
      'serviceCost':
          parseDouble(dbData['service_cost'] ?? dbData['serviceCost']),
      'totalAmount':
          parseDouble(dbData['total_amount'] ?? dbData['totalAmount']),
      'status': dbData['status'] ?? 'unpaid',
    };
  }

  // =========================================================================
  // CÁC HÀM TƯƠNG TÁC VỚI API
  // =========================================================================

  // 1. Lấy TẤT CẢ hóa đơn (Dùng cho màn hình Quản lý hóa đơn)
  Future<List<Map<String, dynamic>>> fetchAllInvoices() async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực: Không tìm thấy Token');

    final response = await http.get(
      Uri.parse('$baseUrl/invoices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => _normalizeInvoice(e as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  }

  // 2. Lấy hóa đơn mới nhất CỦA MỘT PHÒNG (Dùng cho Màn hình Chi tiết phòng)
  Future<Map<String, dynamic>?> getLatestInvoiceByRoom(String roomId) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/invoices/room/$roomId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        // Sắp xếp giảm dần theo Năm -> Tháng (Mới nhất lên đầu)
        data.sort((a, b) {
          int yearDiff = (b['year'] ?? 0).compareTo(a['year'] ?? 0);
          if (yearDiff != 0) return yearDiff;
          return (b['month'] ?? 0).compareTo(a['month'] ?? 0);
        });

        return _normalizeInvoice(data.first as Map<String, dynamic>);
      }
    }
    return null;
  }

  // 3. LẤY TOÀN BỘ HÓA ĐƠN CỦA MỘT PHÒNG (Dùng cho TenantsController)
  Future<List<Map<String, dynamic>>> getInvoicesByRoom(String roomId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực');

    final response = await http.get(
      Uri.parse('$baseUrl/invoices/room/$roomId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => _normalizeInvoice(e as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  }

  // 4. Cập nhật trạng thái hóa đơn
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực');

    final response = await http.put(
      Uri.parse('$baseUrl/invoices/$invoiceId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) throw Exception('Lỗi cập nhật hóa đơn');
  }

  // 5. TẠO HÓA ĐƠN MỚI TỪ CHỐT ĐIỆN NƯỚC (Dùng cho UtilityReadingController)
  Future<void> createInvoice(Map<String, dynamic> invoiceData) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực');

    final response = await http.post(
      Uri.parse('$baseUrl/invoices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(invoiceData),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể chốt hóa đơn: ${response.body}');
    }
  }
}
