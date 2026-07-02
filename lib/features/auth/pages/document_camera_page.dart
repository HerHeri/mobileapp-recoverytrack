import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

enum DocumentCaptureType { ktp, selfieKtp, suratTugas, sppi }

class DocumentCameraPage extends StatefulWidget {
  final DocumentCaptureType type;

  const DocumentCameraPage({super.key, required this.type});

  @override
  State<DocumentCameraPage> createState() => _DocumentCameraPageState();
}

class _DocumentCameraPageState extends State<DocumentCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _initializing = true;
  bool _capturing = false;
  bool _flashEnabled = false;
  String? _error;

  bool get _usesFrontCamera => widget.type == DocumentCaptureType.selfieKtp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera({CameraLensDirection? direction}) async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('Kamera tidak tersedia pada perangkat ini.');
      }

      final preferredDirection =
          direction ??
          (_usesFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back);
      final camera = _cameras.firstWhere(
        (item) => item.lensDirection == preferredDirection,
        orElse: () => _cameras.first,
      );

      await _controller?.dispose();
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (widget.type == DocumentCaptureType.selfieKtp &&
          camera.lensDirection == CameraLensDirection.front) {
        final minimumZoom = await controller.getMinZoomLevel();
        await controller.setZoomLevel(minimumZoom);
      }

      if (!mounted) return;
      setState(() {
        _initializing = false;
        _flashEnabled = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = e.description ?? 'Kamera tidak dapat dibuka.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(direction: controller.description.lensDirection);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final enabled = !_flashEnabled;
    await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() => _flashEnabled = enabled);
  }

  Future<void> _switchCamera() async {
    final controller = _controller;
    if (controller == null || _cameras.length < 2) return;

    final nextDirection =
        controller.description.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _initializeCamera(direction: nextDirection);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      if (_flashEnabled) {
        await controller.setFlashMode(FlashMode.off);
      }
      final photo = await controller.takePicture();
      if (mounted) Navigator.pop(context, photo);
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.description ?? 'Foto gagal diambil.')),
      );
      setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initializing
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(),
                  Container(color: Colors.black.withValues(alpha: 0.14)),
                  _CaptureGuide(type: widget.type),
                  _buildTopBar(),
                  _buildBottomControls(),
                ],
              ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _controller!;

    if (widget.type == DocumentCaptureType.selfieKtp &&
        controller.description.lensDirection == CameraLensDirection.front) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1 / controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenRatio = constraints.maxWidth / constraints.maxHeight;
        final previewRatio = controller.value.aspectRatio;
        final scale = previewRatio < screenRatio
            ? screenRatio / previewRatio
            : previewRatio / screenRatio;

        return Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(controller)),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CameraControl(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
            Row(
              children: [
                if (_controller?.description.lensDirection ==
                    CameraLensDirection.back)
                  _CameraControl(
                    icon: _flashEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap: _toggleFlash,
                  ),
                if (_cameras.length > 1) ...[
                  const SizedBox(width: 10),
                  _CameraControl(
                    icon: Icons.cameraswitch_rounded,
                    onTap: _switchCamera,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.86)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _capture,
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _capturing ? Colors.white54 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 2),
                  ),
                  child: _capturing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            color: Colors.black54,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black87,
                          size: 28,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _instruction {
    switch (widget.type) {
      case DocumentCaptureType.ktp:
        return 'Posisikan seluruh KTP di dalam bingkai dan pastikan tulisan terbaca.';
      case DocumentCaptureType.selfieKtp:
        return 'Posisikan kepala dan bahu di oval, lalu pegang KTP dekat wajah pada bingkai.';
      case DocumentCaptureType.suratTugas:
        return 'Posisikan seluruh halaman surat tugas di dalam bingkai.';
      case DocumentCaptureType.sppi:
        return 'Posisikan seluruh halaman surat SPPI di dalam bingkai.';
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureGuide extends StatelessWidget {
  final DocumentCaptureType type;

  const _CaptureGuide({required this.type});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _GuidePainter(type: type),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _GuidePainter extends CustomPainter {
  final DocumentCaptureType type;

  _GuidePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.48);
    final guide = Path()..addRect(Offset.zero & size);
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (type == DocumentCaptureType.ktp) {
      final width = size.width * 0.84;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.43),
        width: width,
        height: width / 1.586,
      );
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(18));
      guide.addRRect(rounded);
      guide.fillType = PathFillType.evenOdd;
      canvas.drawPath(guide, overlay);
      canvas.drawRRect(rounded, framePaint);
      _drawCorners(canvas, rect, framePaint, radius: 18);
    } else if (type == DocumentCaptureType.suratTugas || type == DocumentCaptureType.sppi) {
      final height = size.height * 0.58;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.43),
        width: height * 0.7,
        height: height,
      );
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(12));
      guide.addRRect(rounded);
      guide.fillType = PathFillType.evenOdd;
      canvas.drawPath(guide, overlay);
      canvas.drawRRect(rounded, framePaint);
      _drawCorners(canvas, rect, framePaint, radius: 12);
    } else {
      final faceWidth = size.width * 0.60;
      final faceHeight = size.height * 0.42;
      final faceRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.33),
        width: faceWidth,
        height: faceHeight,
      );
      final cardWidth = size.width * 0.62;
      final cardHeight = cardWidth / 1.686;
      final cardTop = faceRect.bottom + size.height * 0.045;
      final cardRect = Rect.fromCenter(
        center: Offset(size.width / 2, cardTop + (cardHeight / 2)),
        width: cardWidth,
        height: cardHeight,
      );
      final cardRounded = RRect.fromRectAndRadius(
        cardRect,
        const Radius.circular(10),
      );

      guide.addOval(faceRect);
      guide.addRRect(cardRounded);
      guide.fillType = PathFillType.evenOdd;
      canvas.drawPath(guide, overlay);
      canvas.drawOval(faceRect, framePaint);
      canvas.drawRRect(cardRounded, framePaint);
      _drawCorners(canvas, cardRect, framePaint, radius: 10);
    }
  }

  void _drawCorners(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    required double radius,
  }) {
    final cornerPaint = Paint()
      ..color = const Color(0xFF80D8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const length = 24.0;

    canvas.drawLine(
      Offset(rect.left + radius, rect.top),
      Offset(rect.left + radius + length, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + radius),
      Offset(rect.left, rect.top + radius + length),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right - radius, rect.top),
      Offset(rect.right - radius - length, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + radius),
      Offset(rect.right, rect.top + radius + length),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left + radius, rect.bottom),
      Offset(rect.left + radius + length, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - radius),
      Offset(rect.left, rect.bottom - radius - length),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right - radius, rect.bottom),
      Offset(rect.right - radius - length, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - radius),
      Offset(rect.right, rect.bottom - radius - length),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    return oldDelegate.type != type;
  }
}

class _CameraControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CameraControl({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
      ),
    );
  }
}
