import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../properties/models/room_model.dart';
import '../properties/data/room_repository.dart';
import 'data/notification_repository.dart';
import 'controllers/notifications_controller.dart';

class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);
    final notificationsAsync =
        ref.watch(notificationListProvider); // Đọc từ Postgres
    final readContracts = ref.watch(readContractAlertsProvider);
    final controller = ref.read(notificationControllerProvider);

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Text(
          'Thông báo hệ thống',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.black87,
              letterSpacing: -0.5),
        ),
        actions: [
          roomsAsyncValue.maybeWhen(
            data: (rooms) => notificationsAsync.maybeWhen(
              data: (notifs) {
                final unreadCount = ref.watch(unreadNotificationCountProvider);
                if (unreadCount == 0) return const SizedBox.shrink();

                return IconButton(
                  tooltip: 'Đánh dấu đã đọc tất cả',
                  icon: const Icon(Icons.done_all_rounded, color: Colors.blue),
                  onPressed: () async {
                    await controller.markAllAsRead(notifs, rooms);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Đã đánh dấu đọc tất cả!'),
                            backgroundColor: Colors.green),
                      );
                    }
                  },
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: roomsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (rooms) {
          return notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
            data: (postgresNotifs) {
              // ==========================================
              // KHỐI 1: CẢNH BÁO HỢP ĐỒNG (Vẫn giữ UI tạo Card)
              // ==========================================
              final today = DateTime.now();
              List<Widget> contractCards = [];

              for (var room in rooms) {
                if (room.status == RoomStatus.rented &&
                    room.contractEndDate != null) {
                  final endDate = DateTime(room.contractEndDate!.year,
                      room.contractEndDate!.month, room.contractEndDate!.day);
                  final currentDate =
                      DateTime(today.year, today.month, today.day);
                  final daysLeft = endDate.difference(currentDate).inDays;
                  final isRead = readContracts.contains(room.id);

                  if (daysLeft < 0) {
                    contractCards.add(_buildAlertCard(
                      context: context,
                      ref: ref,
                      room: room,
                      isRead: isRead,
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      bgColor: Colors.red.shade50,
                      title: 'Hợp đồng đã quá hạn!',
                      message:
                          'Phòng ${room.name} (${room.tenantName}) đã quá hạn hợp đồng ${daysLeft.abs()} ngày.',
                      dateText:
                          'Hết hạn từ: ${dateFormat.format(room.contractEndDate!)}',
                    ));
                  } else if (daysLeft <= 3) {
                    contractCards.add(_buildAlertCard(
                      context: context,
                      ref: ref,
                      room: room,
                      isRead: isRead,
                      icon: Icons.notification_important_outlined,
                      color: Colors.deepOrange.shade500,
                      bgColor: Colors.deepOrange.shade50,
                      title: daysLeft == 0
                          ? 'Hết hạn HÔM NAY'
                          : 'Còn $daysLeft ngày',
                      message:
                          'Hãy liên hệ khách để gia hạn hoặc làm thủ tục trả phòng.',
                      dateText:
                          'Ngày hết hạn: ${dateFormat.format(room.contractEndDate!)}',
                    ));
                  } else if (daysLeft <= 30) {
                    contractCards.add(_buildAlertCard(
                      context: context,
                      ref: ref,
                      room: room,
                      isRead: isRead,
                      icon: Icons.calendar_month_outlined,
                      color: Colors.blue.shade600,
                      bgColor: Colors.blue.shade50,
                      title: 'Đến hạn nhắc gia hạn',
                      message:
                          'Hợp đồng phòng ${room.name} sẽ hết hạn trong $daysLeft ngày nữa.',
                      dateText:
                          'Ngày hết hạn: ${dateFormat.format(room.contractEndDate!)}',
                    ));
                  }
                }
              }

              // ==========================================
              // KHỐI 2: THÔNG BÁO TỪ POSTGRESQL
              // ==========================================
              List<Widget> userNotifCards = [];
              for (var notif in postgresNotifs) {
                final isRead = notif['is_read'] ?? true;
                final type = notif['type'] ?? 'info';
                final String notifId = notif['id'].toString();
                // Parse ngày tháng từ String ISO8601 của Postgres
                final createdAt = notif['created_at'] != null
                    ? DateTime.parse(notif['created_at'])
                    : DateTime.now();

                IconData iconData = type == 'incident'
                    ? Icons.handyman_rounded
                    : (type == 'payment'
                        ? Icons.payments_rounded
                        : Icons.notifications);
                Color iconColor = type == 'incident'
                    ? Colors.orange.shade700
                    : (type == 'payment' ? Colors.green.shade700 : Colors.blue);
                Color iconBg = type == 'incident'
                    ? Colors.orange.shade50
                    : (type == 'payment'
                        ? Colors.green.shade50
                        : Colors.blue.shade50);

                userNotifCards.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : Colors.blue.shade50.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isRead
                              ? Colors.transparent
                              : Colors.blue.shade100),
                    ),
                    child: InkWell(
                      onTap: () => controller.markAsRead(notifId, isRead),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.grey.shade100
                                          : iconBg,
                                      shape: BoxShape.circle),
                                  child: Icon(iconData,
                                      color: isRead
                                          ? Colors.grey.shade400
                                          : iconColor,
                                      size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title'] ?? 'Thông báo',
                                              style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  fontSize: 15,
                                                  color: isRead
                                                      ? Colors.grey.shade700
                                                      : Colors.blue.shade900),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(notif['message'] ?? '',
                                          style: TextStyle(
                                              color: isRead
                                                  ? Colors.grey.shade500
                                                  : Colors.blue.shade800,
                                              fontSize: 13,
                                              height: 1.4)),
                                      const SizedBox(height: 8),
                                      Text(
                                          DateFormat('HH:mm - dd/MM/yyyy')
                                              .format(createdAt),
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Nút duyệt thanh toán (Nếu có API cập nhật hóa đơn)
                            if (type == 'payment' && !isRead) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        controller.markAsRead(notifId, isRead),
                                    child: const Text('Bỏ qua',
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        // Gọi hàm xử lý liên kết liên dịch vụ thật
                                        // Đảm bảo trong JSON thông báo của bạn từ Firebase sang có lưu trường 'invoice_id' hoặc tương đương
                                        final String invoiceId =
                                            notif['invoice_id']?.toString() ??
                                                notif['room_id'].toString();

                                        await controller.approvePayment(
                                            notifId, invoiceId);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Đã xác nhận thanh toán thành công vào Postgres!'),
                                                backgroundColor: Colors.green),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Lỗi thực hiện: $e'),
                                                backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle,
                                        size: 18, color: Colors.white),
                                    label: const Text('Xác nhận đã nhận tiền',
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // ==========================================
              // KHỐI 3: RENDER GIAO DIỆN
              // ==========================================
              if (contractCards.isEmpty && userNotifCards.isEmpty) {
                return const Center(
                    child: Text('Không có thông báo mới nào.',
                        style: TextStyle(color: Colors.grey, fontSize: 16)));
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(notificationListProvider.future),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (contractCards.isNotEmpty) ...[
                      const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text('CẢNH BÁO HỢP ĐỒNG',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey,
                                  letterSpacing: 1.2))),
                      ...contractCards,
                      const SizedBox(height: 16),
                    ],
                    if (userNotifCards.isNotEmpty) ...[
                      const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text('TỪ KHÁCH THUÊ',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey,
                                  letterSpacing: 1.2))),
                      ...userNotifCards,
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Khung giao diện thẻ hợp đồng (Rút gọn để tiết kiệm không gian)
  Widget _buildAlertCard(
      {required BuildContext context,
      required WidgetRef ref,
      required RoomModel room,
      required bool isRead,
      required IconData icon,
      required Color color,
      required Color bgColor,
      required String title,
      required String message,
      required String dateText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  isRead ? Colors.transparent : color.withValues(alpha: 0.2))),
      child: InkWell(
        onTap: () {
          ref.read(readContractAlertsProvider.notifier).markAsRead(room.id);
          context.push('/admin/properties/detail', extra: room);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: isRead ? Colors.grey.shade100 : bgColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon,
                      color: isRead ? Colors.grey.shade400 : color, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.bold,
                            color: isRead
                                ? Colors.grey.shade700
                                : Colors.black87)),
                    const SizedBox(height: 6),
                    Text(message,
                        style: TextStyle(
                            fontSize: 13,
                            color: isRead
                                ? Colors.grey.shade500
                                : Colors.grey.shade700,
                            height: 1.4)),
                    const SizedBox(height: 12),
                    Text(dateText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
