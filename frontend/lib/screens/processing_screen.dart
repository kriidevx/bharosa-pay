import 'package:flutter/material.dart';

/// Processing / Verification screen for Bharosa Pay.
///
/// Shown right after a QR is scanned, while Bharosa Pay is (in a later
/// stage) checking it with the backend. For now this is a static
/// loading UI only — no API call, no trust score, no navigation.
///
/// This screen does not simulate fake progress or a fake result; it
/// simply communicates "we are checking this QR, payment has not
/// happened yet." Real backend integration comes in a later stage.
class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key, required this.qrPayload});

  /// The original raw QR string, preserved exactly as scanned.
  /// Not displayed in the UI at this stage — kept only so a future
  /// stage can pass it to ApiService.verifyQr(qrPayload).
  final String qrPayload;

  // Brand colors, kept consistent with HomeScreen and ScannerScreen.
  static const Color _navy = Color(0xFF102A43);
  static const Color _green = Color(0xFF1FA25A);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.08,
            vertical: 24,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // --- Branding ---
              const Text(
                'BHAROSA PAY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: _navy,
                ),
              ),

              const Spacer(flex: 2),

              // --- Shield visual with loading ring around it ---
              _ShieldWithLoader(navy: _navy, green: _green),

              const SizedBox(height: 32),

              // --- Heading ---
              const Text(
                'Checking this QR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),

              // --- Supporting text ---
              Text(
                'Please wait while we verify the payment details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _navy.withOpacity(0.7),
                ),
              ),

              const Spacer(flex: 3),

              // --- Security reassurance ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: _green),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Your payment hasn't been made yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _navy.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular progress indicator wrapped around a shield icon,
/// visually tying the loading state to Bharosa Pay's security branding.
class _ShieldWithLoader extends StatelessWidget {
  const _ShieldWithLoader({required this.navy, required this.green});

  final Color navy;
  final Color green;

  static const double _size = 120;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(green),
              backgroundColor: green.withOpacity(0.15),
            ),
          ),
          Container(
            width: _size - 28,
            height: _size - 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withOpacity(0.12),
            ),
            child: Center(
              child: Icon(Icons.shield, size: 48, color: navy),
            ),
          ),
        ],
      ),
    );
  }
}