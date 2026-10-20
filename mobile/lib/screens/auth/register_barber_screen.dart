import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterBarberScreen extends ConsumerStatefulWidget {
  const RegisterBarberScreen({super.key});

  @override
  ConsumerState<RegisterBarberScreen> createState() => _RegisterBarberScreenState();
}

class _RegisterBarberScreenState extends ConsumerState<RegisterBarberScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+99890');
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController(text: '3');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final expYears = int.tryParse(_experienceController.text.trim()) ?? 1;

    final success = await ref.read(authProvider.notifier).registerBarber(
      phone: _phoneController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      barbershopName: _shopNameController.text.trim(),
      address: _addressController.text.trim(),
      bio: _bioController.text.trim(),
      experienceYears: expYears,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Ro'yxatdan o'tildi!", style: TextStyle(color: AppColors.gold)),
          content: const Text(
            "Sartaroshlik profilingiz muvaffaqiyatli yaratildi. Platforma ma'muriyati (Admin) profilni tasdiqlaganidan so'ng mijozlar sizga yozilishlari mumkin bo'ladi.",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/barber');
              },
              child: const Text("Kabinetga o'tish"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sartarosh Ro'yxatdan O'tish"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold, width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Sartarosh akkauntlari xavfsizlik va sifatni ta'minlash uchun administrator tomonidan tasdiqlanadi.",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error, width: 0.8),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],

                CustomTextField(
                  controller: _fullNameController,
                  label: AppStrings.fullName,
                  hint: "Sardor Aliyev",
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? "Ism-familiyangizni kiriting" : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneNumber,
                  hint: "+998901234567",
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.length < 9) ? "To'g'ri telefon raqami kiriting" : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _shopNameController,
                  label: AppStrings.barbershopName,
                  hint: "Masalan: Royal Fade Lounge",
                  prefixIcon: Icons.storefront,
                  validator: (v) => (v == null || v.isEmpty) ? "Sartaroshxona nomini kiriting" : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: AppStrings.address,
                  hint: "Toshkent sh., Chilonzor tumani",
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? "Manzilni kiriting" : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _experienceController,
                  label: AppStrings.experienceYears,
                  hint: "3",
                  prefixIcon: Icons.workspace_premium_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _bioController,
                  label: AppStrings.bio,
                  hint: "O'zingiz, mutaxassisligingiz va uslubingiz haqida",
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: "Kamida 6 belgi",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) => (v == null || v.length < 6) ? "Parol kamida 6 belgidan iborat bo'lsin" : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.passwordConfirm,
                  hint: "Parolni qayta kiriting",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v != _passwordController.text) return "Parollar mos kelmadi";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: "Ro'yxatdan o'tish va tasdiqqa yuborish",
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Akkauntingiz bormi? Kirish", style: TextStyle(color: AppColors.gold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
