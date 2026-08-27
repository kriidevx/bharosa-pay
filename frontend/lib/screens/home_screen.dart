import 'package:flutter/material.dart';

import 'scanner_screen.dart';

/// Home / Welcome screen for Bharosa Pay.
///
/// This is the very first screen the user sees. It introduces the app
/// and provides the single primary action: "Scan QR Code".
///
/// This file only contains UI — no scanning, no API calls, no payment
/// logic. Those live in their own files later.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Brand colors, matched to the approved design reference.
  // Kept as constants here (instead of a separate theme file) since
  // this screen is currently self-contained.
  static const Color _navy = Color(0xFF102A43);
  static const Color _green = Color(0xFF1FA25A);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  /// Navigates to the QR scanner screen.
  void _onScanQrPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      body: SafeArea(
        child: Padding(
          // Responsive horizontal padding: a fraction of screen width
          // instead of a fixed pixel value, so this looks reasonable
          // on both small and large Android screens.
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.08,
            vertical: 24,
          ),
          child: Column(
            children: [
              // Pushes the branding block toward vertical center,
              // leaving the CTA anchored near the bottom.
              const Spacer(flex: 3),

              // --- Branding block ---
              _ShieldIcon(navy: _navy, green: _green),
              const SizedBox(height: 24),
              const Text(
                'BHAROSA PAY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan. Verify. Pay Safe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _navy.withOpacity(0.7),
                ),
              ),

              const Spacer(flex: 4),

              // --- Primary action ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _onScanQrPressed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Security reassurance ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: _green),
                  const SizedBox(width: 6),
                  Text(
                    'Secure • Private • Safe',
                    style: TextStyle(
                      fontSize: 13,
                      color: _navy.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple shield visual built from built-in Material icons only —
/// no external image asset required.
class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.navy, required this.green});

  final Color navy;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: green.withOpacity(0.12),
      ),
      child: Center(
        child: Icon(
          Icons.shield,
          size: 64,
          color: navy,
        ),
      ),
    );
  }
}