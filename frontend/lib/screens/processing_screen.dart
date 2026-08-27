import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'result_screen.dart';

/// Processing / Verification screen for Bharosa Pay.
///
/// Receives the raw QR payload, sends it to the backend for verification,
/// and navigates to ResultScreen when the backend responds.
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.qrPayload});

  final String qrPayload;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  static const Color _navy = Color(0xFF102A43);
  static const Color _green = Color(0xFF1FA25A);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  final ApiService _apiService = ApiService();

  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();

    // Start verification after the first frame so that navigation and
    // ScaffoldMessenger operations have a valid BuildContext.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyQr();
    });
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _verifyQr() async {
    if (_hasStarted) return;
    _hasStarted = true;

    try {
      final result = await _apiService.verifyQr(widget.qrPayload);

      if (!mounted) return;

      final classification =
          result['trust_classification'] as String? ?? 'UNKNOWN';

      final trustScore = (result['trust_score'] as num?)?.toInt() ?? 0;

      final merchantName = result['merchant_name'] as String?;

      final rawReasons = result['reasons'];

      final reasons = <ResultReason>[];

      if (rawReasons is List) {
        for (final item in rawReasons) {
          if (item is Map) {
            reasons.add(
              ResultReason(
                signal: item['signal']?.toString() ?? '',
                status: item['status']?.toString() ?? '',
                text: item['text']?.toString() ?? '',
              ),
            );
          }
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            classification: classification,
            trustScore: trustScore,
            merchantName: merchantName,
            reasons: reasons,
            qrPayload: widget.qrPayload,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      _showError(e.message);
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Something went wrong while checking this QR. Please try again.',
      );
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verification failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _hasStarted = false;
                _verifyQr();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

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

              _ShieldWithLoader(
                navy: _navy,
                green: _green,
              ),

              const SizedBox(height: 32),

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

              Text(
                'Please wait while we verify the payment details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _navy.withOpacity(0.7),
                ),
              ),

              const Spacer(flex: 3),

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
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: _green,
                    ),
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

class _ShieldWithLoader extends StatelessWidget {
  const _ShieldWithLoader({
    required this.navy,
    required this.green,
  });

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
              child: Icon(
                Icons.shield,
                size: 48,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}