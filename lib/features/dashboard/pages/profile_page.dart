// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../layout/main_layout.dart';
import '../../../storage/token_storage.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _oldPasswordController = TextEditingController();

  final _passwordController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengambil foto: $e")));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _oldPasswordController.dispose();

    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AuthService.getProfile();
      // Support multiple API response structures:
      // { data: { ... } } or { user: { ... } } or direct keys
      final data =
          (response['data'] as Map<String, dynamic>?) ??
          (response['user'] as Map<String, dynamic>?) ??
          response;

      if (data['photo'] != null) {
        TokenStorage.savePhoto(data['photo'].toString());
      }

      if (!mounted) return;
      setState(() {
        _profileData = data;
        _nameController.text = (data['name'] ?? "").toString();
        _emailController.text = (data['email'] ?? "").toString();
        _phoneController.text = (data['phone'] ?? "").toString();
        _nikController.text = (data['nik'] ?? "").toString();
        _selectedImage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final body = {
      "name": _nameController.text,
      "email": _emailController.text,
      "phone": _phoneController.text,
      "nik": _nikController.text,
      if (_passwordController.text.isNotEmpty) ...{
        "old_password": _oldPasswordController.text,
        "password": _passwordController.text,
      },
    };

    try {
      Uint8List? photoBytes;
      String? photoName;
      if (_selectedImage != null) {
        photoBytes = await _selectedImage!.readAsBytes();
        photoName = _selectedImage!.name;
      }
      final response = await AuthService.updateProfile(
        body,
        photoBytes: photoBytes,
        photoFileName: photoName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Profil berhasil diperbarui"),
            backgroundColor: Colors.green,
          ),
        );
        _oldPasswordController.clear();
        _passwordController.clear();

        if (response['user'] != null) {
          if (response['user']['photo'] != null) {
            TokenStorage.savePhoto(response['user']['photo'].toString());
          }
          setState(() {
            _profileData = response['user'];
            _nameController.text = response['user']['name'] ?? "";
            _emailController.text = response['user']['email'] ?? "";
            _phoneController.text = response['user']['phone'] ?? "";
            _nikController.text = response['user']['nik'] ?? "";
            _selectedImage = null;
          });
        } else {
          _fetchProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(activeIndex: 3, child: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }

    // Ensure _profileData is not null before building view
    if (_profileData == null) {
      return const Center(child: Text("Data profil tidak tersedia."));
    }

    return _buildProfileView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProfile,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff764ba2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final data = _profileData!;
    final dateFormat = DateFormat('dd MMM yyyy');

    // API menggunakan field "expired", bukan "exp"
    String expiryText = "-";
    if (data['expired'] != null && data['expired'].toString().isNotEmpty) {
      try {
        expiryText = dateFormat.format(
          DateTime.parse(data['expired'].toString()),
        );
      } catch (_) {}
    }

    // "paket" di API adalah object {"nama_paket": "..."}, bukan string
    String paketName = "Tidak ada";
    final paket = data['paket'];
    if (paket != null) {
      if (paket is Map<String, dynamic>) {
        paketName = paket['nama_paket']?.toString() ?? "Tidak ada";
      } else {
        paketName = paket.toString();
      }
    }

    // Status paket
    final approvalStatus = data['approval_status']?.toString() ?? '-';
    final paketStatus = data['paket_status']?.toString() ?? '-';
    final isFree = data['free_status'] != null;
    final freeStatus = data['free_status']?.toString() ?? '-';

    final photoUrl = data['photo']?.toString();
    final hasNetworkPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff667eea), Color(0xff764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            backgroundImage: _selectedImage != null
                                ? (kIsWeb
                                      ? NetworkImage(_selectedImage!.path)
                                      : FileImage(File(_selectedImage!.path)))
                                : hasNetworkPhoto
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (_selectedImage == null && !hasNetworkPhoto)
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Color(0xff764ba2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data['email'] ?? "",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// INFO SECTION
            _buildSectionTitle("Status Layanan"),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  children: [
                    _infoRow(Icons.star_outline, "Paket Aktif", paketName),
                    const Divider(),
                    _infoRow(
                      Icons.info_outline,
                      "Status Paket",
                      _statusLabel(paketStatus),
                    ),
                    const Divider(),
                    _infoRow(Icons.badge_outlined, "NIK", data['nik'] ?? "-"),
                    const Divider(),
                    _infoRow(Icons.event_available, "Masa Berlaku", expiryText),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// EDIT FORM
            _buildSectionTitle("Ubah Profil"),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Nama Lengkap",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Nama tidak boleh kosong" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Email tidak boleh kosong" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Nomor HP",
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOldPassword,
                        decoration: InputDecoration(
                          labelText: "Password Lama",
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureOldPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureOldPassword = !_obscureOldPassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (_passwordController.text.isNotEmpty &&
                              v!.isEmpty) {
                            return "Password lama wajib diisi jika ingin mengubah password";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText:
                              "Password Baru (Kosongkan jika tidak diubah)",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff764ba2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Simpan Perubahan"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
