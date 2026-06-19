import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../properties/models/room_model.dart';
import 'controllers/edit_tenant_controller.dart'; 

class EditTenantScreen extends HookConsumerWidget {
  final RoomModel room;

  const EditTenantScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- TỰ QUẢN LÝ VÒNG XOAY LOADING CHUẨN XÁC 100% ---
    final isLoading = useState<bool>(false);

    // --- BỘ ĐIỀU KHIỂN DỮ LIỆU ---
    final nameController = useTextEditingController(text: room.tenantName);
    final phoneController = useTextEditingController(text: room.tenantPhone);
    final cccdController = useTextEditingController(text: room.tenantCCCD);
    final addressController =
        useTextEditingController(text: room.tenantAddress);

    // --- HÀM XỬ LÝ NÚT BẤM (Đã tích hợp xử lý thành công/thất bại) ---
    Future<void> onSubmit() async {
      FocusScope.of(context).unfocus();
      final name = nameController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tên không được để trống'),
              backgroundColor: Colors.red),
        );
        return;
      }

      isLoading.value = true; // Bật vòng xoay

      // Đợi Controller làm việc và nhận kết quả trả về
      final errorMessage = await ref.read(editTenantControllerProvider).updateTenantInfo(
            roomId: room.id,
            name: name,
            phone: phoneController.text.trim(),
            cccd: cccdController.text.trim(),
            address: addressController.text.trim(),
          );

      isLoading.value = false; // Tắt vòng xoay

      // Xử lý thông báo sau khi có kết quả
      if (context.mounted) {
        if (errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cập nhật khách thuê thành công!'),
                backgroundColor: Colors.green),
          );
          context.pop(); // Đóng màn hình
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $errorMessage'),
                backgroundColor: Colors.red),
          );
        }
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          centerTitle: false,
          title: Text(
            'Sửa khách - ${room.name}',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Colors.black87,
                letterSpacing: -0.5),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HỒ SƠ KHÁCH THUÊ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              _buildModernInput(
                  controller: nameController,
                  label: 'Họ và tên người đại diện',
                  hint: 'Nguyễn Văn A',
                  icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildModernInput(
                  controller: phoneController,
                  label: 'Số điện thoại',
                  hint: '0912345678',
                  icon: Icons.phone_outlined,
                  isNumber: true),
              const SizedBox(height: 16),
              _buildModernInput(
                  controller: cccdController,
                  label: 'Số CCCD/CMND',
                  hint: '0012010...',
                  icon: Icons.badge_outlined,
                  isNumber: true),
              const SizedBox(height: 16),
              _buildModernInput(
                  controller: addressController,
                  label: 'Địa chỉ thường trú',
                  hint: 'Nhập địa chỉ...',
                  icon: Icons.location_on_outlined,
                  maxLines: 2),
              const SizedBox(height: 100),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          color: Colors.white,
          child: ElevatedButton(
            // Khóa nút nếu đang tải
            onPressed: isLoading.value ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C1E),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('LƯU THÔNG TIN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 4.0 : 0),
            child: Icon(icon, color: Colors.grey.shade500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                TextField(
                  controller: controller,
                  keyboardType:
                      isNumber ? TextInputType.number : TextInputType.text,
                  maxLines: maxLines,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4),
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}