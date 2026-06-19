import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class InvoiceMigrationTool extends StatefulWidget {
  const InvoiceMigrationTool({super.key});

  @override
  State<InvoiceMigrationTool> createState() => _InvoiceMigrationToolState();
}

class _InvoiceMigrationToolState extends State<InvoiceMigrationTool> {
  List<String> logs = [];
  bool isRunning = false;

  void addLog(String message) {
    setState(() {
      logs.insert(0, message); // Đẩy log mới nhất lên đầu
    });
  }

  Future<void> startNotificationMigration() async {
    setState(() => isRunning = true);
    addLog('🚀 Bắt đầu dọn nhà THÔNG BÁO...');

    try {
      final firebaseToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      addLog('🎫 Đang xin cấp vé Access Token...');
      final loginRes = await http.post(
        Uri.parse('http://localhost/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': firebaseToken}),
      );
      final accessToken = jsonDecode(loginRes.body)['access_token'];

      // Kéo từ bảng notifications của Firebase
      final snapshot =
          await FirebaseFirestore.instance.collection('notifications').get();
      addLog(
          '📦 Bắt được ${snapshot.docs.length} thông báo. Đang chuyển đi...');

      int successCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Chuẩn hóa dữ liệu Firebase sang Postgres
        final payload = {
          'title': data['title'] ?? 'Không tiêu đề',
          'message': data['message'] ?? '...',
          'type': data['type'] ?? 'info',
          'is_read': data['isRead'] ?? data['is_read'] ?? false,
          'recipient_id': data['userId'] ?? data['recipient_id']?.toString(),
          'room_id': data['roomId']?.toString(),
          // Xử lý Timestamp của Firebase (rất hay gây lỗi nếu không parse cẩn thận)
          'created_at': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        };

        final response = await http.post(
          Uri.parse(
              'http://localhost/api/v1/notifications'), // API Gateway tự điều phối sang Port 5004
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 201) {
          successCount++;
          addLog('✅ Chuyển OK: ${payload['title']}');
        } else {
          addLog('❌ Lỗi: ${response.body}');
        }
      }

      addLog(
          '🎉 XONG! Chuyển thành công $successCount/${snapshot.docs.length} thông báo.');
    } catch (e) {
      addLog('❌ Lỗi hệ thống: $e');
    } finally {
      setState(() => isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công Cụ Dọn Dữ Liệu Hóa Đơn',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                const Icon(Icons.cloud_sync, size: 60, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Firebase ➔ PostgreSQL',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isRunning ? null : startNotificationMigration,
                  icon: isRunning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(
                    isRunning
                        ? 'ĐANG CHUYỂN DỮ LIỆU...'
                        : 'BẮT ĐẦU CHUYỂN DỮ LIỆU',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.grey.shade100,
            child: const Text('BẢNG ĐIỀU KHIỂN (LOGS)',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      logs[index],
                      style: TextStyle(
                        color: logs[index].contains('❌')
                            ? Colors.redAccent
                            : (logs[index].contains('✅')
                                ? Colors.greenAccent
                                : Colors.white),
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
