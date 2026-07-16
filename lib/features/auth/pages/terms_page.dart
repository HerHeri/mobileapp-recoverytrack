import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../dashboard/pages/dashboard_page.dart';

import '../pages/login_page.dart';
import '../../../storage/token_storage.dart';

class TermsPage extends StatefulWidget {
  final String terms;

  const TermsPage({super.key, required this.terms});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _isLoading = false;
  bool _isAgreed = false;

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.updateTerms("Yes");
      if (response['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      } else {
        throw Exception(response['message'] ?? "Gagal menyimpan persetujuan");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.logout();
      await TokenStorage.clearToken();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal logout: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.gavel_rounded, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "Syarat & Ketentuan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Silakan baca dan setujui untuk melanjutkan",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      widget.terms,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () => setState(() => _isAgreed = !_isAgreed),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            onChanged: _isLoading
                                ? null
                                : (value) => setState(
                                    () => _isAgreed = value ?? false,
                                  ),
                            activeColor: Colors.white,
                            checkColor: const Color(0xFF764BA2),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'Dengan memberikan tanda centang pada kolom ini, '
                                'Pengguna Aplikasi menyatakan bahwa persetujuan '
                                'elektronik yang diberikan merupakan tindakan sah '
                                'yang mengikat secara hukum dan memiliki kekuatan '
                                'pembuktian sebagaimana persetujuan tertulis '
                                'berdasarkan ketentuan peraturan perundang-undangan '
                                'yang berlaku di Republik Indonesia.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isAgreed
                            ? null
                            : _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF764BA2),
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.45,
                          ),
                          disabledForegroundColor: const Color(
                            0xFF764BA2,
                          ).withValues(alpha: 0.55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF764BA2),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Setuju dan Lanjutkan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _handleLogout,
                child: Text(
                  "Kembali ke Login",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
