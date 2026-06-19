import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/room_repository.dart';

final createContractControllerProvider =
    Provider<CreateContractController>((ref) {
  return CreateContractController(ref);
});

class CreateContractController {
  final Ref ref;

  CreateContractController(this.ref);

  Future<String?> submitContract({
    required String roomId,
    required bool isRenewing,
    required String name,
    required String phone,
    required String cccd,
    required String address,
    required String depositText,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    double deposit = 0;
    if (depositText.isNotEmpty) {
      final rawDeposit = depositText.replaceAll(RegExp(r'[., ]'), '');
      deposit = double.tryParse(rawDeposit) ?? 0;
    }

    try {
      // ====================================================================
      // BƯỚC 1: TẠO TÀI KHOẢN KHÁCH THUÊ TRƯỚC (Bắt lỗi siêu chuẩn)
      // ====================================================================
      const authUrl = 'http://localhost:8001/api/v1/auth/register';
      final authResponse = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': '66668888',
          'full_name': name,
          'role': 'tenant'
        }),
      );

      // 👉 Nếu Backend từ chối, quét sạch mọi loại thông báo để hiển thị
      if (authResponse.statusCode != 201 && authResponse.statusCode != 200) {
        String errorMessage = authResponse.body; // Lấy nguyên gốc báo lỗi
        try {
          final errorData = jsonDecode(authResponse.body);
          // Cố gắng moi móc thông tin từ các cấu trúc JSON khác nhau
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? authResponse.body;
        } catch (_) {
          // Nếu Backend sập và trả về HTML, nó sẽ nhảy vào đây
        }
        return 'Tạo tk thất bại (Mã ${authResponse.statusCode}): $errorMessage';
      }

      // ====================================================================
      // BƯỚC 2: TÀI KHOẢN TẠO THÀNH CÔNG -> LƯU HỢP ĐỒNG VÀO PHÒNG
      // ====================================================================
      final updateData = {
        'status': 'rented',
        'tenantName': name,
        'tenantPhone': phone,
        'tenantCCCD': cccd,
        'tenantAddress': address,
        'contractDeposit': deposit,
        'contractStartDate': startDate.toIso8601String(),
        'contractEndDate': endDate.toIso8601String(),
      };

      await ref.read(roomRepositoryProvider).updateRoom(roomId, updateData);

      ref.invalidate(roomListStreamProvider);

      return null;
    } catch (e) {
      return 'Lỗi kết nối hệ thống: ${e.toString()}';
    }
  }
}
