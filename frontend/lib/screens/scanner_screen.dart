import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'processing_screen.dart';

/// QR Scanner screen for Bharosa Pay.
///
/// Responsibility (for this stage):
///   1. Open the camera and show a QR scanning UI.
///   2. Detect a QR code and capture its raw decoded string.
///   3. Navigate to ProcessingScreen with that raw string unchanged.
///   4. Resume scanning correctly if the user comes back to this
///      screen later (e.g. via "Scan Another QR").
///
/// It does NOT call any backend, score anything, or navigate to the
/// result screen — that comes later once the API is wired up inside
/// ProcessingScreen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Brand colors, matched to the rest of the app.
  static const Color _navy = Color(0xFF102A43);
  static const Color _green = Color(0xFF1FA25A);

  // Controls the camera: start/stop, torch, facing direction, etc.
  late final MobileScannerController _controller;

  // Prevents us from processing the same QR repeatedly while the
  // camera keeps detecting it every frame.
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    // Always release the camera when leaving this screen, otherwise
    // it stays "locked" by this controller.
    _controller.dispose();
    super.dispose();
  }

  /// Called every time mobile_scanner detects one or more barcodes.
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return; // Ignore further scans until we're done with this one.

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    // Pause the camera so it stops firing more detections while we
    // move on to the next screen.
    _controller.stop();

    _goToProcessingScreen(rawValue);
  }

  /// Navigates to ProcessingScreen, passing the raw QR string exactly
  /// as decoded — no parsing, modification, or scoring happens here.
  ///
  /// We `await` the navigation so that when the user eventually comes
  /// back to ScannerScreen (e.g. by popping back from a later screen
  /// such as "Scan Another QR"), we know exactly when that happens and
  /// can resume the camera correctly instead of leaving it stopped.
  Future<void> _goToProcessingScreen(String rawValue) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(qrPayload: rawValue),
      ),
    );

    // We're back on ScannerScreen now. If this State object is still
    // alive (the widget wasn't disposed while we were away), reset
    // the processing flag and restart the camera so scanning works
    // again immediately.
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _controller.start();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- Camera preview, fills the whole screen ---
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              // Shown if the camera fails to start (e.g. permission
              // denied, no camera available, camera in use elsewhere).
              return _CameraErrorView(error: error);
            },
          ),

          // --- Top bar: back button + title ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Bharosa Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.flash_on,
                    onPressed: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),

          // --- Scanning frame + instruction ---
          Align(
            alignment: const Alignment(0, -0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScanFrame(color: _green),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align QR within the frame',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // --- Bottom hint ---
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Scanning QR will not deduct any amount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded, semi-transparent circular button used for the top bar
/// icons (back/close and flashlight), matching the design reference.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.4),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/// The green-cornered square frame shown over the camera preview to
/// indicate where the user should position the QR code.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.color});

  final Color color;

  static const double _size = 240;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _CornerFramePainter(color: color),
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  _CornerFramePainter({required this.color});

  final Color color;
  static const double _cornerLength = 28;
  static const double _strokeWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(_cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, _cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width - _cornerLength, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, _cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height),
        Offset(_cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height),
        Offset(0, size.height - _cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - _cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - _cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerFramePainter oldDelegate) => false;
}

/// Friendly error view shown instead of crashing when the camera
/// cannot start (permission denied, no camera, camera busy, etc.).
class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error});

  final MobileScannerException error;

  String get _message {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission was denied.\nPlease allow camera access in your phone settings to scan QR codes.';
      case MobileScannerErrorCode.unsupported:
        return 'QR scanning is not supported on this device.';
      default:
        return 'Could not start the camera.\nPlease try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}