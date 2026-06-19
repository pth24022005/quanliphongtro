import 'package:hooks_riverpod/hooks_riverpod.dart'; // 👉 ĐÃ SỬA: Import chuẩn xác
import '../../properties/models/room_model.dart';
import '../../properties/data/room_repository.dart';
import '../../properties/data/billing_repository.dart';
import '../data/notification_repository.dart';

// =====================================================================
// 1. QUẢN LÝ TRẠNG THÁI HỢP ĐỒNG ĐÃ ĐỌC (Lưu Local)
// =====================================================================
class ReadContractsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markAsRead(String roomId) {
    state = {...state, roomId};
  }

  void markAllAsRead(Set<String> roomIds) {
    state = roomIds;
  }
}

final readContractAlertsProvider =
    NotifierProvider<ReadContractsNotifier, Set<String>>(() {
  return ReadContractsNotifier();
});

// =====================================================================
// 2. TÍNH TOÁN SỐ LƯỢNG CHƯA ĐỌC (Dùng cho chấm đỏ)
// =====================================================================
final unreadNotificationCountProvider = Provider<int>((ref) {
  int count = 0;

  // 1. Đếm thông báo từ PostgreSQL
  final postgresNotifs = ref.watch(notificationListProvider).value ?? [];
  // 👉 ĐÃ SỬA: Ép kiểu rõ ràng để tránh lỗi "num can't be assigned to int"
  final unreadPostgresCount =
      postgresNotifs.where((n) => n is Map && n['is_read'] == false).length;
  count = count + unreadPostgresCount;

  // 2. Đếm cảnh báo hợp đồng
  final List<RoomModel> rooms = ref.watch(roomListStreamProvider).value ?? [];
  final Set<String> readContracts = ref.watch(readContractAlertsProvider);
  final today = DateTime.now();

  for (var room in rooms) {
    if (room.status == RoomStatus.rented && room.contractEndDate != null) {
      final endDate = DateTime(room.contractEndDate!.year,
          room.contractEndDate!.month, room.contractEndDate!.day);
      final currentDate = DateTime(today.year, today.month, today.day);
      final daysLeft = endDate.difference(currentDate).inDays;

      if (daysLeft <= 30 && !readContracts.contains(room.id)) {
        count++;
      }
    }
  }
  return count;
});

// =====================================================================
// 3. CONTROLLER XỬ LÝ HÀNH ĐỘNG (Đánh dấu đọc, Duyệt tiền)
// =====================================================================
final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(ref);
});

class NotificationController {
  final Ref ref;
  NotificationController(this.ref);

  Future<void> markAsRead(String notifId, bool currentStatus) async {
    if (!currentStatus) {
      try {
        await ref.read(notificationRepositoryProvider).markAsRead(notifId);
        ref.invalidate(notificationListProvider);
      } catch (e) {
        // Linter khuyến cáo dùng debugPrint hoặc log thay vì print trong production,
        // nhưng với đồ án thì xài print tạm để dễ debug ở console.
        print('Lỗi API markAsRead: $e');
      }
    }
  }

  Future<void> markAllAsRead(
      List<dynamic> notifs, List<RoomModel> rooms) async {
    try {
      // 1. Cập nhật Postgres
      for (var n in notifs) {
        if (n is Map && n['is_read'] == false) {
          await ref
              .read(notificationRepositoryProvider)
              .markAsRead(n['id'].toString());
        }
      }
      ref.invalidate(notificationListProvider);

      // 2. Cập nhật Hợp đồng Local
      final Set<String> allAlertRoomIds = {};
      final today = DateTime.now();
      for (var room in rooms) {
        if (room.status == RoomStatus.rented && room.contractEndDate != null) {
          final endDate = DateTime(room.contractEndDate!.year,
              room.contractEndDate!.month, room.contractEndDate!.day);
          final currentDate = DateTime(today.year, today.month, today.day);
          if (endDate.difference(currentDate).inDays <= 30) {
            allAlertRoomIds.add(room.id);
          }
        }
      }
      ref
          .read(readContractAlertsProvider.notifier)
          .markAllAsRead(allAlertRoomIds);
    } catch (e) {
      print('Lỗi markAllAsRead: $e');
    }
  }

  Future<void> approvePayment(String notifId, String invoiceId) async {
    try {
      await ref
          .read(billingRepositoryProvider)
          .updateInvoiceStatus(invoiceId, 'paid');
      await markAsRead(notifId, false);
    } catch (e) {
      print('Lỗi API approvePayment: $e');
      rethrow;
    }
  }
}
