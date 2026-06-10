import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/update_service.dart';
import '../storage/token_storage.dart';

class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final int currentVersionCode;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.currentVersionCode,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  Map<String, dynamic>? _updateData;
  bool _isChecking = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _error;
  StreamSubscription<http.StreamedResponse>? _downloadSub;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    try {
      final data = await UpdateService.checkUpdate(
        currentVersion: widget.currentVersion,
        currentVersionCode: widget.currentVersionCode,
      );

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _updateData = data;
          _isChecking = false;
        });
      } else {
        // No update available — close dialog silently
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memeriksa update.';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _startDownload() async {
    if (_updateData == null) return;

    final downloadUrl = _updateData!['download_url']?.toString();
    if (downloadUrl == null || downloadUrl.isEmpty) {
      setState(() => _error = 'URL download tidak tersedia.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      final uri = Uri.parse(downloadUrl);
      final request = http.Request('GET', uri);
      final client = http.Client();
      final streamedResponse = await client.send(request);

      final totalBytes = streamedResponse.contentLength ?? 0;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/update_suntikradar.apk';
      final file = File(filePath);

      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);

        if (totalBytes > 0 && mounted) {
          setState(() {
            _downloadProgress = downloadedBytes / totalBytes;
          });
        }
      }

      await sink.close();
      client.close();

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
      });

      // Save the version code so we don't prompt again for this update
      final installedCode = _updateData?['version_code'] as int?;
      if (installedCode != null) {
        await TokenStorage.saveLastUpdateVersionCode(installedCode);
      }

      // Open the APK file (triggers Android install prompt)
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (!mounted) return;

      if (result.type == ResultType.done) {
        // APK opened — user will see Android install prompt
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(
          () => _error = 'Gagal membuka file APK. Silakan install manual.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Gagal mendownload: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool forceUpdate = _updateData?['force_update'] == true;

    return PopScope(
      canPop: !forceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(forceUpdate),
        ),
      ),
    );
  }

  Widget _buildContent(bool forceUpdate) {
    if (_isChecking) {
      return _buildLoadingState();
    }

    if (_error != null && _updateData == null) {
      return _buildErrorState();
    }

    if (_isDownloading) {
      return _buildDownloadingState();
    }

    return _buildUpdateAvailableState(forceUpdate);
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.system_update, size: 48, color: Color(0xff667eea)),
        SizedBox(height: 20),
        Text(
          'Memeriksa update...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        CircularProgressIndicator(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(_error ?? 'Terjadi kesalahan.'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isChecking = true;
                  _error = null;
                });
                _checkForUpdate();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateAvailableState(bool forceUpdate) {
    final version = _updateData?['version'] ?? '';
    final changelog = _updateData?['changelog']?.toString() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff667eea), Color(0xff764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.system_update, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          'Update Tersedia',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Versi $version',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        if (changelog.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(changelog, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff764ba2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Update Sekarang',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (!forceUpdate) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Nanti Saja',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadingState() {
    final progressPercent = (_downloadProgress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.downloading, size: 48, color: Color(0xff667eea)),
        const SizedBox(height: 20),
        const Text(
          'Mendownload update...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$progressPercent%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _downloadProgress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 12),
        Text(
          'Mohon tunggu, jangan tutup aplikasi.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
