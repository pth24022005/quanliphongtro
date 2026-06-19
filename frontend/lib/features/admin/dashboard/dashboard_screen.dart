import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../properties/models/room_model.dart';
import '../properties/data/room_repository.dart';
import '../properties/data/billing_repository.dart';
import 'controllers/dashboard_controller.dart';

// =====================================================================
// WIDGET THẺ THỐNG KÊ MINI (STAT CARD)
// =====================================================================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// GIAO DIỆN CHÍNH DASHBOARD SCREEN
// =====================================================================
class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kéo 3 luồng dữ liệu riêng biệt
    final roomsAsync = ref.watch(roomListStreamProvider);
    final statsAsync = ref.watch(financialStatsProvider); // Dùng cho Đầu trang
    final invoicesAsync =
        ref.watch(currentMonthInvoicesProvider); // Dùng cho Cuối trang

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work,
                  color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xin chào, Quản lý!',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                Text('Khu trọ Hoa Mai',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.black87),
            onPressed: () => context.push('/admin/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: ClipOval(
              child: Image.network(
                'https://i.pravatar.cc/150?img=11',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomListStreamProvider);
          ref.invalidate(allInvoicesProvider);
          ref.invalidate(currentMonthInvoicesProvider);
          ref.invalidate(financialStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KHU VỰC 1: BỨC TRANH TÀI CHÍNH THÁNG NÀY ---
              _buildFinancialCard(statsAsync, currencyFormat),
              const SizedBox(height: 32),

              // --- KHU VỰC 2: PHÍM TẮT HÀNH ĐỘNG ---
              _buildSectionTitle('HÀNH ĐỘNG NHANH'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(
                        context,
                        Icons.add_home_work_outlined,
                        'Thêm phòng',
                        Colors.blue,
                        () => context.push('/admin/properties/add')),
                    _buildQuickAction(
                        context,
                        Icons.electric_meter_outlined,
                        'Chốt số',
                        Colors.orange,
                        () => context.push('/admin/properties')),
                    _buildQuickAction(
                        context,
                        Icons.description_outlined,
                        'Thông báo',
                        Colors.purple,
                        () => context.push('/admin/notifications')),
                    _buildQuickAction(
                        context,
                        Icons.group_outlined,
                        'Khách thuê',
                        const Color(0xFF2E7D32),
                        () => context.push('/admin/tenants')),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- KHU VỰC 3: HIỆN TRẠNG PHÒNG TRỌ ---
              _buildSectionTitle('HIỆN TRẠNG KHU TRỌ'),
              const SizedBox(height: 16),
              _buildRoomStatsGrid(roomsAsync),
              const SizedBox(height: 32),

              // --- KHU VỰC 4: SỰ KIỆN CẦN CHÚ Ý ---
              _buildSectionTitle('SỰ KIỆN CẦN CHÚ Ý'),
              const SizedBox(height: 16),
              _buildLiveFeed(roomsAsync, invoicesAsync, currencyFormat),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 1.2));
  }

  // 👉 ĐẦU TRANG: Lấy dữ liệu từ statsAsync
  Widget _buildFinancialCard(
      AsyncValue<FinancialStats> statsAsync, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: statsAsync.when(
        loading: () => const SizedBox(
            height: 120,
            child:
                Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (e, _) => SizedBox(
            height: 120,
            child: Center(
                child: Text('Lỗi tải tài chính: $e',
                    style: const TextStyle(color: Colors.white)))),
        data: (stats) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DOANH THU DỰ KIẾN THÁNG NÀY',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('T${DateTime.now().month}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(format.format(stats.totalExpected),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatDetail(
                      'ĐÃ THU',
                      format.format(stats.totalCollected),
                      const Color(0xFF6EE7B7)),
                  Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withValues(alpha: 0.2)),
                  _buildStatDetail(
                      'CHƯA THU',
                      format.format(stats.totalPending),
                      const Color(0xFFFCD34D)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatDetail(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildRoomStatsGrid(AsyncValue<List<RoomModel>> roomsAsync) {
    return roomsAsync.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Lỗi tải hiện trạng: $e'),
      data: (rooms) {
        final total = rooms.length;
        final available =
            rooms.where((r) => r.status == RoomStatus.available).length;
        final rented = rooms.where((r) => r.status == RoomStatus.rented).length;
        final maintenance =
            rooms.where((r) => r.status == RoomStatus.maintenance).length;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
                title: 'Tổng phòng',
                value: '$total',
                icon: Icons.meeting_room,
                color: Colors.blue),
            StatCard(
                title: 'Đang thuê',
                value: '$rented',
                icon: Icons.how_to_reg,
                color: const Color(0xFF2E7D32)),
            StatCard(
                title: 'Phòng trống',
                value: '$available',
                icon: Icons.door_front_door,
                color: Colors.orange),
            StatCard(
                title: 'Bảo trì',
                value: '$maintenance',
                icon: Icons.build_circle_outlined,
                color: Colors.red),
          ],
        );
      },
    );
  }

  // 👉 CUỐI TRANG: Lấy dữ liệu danh sách hóa đơn từ invoicesAsync
  Widget _buildLiveFeed(
      AsyncValue<List<RoomModel>> roomsAsync,
      AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
      NumberFormat format) {
    final rooms =
        roomsAsync.maybeWhen(data: (data) => data, orElse: () => <RoomModel>[]);
    final invoices = invoicesAsync.maybeWhen(
        data: (data) => data, orElse: () => <Map<String, dynamic>>[]);

    if ((rooms.isEmpty && roomsAsync.isLoading) ||
        (invoices.isEmpty && invoicesAsync.isLoading)) {
      return const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()));
    }

    List<Widget> feedItems = [];

    final brokenRooms = rooms.where((r) => r.status == RoomStatus.maintenance);
    for (var room in brokenRooms) {
      feedItems.add(_buildAlertTile(
          icon: Icons.build_circle_outlined,
          color: Colors.red,
          title: 'Phòng ${room.name} đang cần sửa chữa',
          subtitle: room.description?.isNotEmpty == true
              ? room.description!
              : 'Yêu cầu kiểm tra trang thiết bị'));
    }

    final unpaidInvoices = invoices.where((i) => i['status'] == 'unpaid');
    for (var inv in unpaidInvoices) {
      feedItems.add(_buildAlertTile(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange.shade600,
          title: '${inv['roomName']} chưa thanh toán tiền',
          subtitle: 'Số tiền thu: ${format.format(inv['totalAmount'] ?? 0)}'));
    }

    final paidInvoices = invoices.where((i) => i['status'] == 'paid').take(3);
    for (var inv in paidInvoices) {
      feedItems.add(_buildAlertTile(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2E7D32),
          title: '${inv['roomName']} thanh toán hoàn tất',
          subtitle: 'Đã nhận: ${format.format(inv['totalAmount'] ?? 0)}'));
    }

    if (feedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Mọi thứ đã được xử lý gọn gàng!',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Column(children: feedItems);
  }

  Widget _buildAlertTile(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
