// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../../widgets/custom_textfield.dart';
import '../widgets/login_header.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum ForgotPasswordStep { email, otp, reset }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.resetPassword(
        _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'OTP dikirim ke email')),
      );
      setState(() => _currentStep = ForgotPasswordStep.otp);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.verifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );
      setState(() => _currentStep = ForgotPasswordStep.reset);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.changePassword(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Password berhasil diubah'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff667eea), Color(0xff764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoginHeader(),
                        const SizedBox(height: 24),
                        Text(
                          _getStepTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStepContent(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _getStepAction(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff667eea),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_getButtonText()),
                          ),
                        ),
                        if (_currentStep == ForgotPasswordStep.email) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Kembali ke Login"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        return "Lupa Password";
      case ForgotPasswordStep.otp:
        return "Verifikasi OTP";
      case ForgotPasswordStep.reset:
        return "Reset Password";
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        return "Kirim OTP";
      case ForgotPasswordStep.otp:
        return "Verifikasi OTP";
      case ForgotPasswordStep.reset:
        return "Ganti Password";
    }
  }

  VoidCallback _getStepAction() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        return _handleResetRequest;
      case ForgotPasswordStep.otp:
        return _handleVerifyOtp;
      case ForgotPasswordStep.reset:
        return _handleChangePassword;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        return Column(
          children: [
            const Text(
              "Masukkan email terdaftar Anda untuk menerima kode OTP.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hint: "Email",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        );
      case ForgotPasswordStep.otp:
        return Column(
          children: [
            Text(
              "Masukkan kode OTP yang dikirim ke ${_emailController.text}",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _otpController,
              hint: "Kode OTP",
              icon: Icons.security,
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case ForgotPasswordStep.reset:
        return Column(
          children: [
            const Text(
              "Masukkan password baru Anda.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              hint: "Password Baru",
              icon: Icons.lock,
              obscure: true,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _confirmPasswordController,
              hint: "Konfirmasi Password",
              icon: Icons.lock_outline,
              obscure: true,
            ),
          ],
        );
    }
  }
}
