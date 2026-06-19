import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

// ĐÃ SỬA ĐƯỜNG DẪN IMPORT CHO ĐÚNG THƯ MỤC
import '../properties/models/room_model.dart';
import '../properties/data/room_repository.dart';
import 'controllers/utility_reading_controller.dart'; // 👉 Sửa lại đường dẫn import controller nếu cần

class UtilityReadingScreen extends HookConsumerWidget {
  final RoomModel room;

  const UtilityReadingScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldElectricity = room.electricityIndex ?? 0;
    final oldWater = room.waterIndex ?? 0;

    final newElecController = useTextEditingController();
    final newWaterController = useTextEditingController();

    final controllerState = ref.watch(utilityReadingControllerProvider);

    // 👉 ĐÃ XÓA KHỐI ref.listen Ở ĐÂY VÌ NÓ GÂY RA HIỆN TƯỢNG BÁO FAKE SUCCESS

    Future<void> onSubmit() async {
      FocusScope.of(context).unfocus();
      final newElecStr = newElecController.text.trim();
      final newWaterStr = newWaterController.text.trim();

      if (newElecStr.isEmpty || newWaterStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vui lòng nhập đầy đủ chỉ số!'),
            backgroundColor: Colors.red));
        return;
      }

      final newElec = int.tryParse(newElecStr);
      final newWater = int.tryParse(newWaterStr);

      if (newElec == null || newWater == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chỉ số phải là số hợp lệ!'),
            backgroundColor: Colors.red));
        return;
      }

      if (newElec < oldElectricity || newWater < oldWater) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Số mới KHÔNG ĐƯỢC nhỏ hơn số cũ!'),
            backgroundColor: Colors.orange.shade700));
        return;
      }

      // 👉 THUỐC ĐẶC TRỊ BẮT LỖI: Bọc try-catch trực tiếp ở đây
      try {
        await ref.read(utilityReadingControllerProvider.notifier).submitReading(
              room: room,
              newElec: newElec,
              newWater: newWater,
            );

        // NẾU CHẠY ĐẾN ĐƯỢC ĐÂY MÀ KHÔNG BỊ LỖI NÉM RA THÌ MỚI LÀ THÀNH CÔNG THẬT!
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Chốt số thành công!'),
                backgroundColor: Colors.green),
          );
          ref.invalidate(roomListStreamProvider); // Load lại danh sách phòng
          context.pop(); // Đóng màn hình
        }
      } catch (e) {
        // CÓ LỖI TỪ POSTGRES HAY BACKEND NÉM RA SẼ BAY VÀO ĐÂY LẬP TỨC!
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'), // In thẳng mặt cái lỗi đỏ ra
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5), // Hiện 5 giây để kịp đọc
            ),
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
          title: Text(
            'Chốt số - ${room.name}',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Colors.black87),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NHẬP CHỈ SỐ THÁNG NÀY',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              _buildModernReadingCard(
                title: 'Điện năng tiêu thụ (kWh)',
                icon: Icons.bolt,
                iconColor: Colors.orange.shade500,
                iconBg: Colors.orange.shade50,
                oldValue: oldElectricity,
                newController: newElecController,
              ),
              const SizedBox(height: 24),
              _buildModernReadingCard(
                title: 'Nước sinh hoạt (m³)',
                icon: Icons.water_drop,
                iconColor: Colors.blue.shade500,
                iconBg: Colors.blue.shade50,
                oldValue: oldWater,
                newController: newWaterController,
              ),
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
            onPressed: controllerState.isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C1E),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: controllerState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('XUẤT HÓA ĐƠN THÁNG NÀY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildModernReadingCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required int oldValue,
    required TextEditingController newController,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Số tháng trước',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(oldValue.toString(),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: Colors.grey, size: 20),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chỉ số mới',
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: TextField(
                        controller: newController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.blue),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          border: InputBorder.none,
                          hintText: 'Nhập...',
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
