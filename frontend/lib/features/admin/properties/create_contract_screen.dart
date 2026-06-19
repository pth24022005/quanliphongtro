import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'models/room_model.dart';
import 'controllers/create_contract_controller.dart';

class CreateContractScreen extends HookConsumerWidget {
  final RoomModel room;

  const CreateContractScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tự quản lý trạng thái loading trên UI
    final isLoading = useState<bool>(false);

    // --- BỘ ĐIỀU KHIỂN TEXTFIELD ---
    final tenantNameController =
        useTextEditingController(text: room.tenantName);
    final tenantPhoneController =
        useTextEditingController(text: room.tenantPhone);
    final cccdController = useTextEditingController(text: room.tenantCCCD);
    final addressController =
        useTextEditingController(text: room.tenantAddress);
    final depositController = useTextEditingController(
      text: room.contractDeposit != null
          ? room.contractDeposit!.toInt().toString()
          : '',
    );

    // --- BỘ ĐIỀU KHIỂN NGÀY THÁNG ---
    final startDate =
        useState<DateTime>(room.contractEndDate ?? DateTime.now());
    final endDate = useState<DateTime>(
      (room.contractEndDate ?? DateTime.now()).add(const Duration(days: 180)),
    );
    final isRenewing = room.status == RoomStatus.rented;

    Future<void> selectDate(
      BuildContext context,
      ValueNotifier<DateTime> dateState, {
      bool isStart = true,
    }) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: dateState.value,
        firstDate: isStart ? DateTime(2020) : startDate.value,
        lastDate: DateTime(2035),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2E7D32),
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != dateState.value) {
        dateState.value = picked;
        if (isStart && picked.isAfter(endDate.value)) {
          endDate.value = picked.add(const Duration(days: 180));
        }
      }
    }

    // --- HÀM KIỂM TRA ĐẦU VÀO VÀ ĐẨY CHO CONTROLLER ---
    Future<void> handleAction() async {
      FocusScope.of(context).unfocus();

      final name = tenantNameController.text.trim();
      final phone = tenantPhoneController.text.trim();

      // Validate UI cơ bản
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng nhập tên khách thuê'),
              backgroundColor: Colors.red),
        );
        return;
      }
      if (phone.isEmpty || phone.length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Số điện thoại không hợp lệ'),
              backgroundColor: Colors.red),
        );
        return;
      }

      isLoading.value = true; // Bật vòng xoay
      // Gọi Controller xử lý
      final errorMessage =
          await ref.read(createContractControllerProvider).submitContract(
                roomId: room.id,
                isRenewing: isRenewing,
                name: name,
                phone: phone,
                cccd: cccdController.text.trim(),
                address: addressController.text.trim(),
                depositText: depositController.text.trim(),
                startDate: startDate.value,
                endDate: endDate.value,
              );
      isLoading.value = false; // Tắt vòng xoay

      // Xử lý kết quả trả về
      if (context.mounted) {
        if (errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRenewing
                  ? 'Gia hạn thành công!'
                  : 'Tạo hợp đồng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Quay về trang chi tiết
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
            isRenewing ? 'Gia hạn - ${room.name}' : 'Hợp đồng - ${room.name}',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HỒ SƠ KHÁCH THUÊ',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _buildModernInput(
                  controller: tenantNameController,
                  label: 'Họ và tên người đại diện',
                  hint: 'Nguyễn Văn A',
                  icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildModernInput(
                  controller: tenantPhoneController,
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
              const SizedBox(height: 32),
              const Text('THÔNG TIN HỢP ĐỒNG MỚI',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _buildPriceInput(depositController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      context: context,
                      label:
                          isRenewing ? 'Bắt đầu (Theo HĐ cũ)' : 'Ngày bắt đầu',
                      date: startDate.value,
                      iconColor:
                          isRenewing ? Colors.grey : Colors.blue.shade600,
                      isLocked: isRenewing,
                      onTap: isRenewing
                          ? null
                          : () => selectDate(context, startDate, isStart: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      context: context,
                      label: 'Ngày kết thúc mới',
                      date: endDate.value,
                      iconColor: const Color(0xFF2E7D32),
                      isLocked: false,
                      onTap: () => selectDate(context, endDate, isStart: false),
                    ),
                  ),
                ],
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
            onPressed: isLoading.value ? null : handleAction,
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
                : Text(
                    isRenewing ? 'XÁC NHẬN GIA HẠN' : 'XÁC NHẬN CHO THUÊ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // WIDGET GIAO DIỆN PHỤ (Giữ nguyên)
  // ========================================================
  Widget _buildModernInput(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      bool isNumber = false,
      int maxLines = 1}) {
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
              child: Icon(icon, color: Colors.grey.shade500, size: 20)),
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
                          fontWeight: FontWeight.normal)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FBF9),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiền cọc giữ chỗ',
              style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('đ',
                  style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey.shade300)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
      {required BuildContext context,
      required String label,
      required DateTime date,
      required Color iconColor,
      required bool isLocked,
      required VoidCallback? onTap}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            color: isLocked ? Colors.grey.shade100 : const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isLocked ? Colors.transparent : Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(dateFormat.format(date),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            isLocked ? Colors.grey.shade500 : Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
