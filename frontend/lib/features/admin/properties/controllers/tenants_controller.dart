import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../properties/data/billing_repository.dart';
import 'package:flutter/foundation.dart';

final tenantDebtProvider =
    FutureProvider.family<double, String>((ref, roomId) async {
  final billingRepo = ref.read(billingRepositoryProvider);
  try {
    // Kéo toàn bộ hóa đơn chưa thanh toán của phòng này từ Postgres
    final unpaidInvoices = await billingRepo.getInvoicesByRoom(roomId);

    double totalDebt = 0;
    for (var invoice in unpaidInvoices) {
      totalDebt += (invoice['total_amount'] ?? 0.0) as num;
    }
    return totalDebt;
  } catch (e) {
    debugPrint('Lỗi tính nợ phòng $roomId: $e');
    return 0.0;
  }
});
