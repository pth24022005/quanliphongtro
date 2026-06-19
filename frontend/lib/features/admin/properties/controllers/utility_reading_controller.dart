import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/room_model.dart';
import '../data/room_repository.dart';
import '../data/billing_repository.dart';
// 👉 THÊM IMPORT NÀY: Để lấy latestInvoiceFutureProvider
import 'room_detail_controller.dart';

final utilityReadingControllerProvider =
    AsyncNotifierProvider<UtilityReadingController, void>(() {
  return UtilityReadingController();
});

class UtilityReadingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> submitReading({
    required RoomModel room,
    required int newElec,
    required int newWater,
  }) async {
    state = const AsyncValue.loading();

    final roomRepo = ref.read(roomRepositoryProvider);
    final billingRepo = ref.read(billingRepositoryProvider);

    try {
      final elecPrice = room.electricityPrice ?? 3500.0;
      final waterPrice = room.waterPrice ?? 25000.0;
      final internetPrice = room.internetPrice ?? 100000.0;
      final servicePrice = room.servicePrice ?? 50000.0;

      final elecUsage = newElec - (room.electricityIndex ?? 0);
      final waterUsage = newWater - (room.waterIndex ?? 0);

      final elecCost = elecUsage * elecPrice;
      final waterCost = waterUsage * waterPrice;

      final totalBill =
          room.price + elecCost + waterCost + internetPrice + servicePrice;

      // 1. Cập nhật số điện nước mới của phòng xuống Postgres (Room Service)
      await roomRepo.updateRoom(room.id, {
        'electricityIndex': newElec,
        'waterIndex': newWater,
      });

      // 2. Xuất hóa đơn mới xuống Postgres (Billing Service) thay vì Firebase
      final currentMonth = DateTime.now();
      await billingRepo.createInvoice({
        'roomId': room.id,
        'roomName': room.name,
        'tenantName': room.tenantName,
        'month': currentMonth.month,
        'year': currentMonth.year,
        'rentCost': room.price,
        'electricityUsage': elecUsage,
        'electricityCost': elecCost,
        'waterUsage': waterUsage,
        'waterCost': waterCost,
        'internetCost': internetPrice,
        'serviceCost': servicePrice,
        'totalAmount': totalBill,
        'status': 'unpaid',
      });

      // 👉 THÊM 2 DÒNG NÀY: Ép giao diện giấu nút "Chốt điện nước" và hiện hóa đơn mới!
      ref.invalidate(latestInvoiceFutureProvider(room.id));
      ref.invalidate(allInvoicesProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
