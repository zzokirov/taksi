import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '+998905555555');
  final _passwordController = TextEditingController(text: 'customer123');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null && user.isBarber) {
        context.go('/barber');
      } else {
        context.go('/customer');
      }
    }
  }

  void _fillQuickCredentials(String phone, String password) {
    setState(() {
      _phoneController.text = phone;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: const Icon(Icons.content_cut, color: AppColors.gold, size: 40),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.loginSubtitle,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Error Banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Inputs
                  CustomTextField(
                    controller: _phoneController,
                    label: AppStrings.phoneNumber,
                    hint: "+998901234567",
                    prefixIcon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Telefon raqamini kiriting";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    label: AppStrings.password,
                    hint: "••••••••",
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Parolni kiriting";
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: AppStrings.loginButton,
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Quick Demo Accounts Pill Chips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tezkor Demo Kirish:",
                          style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text("Mijoz (Sanjar)", style: TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.card,
                              side: const BorderSide(color: AppColors.gold, width: 0.5),
                              onPressed: () => _fillQuickCredentials('+998905555555', 'customer123'),
                            ),
                            ActionChip(
                              label: const Text("Sartarosh (Sardor)", style: TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.card,
                              side: const BorderSide(color: AppColors.gold, width: 0.5),
                              onPressed: () => _fillQuickCredentials('+998901111111', 'barber123'),
                            ),
                            ActionChip(
                              label: const Text("Admin", style: TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.card,
                              side: const BorderSide(color: Colors.redAccent, width: 0.5),
                              onPressed: () => _fillQuickCredentials('+998900000001', 'admin123'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),

                  // Registration Links
                  CustomButton(
                    text: AppStrings.registerCustomer,
                    isOutlined: true,
                    onPressed: () => context.push('/register-customer'),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => context.push('/register-barber'),
                    child: const Text(
                      AppStrings.registerBarber,
                      style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w600),
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
}
