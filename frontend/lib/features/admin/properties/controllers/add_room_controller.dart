import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/room_repository.dart'; // Import Repository đã có sẵn vé Token

// Provider cung cấp Controller
final addRoomControllerProvider = Provider<AddRoomController>((ref) {
  return AddRoomController(ref);
});

class AddRoomController {
  final Ref ref;
  AddRoomController(this.ref);

  // Trả về null nếu thành công, trả về lỗi nếu thất bại
  Future<String?> addRoom(Map<String, dynamic> roomData) async {
    try {
      final repo = ref.read(roomRepositoryProvider);
      
      // Gọi hàm createRoom (POST) mà chúng ta vừa thêm vào Repository
      await repo.createRoom(roomData); 

      // 👉 BẮT BUỘC CÓ: Xóa cache, bắt giao diện tải lại danh sách phòng mới nhất!
      ref.invalidate(roomListStreamProvider);

      return null; // Thành công
    } catch (e) {
      return e.toString(); // Trả về thông báo lỗi ("Phiên đăng nhập hết hạn...")
    }
  }
}