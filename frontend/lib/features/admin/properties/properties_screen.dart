import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import 2 file bạn vừa tách ra
import 'models/room_model.dart';
import 'widgets/room_card.dart';
import 'data/room_repository.dart';

class PropertiesScreen extends HookConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);

    final searchQuery = useState<String>('');
    final searchController = useTextEditingController();

    final statusFilter = useState<RoomStatus?>(null);
    final sortFilter = useState<String>('default');

    void _showFilterModal() {
      RoomStatus? tempStatus = statusFilter.value;
      String tempSort = sortFilter.value;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Lọc danh sách phòng',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text('Trạng thái phòng',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Tất cả', tempStatus == null,
                          () => setModalState(() => tempStatus = null)),
                      _buildFilterChip(
                          'Phòng trống',
                          tempStatus == RoomStatus.available,
                          () => setModalState(
                              () => tempStatus = RoomStatus.available)),
                      _buildFilterChip(
                          'Đã thuê',
                          tempStatus == RoomStatus.rented,
                          () => setModalState(
                              () => tempStatus = RoomStatus.rented)),
                      _buildFilterChip(
                          'Bảo trì',
                          tempStatus == RoomStatus.maintenance,
                          () => setModalState(
                              () => tempStatus = RoomStatus.maintenance)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Sắp xếp theo giá',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Mặc định', tempSort == 'default',
                          () => setModalState(() => tempSort = 'default')),
                      _buildFilterChip('Giá thấp đến cao', tempSort == 'asc',
                          () => setModalState(() => tempSort = 'asc')),
                      _buildFilterChip('Giá cao xuống thấp', tempSort == 'desc',
                          () => setModalState(() => tempSort = 'desc')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            statusFilter.value = null;
                            sortFilter.value = 'default';
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Bỏ lọc',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            statusFilter.value = tempStatus;
                            sortFilter.value = tempSort;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Áp dụng',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.home_work, color: Color(0xFF2E7D32), size: 24),
            const SizedBox(width: 8),
            const Text('NestFinder',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87)),
            const Spacer(),
            const Text('Phòng trọ',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black)),
            const Spacer(),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: (statusFilter.value != null ||
                          sortFilter.value != 'default')
                      ? const Color(0xFF2E7D32)
                      : Colors.black87,
                ),
                onPressed: _showFilterModal,
              ),
              if (statusFilter.value != null || sortFilter.value != 'default')
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle)),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => ref.invalidate(
                roomListStreamProvider), // Nút tải lại bằng tay nếu cần
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Tìm phòng, khách thuê...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel,
                            color: Colors.grey, size: 20),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F5F7),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: roomsAsyncValue.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
              error: (err, stack) =>
                  Center(child: Text('Lỗi tải dữ liệu: $err')),
              data: (rooms) {
                var filteredRooms = rooms.where((room) {
                  final query = searchQuery.value.toLowerCase().trim();
                  final matchText = query.isEmpty ||
                      room.name.toLowerCase().contains(query) ||
                      (room.tenantName?.toLowerCase().contains(query) ?? false);
                  final matchStatus = statusFilter.value == null ||
                      room.status == statusFilter.value;
                  return matchText && matchStatus;
                }).toList();

                if (sortFilter.value == 'asc') {
                  filteredRooms.sort((a, b) => a.price.compareTo(b.price));
                } else if (sortFilter.value == 'desc') {
                  filteredRooms.sort((a, b) => b.price.compareTo(a.price));
                }

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Không tìm thấy phòng nào phù hợp',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRooms.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return RoomCard(room: filteredRooms[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/properties/add'),
        backgroundColor: const Color(0xFF388E3C),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
          border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
        ),
      ),
    );
  }
}
