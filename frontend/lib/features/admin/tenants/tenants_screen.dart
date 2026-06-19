import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../properties/models/room_model.dart';
import '../properties/data/room_repository.dart';

// Nhập Model và Controller từ các file riêng biệt
import '../properties/models/tenant_model.dart';
import '../properties/controllers/tenants_controller.dart';

class TenantsScreen extends HookConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final roomsAsync = ref.watch(roomListStreamProvider);

    final tenants = roomsAsync.maybeWhen(
      data: (rooms) {
        final rentedRooms = rooms.where(
          (r) => r.status == RoomStatus.rented && r.tenantName != null,
        );

        var tenantList = rentedRooms
            .map((r) => TenantModel(
                  roomId: r.id,
                  fullName: r.tenantName!,
                  phone: r.tenantPhone?.isNotEmpty == true
                      ? r.tenantPhone!
                      : 'Chưa cập nhật',
                  roomName: r.name,
                  room: r,
                ))
            .toList();

        if (searchQuery.value.isNotEmpty) {
          final query = searchQuery.value.toLowerCase();
          tenantList = tenantList
              .where((t) =>
                  t.fullName.toLowerCase().contains(query) ||
                  t.phone.contains(query))
              .toList();
        }
        return tenantList;
      },
      orElse: () => <TenantModel>[],
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Danh bạ Khách thuê',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 1)),
              ),
            ),
          ),
          Expanded(
            child: tenants.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    itemCount: tenants.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return TenantCard(tenant: tenants[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy khách thuê',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class TenantCard extends HookConsumerWidget {
  final TenantModel tenant;

  const TenantCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // 👉 GỌI TIỀN NỢ TỪ POSTGRESQL THÔNG QUA CONTROLLER
    final debtAsync = ref.watch(tenantDebtProvider(tenant.roomId));

    final debtAmount = debtAsync.when(
      data: (debt) => debt,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final hasDebt = debtAmount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
        border: Border.all(
            color: hasDebt ? Colors.red.shade300 : Colors.transparent,
            width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: hasDebt ? Colors.red.shade50 : Colors.blue.shade50,
          child: Text(
            tenant.fullName.isNotEmpty
                ? tenant.fullName.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hasDebt ? Colors.red : Colors.blue),
          ),
        ),
        title: Text(tenant.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.meeting_room_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Phòng: ${tenant.roomName}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(tenant.phone),
                ],
              ),
            ],
          ),
        ),
        trailing: hasDebt
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Đang nợ',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Text(currencyFormat.format(debtAmount),
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          context.push('/admin/properties/detail', extra: tenant.room);
        },
      ),
    );
  }
}
