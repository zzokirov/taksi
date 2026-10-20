import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _notifications = true;

  void _showPasswordChangeDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Parolni o'zgartirish", style: TextStyle(color: AppColors.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Amaldagi parol"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Yangi parol"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Yangi parolni tasdiqlang"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Bekor qilish", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Parol muvaffaqiyatli o'zgartirildi!"), backgroundColor: AppColors.success),
              );
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mening Profilim"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Name Card
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: const Icon(Icons.person, color: AppColors.gold, size: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? "Foydalanuvchi",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phoneNumber ?? '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Profile Settings Menu
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Bildirishnomalar", style: TextStyle(color: Colors.white, fontSize: 15)),
                    subtitle: const Text("Yangi holatlar va eslatmalar haqida xabar olish", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    value: _notifications,
                    activeColor: AppColors.gold,
                    onChanged: (val) => setState(() => _notifications = val),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.gold),
                    title: const Text("Parolni o'zgartirish", style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
                    onTap: _showPasswordChangeDialog,
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: AppColors.gold),
                    title: const Text("Qo'llab-quvvatlash va yordam", style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Telegram: @barber_support_bot")),
                      );
                    },
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.gold),
                    title: const Text("Ilova haqida", style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: const Text("v1.0.0", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(AppStrings.logout, style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
