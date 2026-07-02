// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/pages/document_camera_page.dart';
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

  XFile? _photo;
  XFile? _ktpPhoto;
  XFile? _selfieKtpPhoto;
  XFile? _suratTugasPhoto;
  XFile? _sppiPhoto;
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

  Future<void> _pickImage(String type) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;
    if (!mounted) return;
    setState(() {
      switch (type) {
        case 'photo':
          _photo = image;
          break;

        case 'ktp':
          _ktpPhoto = image;
          break;

        case 'selfie':
          _selfieKtpPhoto = image;
          break;

        case 'surat':
          _suratTugasPhoto = image;
          break;

        case 'sppi':
          _sppiPhoto = image;
          break;
      }
    });
  }

  Future<void> _takeLivePhoto(DocumentCaptureType type, String key) async {
    try {
      final photo = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(builder: (_) => DocumentCameraPage(type: type)),
      );
      if (photo == null) return;

      if (await photo.length() > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ukuran foto maksimal 2 MB. Silakan ambil ulang foto.',
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          switch (key) {
            case 'ktp':
              _ktpPhoto = photo;
              break;
            case 'selfie':
              _selfieKtpPhoto = photo;
              break;
            case 'surat':
              _suratTugasPhoto = photo;
              break;
            case 'sppi':
              _sppiPhoto = photo;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kamera tidak dapat dibuka. Pastikan izin kamera sudah diberikan.',
            ),
          ),
        );
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
        _photo = null;
        _ktpPhoto = null;
        _selfieKtpPhoto = null;
        _suratTugasPhoto = null;
        _sppiPhoto = null;
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

    // Validate profile data exists
    if (_profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data profil tidak tersedia"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate mandatory photo fields
    if (_ktpPhoto == null &&
        (_profileData!['ktp_photo'] == null ||
            _profileData!['ktp_photo'].toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto KTP wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selfieKtpPhoto == null &&
        (_profileData!['selfie_ktp_photo'] == null ||
            _profileData!['selfie_ktp_photo'].toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selfie dengan KTP wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_suratTugasPhoto == null &&
        (_profileData!['surat_tugas_photo'] == null ||
            _profileData!['surat_tugas_photo'].toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Surat Tugas wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sppiPhoto == null &&
        (_profileData!['sppi_photo'] == null ||
            _profileData!['sppi_photo'].toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto SPPI wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final body = {
      "name": _nameController.text,
      "email": _emailController.text,
      "phone": _phoneController.text,
      if (_passwordController.text.isNotEmpty) ...{
        "old_password": _oldPasswordController.text,
        "password": _passwordController.text,
      },
    };

    try {
      final response = await AuthService.updateProfile(
        body,

        photoBytes: _photo == null ? null : await _photo!.readAsBytes(),
        photoFileName: _photo?.name,

        ktpPhotoBytes: _ktpPhoto == null
            ? null
            : await _ktpPhoto!.readAsBytes(),
        ktpPhotoFileName: _ktpPhoto?.name,

        selfieKtpPhotoBytes: _selfieKtpPhoto == null
            ? null
            : await _selfieKtpPhoto!.readAsBytes(),
        selfieKtpPhotoFileName: _selfieKtpPhoto?.name,

        suratTugasPhotoBytes: _suratTugasPhoto == null
            ? null
            : await _suratTugasPhoto!.readAsBytes(),
        suratTugasPhotoFileName: _suratTugasPhoto?.name,

        sppiPhotoBytes: _sppiPhoto == null
            ? null
            : await _sppiPhoto!.readAsBytes(),
        sppiPhotoFileName: _sppiPhoto?.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Profil berhasil diperbarui"),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchProfile();
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
            _photo = null;
            _ktpPhoto = null;
            _selfieKtpPhoto = null;
            _suratTugasPhoto = null;
            _sppiPhoto = null;
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
        await _fetchProfile();
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
    // Check if profile is approved by admin (using paket_status field)
    final isProfileApproved =
        data['paket_status']?.toString().toLowerCase() == 'approved';



    final hasKtp =
        data['ktp_photo'] != null && data['ktp_photo'].toString().isNotEmpty;
    final hasSelfie =
        data['selfie_ktp_photo'] != null &&
        data['selfie_ktp_photo'].toString().isNotEmpty;
    final hasSurat =
        data['surat_tugas_photo'] != null &&
        data['surat_tugas_photo'].toString().isNotEmpty;
    final hasSppi =
        data['sppi_photo'] != null &&
        data['sppi_photo'].toString().isNotEmpty;
    final isPhotosIncomplete = !hasKtp || !hasSelfie || !hasSurat || !hasSppi;

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
    final paketStatus = data['paket_status']?.toString() ?? '-';

    final photoUrl = data['photo']?.toString();
    final hasNetworkPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BANNER: Sudah disetujui admin ---
            if (isProfileApproved)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profil Telah Disetujui',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Data profil Anda telah disetujui oleh admin. Anda tetap dapat memperbarui nama, password, dan dokumen pendukung jika diperlukan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // --- BANNER: Dokumen belum lengkap ---
            if (isPhotosIncomplete) ...[
              Builder(
                builder: (context) {
                  final missing = <String>[];
                  if (data['ktp_photo'] == null ||
                      data['ktp_photo'].toString().isEmpty) {
                    missing.add('Foto KTP');
                  }
                  if (data['selfie_ktp_photo'] == null ||
                      data['selfie_ktp_photo'].toString().isEmpty) {
                    missing.add('Selfie dengan KTP');
                  }
                  if (data['surat_tugas_photo'] == null ||
                      data['surat_tugas_photo'].toString().isEmpty) {
                    missing.add('Surat Tugas');
                  }
                  if (data['sppi_photo'] == null ||
                      data['sppi_photo'].toString().isEmpty) {
                    missing.add('Foto SPPI');
                  }
                  if (missing.isEmpty) return const SizedBox.shrink();

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dokumen Belum Lengkap',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lengkapi dokumen berikut untuk mengakses fitur pencarian:\n${missing.map((d) => '• $d').join('\n')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

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
                      onTap: () => _pickImage('photo'),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            backgroundImage: _photo != null
                                ? (kIsWeb
                                      ? NetworkImage(_photo!.path)
                                      : FileImage(File(_photo!.path)))
                                : hasNetworkPhoto
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (_photo == null && !hasNetworkPhoto)
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          if (true)
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
                          // Admin approval indicator
                          if (isProfileApproved)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.5),
                                  ),
                                ),
                                child: const Text(
                                  "Disetujui Admin",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                        readOnly: false,
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
                        readOnly: isProfileApproved,
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
                        readOnly: isProfileApproved,
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
                                      _obscureOldPassword =
                                          !_obscureOldPassword;
                                    });
                                  },
                                ),
                        ),
                        readOnly: false,
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
                                      _obscureNewPassword =
                                          !_obscureNewPassword;
                                    });
                                  },
                                ),
                        ),
                        readOnly: false,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Dokumen"),
                      _buildDocumentPicker(
                        title: "Foto KTP",
                        networkImage: data['ktp_photo'],
                        localImage: _ktpPhoto,
                        onTap: () =>
                            _takeLivePhoto(DocumentCaptureType.ktp, 'ktp'),
                        isLocked: false,
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentPicker(
                        title: "Selfie Dengan KTP",
                        networkImage: data['selfie_ktp_photo'],
                        localImage: _selfieKtpPhoto,
                        onTap: () => _takeLivePhoto(
                          DocumentCaptureType.selfieKtp,
                          'selfie',
                        ),
                        isLocked: false,
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentPicker(
                        title: "Surat Tugas",
                        networkImage: data['surat_tugas_photo'],
                        localImage: _suratTugasPhoto,
                        onTap: () => _takeLivePhoto(
                          DocumentCaptureType.suratTugas,
                          'surat',
                        ),
                        isLocked: false,
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentPicker(
                        title: "Foto SPPI",
                        networkImage: data['sppi_photo'],
                        localImage: _sppiPhoto,
                        onTap: () => _takeLivePhoto(
                          DocumentCaptureType.sppi,
                          'sppi',
                        ),
                        isLocked: false,
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

  Widget _buildDocumentPicker({
    required String title,
    required String? networkImage,
    required XFile? localImage,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    Widget imageWidget;

    if (localImage != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(localImage.path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (networkImage != null && networkImage.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          networkImage,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: Icon(Icons.image, size: 60)),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock_outline, size: 14, color: Colors.green),
                ],
              ],
            ),
            const SizedBox(height: 10),
            imageWidget,
            const SizedBox(height: 12),
            if (isLocked)
              // Locked state: show non-interactive label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Sudah Disetujui Admin',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Pilih Foto"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // atau 0 agar benar-benar kotak
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
