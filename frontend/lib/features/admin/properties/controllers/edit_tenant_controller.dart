import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/room_repository.dart'; // Đảm bảo import đúng đường dẫn của bạn

// 👉 Provider cơ bản, không dính líu đến vòng đời phức tạp của AsyncNotifier
final editTenantControllerProvider = Provider<EditTenantController>((ref) {
  return EditTenantController(ref);
});

class EditTenantController {
  final Ref ref;
  EditTenantController(this.ref);

  // 👉 Trả về chuỗi lỗi nếu thất bại, trả về null nếu thành công
  Future<String?> updateTenantInfo({
    required String roomId,
    required String name,
    required String phone,
    required String cccd,
    required String address,
  }) async {
    try {
      final repo = ref.read(roomRepositoryProvider);

      final updateData = {
        'tenantName': name,
        'tenantPhone': phone,
        'tenantCCCD': cccd,
        'tenantAddress': address,
        'tenantUpdatedAt': DateTime.now().toIso8601String(),
      };

      await repo.updateRoom(roomId, updateData);

      // 👉 Báo cho danh sách phòng tải lại dữ liệu mới
      ref.invalidate(roomListStreamProvider);

      return null; // null nghĩa là Thành công không có lỗi
    } catch (e) {
      return e.toString(); // Trả về câu thông báo lỗi
    }
  }
}