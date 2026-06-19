import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/room_model.dart';
import '../data/room_repository.dart';

class RoomCard extends ConsumerWidget {
  final RoomModel room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Dismissible(
      key: Key(room.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async => _confirmDelete(context, ref),
      onDismissed: (direction) => _deleteRoom(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/admin/properties/detail', extra: room),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: room.status.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: room.status.bgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  room.status.label,
                                  style: TextStyle(color: room.status.color, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(room.price),
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => context.push('/admin/properties/detail/edit', extra: room),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () async {
                                      final confirm = await _confirmDelete(context, ref);
                                      if (confirm == true) _deleteRoom(context, ref);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, WidgetRef ref) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn ${room.name} không?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red.shade50),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa ngay', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRoom(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(roomRepositoryProvider).deleteRoom(room.id);
      // Gọi API tải lại danh sách sau khi xóa
      ref.invalidate(roomListStreamProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa ${room.name}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red));
      }
    }
  }
}