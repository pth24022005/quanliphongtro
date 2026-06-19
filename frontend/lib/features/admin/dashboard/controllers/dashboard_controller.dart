import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../properties/data/billing_repository.dart';

// =====================================================================
// 1. PROVIDER: LẤY DANH SÁCH HÓA ĐƠN THÁNG HIỆN TẠI (Dùng cho phần Cuối trang)
// =====================================================================
final currentMonthInvoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final allInvoices = await ref.watch(allInvoicesProvider.future);
  final now = DateTime.now();

  return allInvoices
      .where((inv) => inv['month'] == now.month && inv['year'] == now.year)
      .toList();
});

// =====================================================================
// 2. PROVIDER: TÍNH TOÁN DOANH THU (Dùng cho Thẻ tài chính Đầu trang)
// =====================================================================
class FinancialStats {
  final double totalExpected;
  final double totalCollected;
  final double totalPending;

  FinancialStats(
      {required this.totalExpected,
      required this.totalCollected,
      required this.totalPending});
}

final financialStatsProvider = FutureProvider<FinancialStats>((ref) async {
  // Lấy luôn danh sách hóa đơn từ provider số 1 ở trên
  final currentInvoices = await ref.watch(currentMonthInvoicesProvider.future);

  double totalExpected = 0;
  double totalCollected = 0;
  double totalPending = 0;

  for (var inv in currentInvoices) {
    final amount = (inv['totalAmount'] ?? 0) as double;
    totalExpected += amount;
    if (inv['status'] == 'paid') {
      totalCollected += amount;
    } else {
      totalPending += amount;
    }
  }
  return FinancialStats(
      totalExpected: totalExpected,
      totalCollected: totalCollected,
      totalPending: totalPending);
});
