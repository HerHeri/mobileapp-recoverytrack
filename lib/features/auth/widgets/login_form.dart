// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../../widgets/custom_textfield.dart';
import '../../../services/auth_service.dart';
import 'login_button.dart';
import '../../../storage/token_storage.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/terms_page.dart';
import '../pages/register_page.dart';

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

      if (response["success"] == true) {
        final token = response['data']['token'];
        final photo = response['data']['user']?['photo'];

        await TokenStorage.saveToken(token);
        if (photo != null) {
          await TokenStorage.savePhoto(photo.toString());
        }

        final statusTerms = response['data']['user']['status_terms'];
        final termsText = response['data']['terms'] ?? "";

        if (statusTerms == "No" || statusTerms == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TermsPage(terms: termsText)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
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
