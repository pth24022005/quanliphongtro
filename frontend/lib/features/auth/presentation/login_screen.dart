import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/custom_button.dart';
import '../../shared/custom_text_field.dart';
import 'auth_controller.dart';
import '../../admin/profile/widgets/change_password_bottom_sheet.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordHidden = useState(true);
    final isLoading = useState(false);

    Future<void> handleLogin([String? _]) async {
      final phone = phoneController.text.trim();
      final password = passwordController.text.trim();

      ScaffoldMessenger.of(context).clearSnackBars();

      if (phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng nhập đầy đủ số điện thoại và mật khẩu'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
          ),
        );
        return;
      }

      isLoading.value = true;
      // Gọi qua controller để băm login bằng PostgreSQL JWT
      final success = await ref
          .read(authProvider.notifier)
          .login(phone, password);
      isLoading.value = false;

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Số điện thoại hoặc mật khẩu không chính xác!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (success && context.mounted) {
        // Chuyển hướng khi thành công (Đã được đưa vào đúng phạm vi của hàm)
        context.go('/admin/properties'); 
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chào mừng trở lại',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để quản lý hệ thống phòng trọ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                CustomTextField(
                  label: 'Tài khoản',
                  hint: 'Nhập số điện thoại đăng nhập',
                  prefixIcon: Icons.phone_android_outlined,
                  controller: phoneController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  prefixIcon: Icons.lock_outline,
                  controller: passwordController,
                  isPassword: isPasswordHidden.value,
                  textInputAction: TextInputAction.done,
                  onSubmitted: handleLogin,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        isPasswordHidden.value = !isPasswordHidden.value,
                  ),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const ChangePasswordBottomSheet(),
                      );
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Đăng nhập',
                  isLoading: isLoading.value,
                  onPressed: handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}