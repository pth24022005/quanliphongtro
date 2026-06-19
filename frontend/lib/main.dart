import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Đồng bộ dùng hooks_riverpod cho toàn dự án
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/router/app_router.dart';

void main() async {
  // Đảm bảo các thành phần hệ thống của Flutter được khởi tạo trước
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase kết nối với Server
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Bọc app bằng ProviderScope để dùng Riverpod
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends HookConsumerWidget {
  // Nâng cấp lên HookConsumerWidget để thống nhất
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy instance của router từ provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NestFinder', // Sửa lại tên App chuẩn
      theme: ThemeData(
        // Cài đặt màu chủ đạo khớp với màu xanh (#2E7D32) của hệ thống NestFinder
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        // Nếu bạn có dùng Google Fonts thì định nghĩa luôn ở đây để áp dụng toàn App
        // fontFamily: 'Inter',
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG góc phải
    );
  }
}
