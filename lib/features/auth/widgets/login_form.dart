// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../widgets/custom_textfield.dart';
import '../../../services/auth_service.dart';
import 'login_button.dart';
import '../../../storage/token_storage.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/terms_page.dart';
import '../pages/register_page.dart';
import '../../dashboard/pages/profile_page.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    try {
      String deviceName = "Unknown Device";
      String deviceType = "unknown";

      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = "${androidInfo.manufacturer} ${androidInfo.model}";
          deviceType = "android";
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
          deviceType = "ios";
        } else if (kIsWeb) {
          final webInfo = await deviceInfo.webBrowserInfo;
          deviceName = webInfo.browserName.name;
          deviceType = "web";
        } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          deviceName = windowsInfo.computerName;
          deviceType = "windows";
        } else if (Platform.isLinux) {
          final linuxInfo = await deviceInfo.linuxInfo;
          deviceName = linuxInfo.prettyName;
          deviceType = "linux";
        } else if (Platform.isMacOS) {
          final macInfo = await deviceInfo.macOsInfo;
          deviceName = macInfo.computerName;
          deviceType = "macos";
        }
      } catch (e) {
        deviceName = "Unknown Device";
        deviceType = "unknown";
      }

      final response = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
        deviceName: deviceName,
        deviceType: deviceType,
      );

      final hasData = response['data'] != null && response['data']['token'] != null;
      final userData = hasData ? response['data']['user'] : null;
      final statusTerms = userData != null ? userData['status_terms'] : null;
      final isPending = userData != null && userData['status'] == 'Pending';

      if (response["success"] == true || (isPending && (statusTerms == "No" || statusTerms == null))) {
        final token = response['data']['token'];
        final photo = response['data']['user']?['photo'];
        final userData = response['data']['user'];

        await TokenStorage.saveToken(token);
        if (photo != null) {
          await TokenStorage.savePhoto(photo.toString());
        }

        final termsText = response['data']['terms'] ?? "";

        if (statusTerms == "No" || statusTerms == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TermsPage(terms: termsText)),
          );
        } else {
          // Show mandatory requirements dialog BEFORE navigating
          // This ensures user sees the notification right after login
          final goToProfile = await _checkPostLoginRequirements(context, userData);

          if (mounted) {
            if (goToProfile) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            }
          }
        }
      } else {
        throw Exception(response["message"] ?? "Login gagal");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Request location access after login (silently, in the background).
  // Document completeness is checked by the dashboard via getProfile().
  Future<bool> _checkPostLoginRequirements(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    if (!mounted) return false;

    // Check location access permission
    LocationPermission locationPermission = LocationPermission.denied;
    bool needsLocationAccess = false;
    try {
      locationPermission = await Geolocator.checkPermission();
      needsLocationAccess =
          locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever;
    } catch (_) {}

    // Silently request location permission if not yet granted (and not permanently denied)
    if (needsLocationAccess && locationPermission != LocationPermission.deniedForever && mounted) {
      try {
        await Geolocator.requestPermission();
      } catch (_) {}
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,

      child: Column(
        children: [
          CustomTextField(
            controller: emailController,
            hint: "Email atau Nomor HP",
            icon: Icons.person,
          ),

          const SizedBox(height: 14),

          CustomTextField(
            controller: passwordController,
            hint: "Password",
            icon: Icons.lock,
            obscure: true,
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
              },
              child: const Text("Lupa password?"),
            ),
          ),

          const SizedBox(height: 6),

          LoginButton(
            onPressed: isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      _login();
                    }
                  },
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'atau',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Belum punya akun?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                child: const Text('Daftar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
