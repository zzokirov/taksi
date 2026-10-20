import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterCustomerScreen extends ConsumerStatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  ConsumerState<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends ConsumerState<RegisterCustomerScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+99890');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iltimos, foydalanish shartlariga rozilik bildiring"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).registerCustomer(
      phone: _phoneController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );

    if (success && mounted) {
      context.go('/customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mijoz Ro'yxatdan O'tish"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  hint: "Ali Valiyev",
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? "Ismingizni kiriting" : null,
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
                  controller: _emailController,
                  label: "Email (ixtiyoriy)",
                  hint: "example@mail.uz",
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      activeColor: AppColors.gold,
                      checkColor: Colors.black,
                      onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        AppStrings.termsAccept,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: AppStrings.register,
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
