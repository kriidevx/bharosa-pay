import 'package:flutter/material.dart';

import '../services/payment_service.dart';
import 'report_screen.dart';
import 'scanner_screen.dart';

/// A single reason/signal returned by the backend for a QR result.
class ResultReason {
  const ResultReason({
    required this.signal,
    required this.status,
    required this.text,
  });

  final String signal;
  final String status;
  final String text;
}

/// Displays the verification result for a scanned QR.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.classification,
    required this.trustScore,
    required this.merchantName,
    required this.reasons,
    required this.qrPayload,
  });

  final String classification;
  final int trustScore;
  final String? merchantName;
  final List<ResultReason> reasons;

  /// Original raw UPI QR payload.
  final String qrPayload;

  static const Color _navy = Color(0xFF102A43);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  static const Color _verifiedColor = Color(0xFF1FA25A);
  static const Color _cautionColor = Color(0xFFE58A00);
  static const Color _suspiciousColor = Color(0xFFD8342A);

  /// Visual configuration based on the backend classification.
  _StateVisuals get _visuals {
    switch (classification) {
      case 'VERIFIED':
        return _StateVisuals(
          color: _verifiedColor,
          icon: Icons.verified,
          title: 'VERIFIED',
          subtitle: 'This QR is Safe to Pay',
        );

      case 'CAUTION':
        return _StateVisuals(
          color: _cautionColor,
          icon: Icons.warning_amber_rounded,
          title: 'CAUTION',
          subtitle: 'Proceed with Caution',
        );

      case 'SUSPICIOUS':
        return _StateVisuals(
          color: _suspiciousColor,
          icon: Icons.gpp_bad,
          title: 'SUSPICIOUS',
          subtitle: "We don't recommend paying",
        );

      default:
        return _StateVisuals(
          color: _navy,
          icon: Icons.help_outline,
          title: classification,
          subtitle: 'Unknown result',
        );
    }
  }

  /// Opens the UPI payment application using the original QR payload.
  Future<void> _openPayment(BuildContext context) async {
    try {
      await PaymentService.openUpiPayment(qrPayload);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  /// Shows an explicit confirmation before allowing payment
  /// for a QR classified as CAUTION.
  Future<void> _payAnyway(BuildContext context) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Proceed with payment?'),
          content: const Text(
            'Bharosa Pay found some unusual details in this QR. '
            'Please make sure the merchant name and payment amount '
            'are correct before continuing.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cautionColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay Anyway'),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true && context.mounted) {
      await _openPayment(context);
    }
  }

  /// Opens the scanner for another QR.
  void _scanAnother(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const ScannerScreen(),
    ),
  );
}

  /// Opens the QR reporting screen.
  void _reportQr(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          qrPayload: qrPayload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _visuals;

    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        backgroundColor: _lightBackground,
        elevation: 0,
        foregroundColor: _navy,
        title: const Text(
          'Bharosa Pay',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.06,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -----------------------------
              // STATUS HEADER
              // -----------------------------
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: visuals.color.withOpacity(0.12),
                      ),
                      child: Icon(
                        visuals.icon,
                        size: 48,
                        color: visuals.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      visuals.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: visuals.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visuals.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: _navy.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // -----------------------------
              // TRUST SCORE
              // -----------------------------
              _InfoCard(
                accentColor: visuals.color,
                child: Column(
                  children: [
                    Text(
                      'Trust Score',
                      style: TextStyle(
                        fontSize: 13,
                        color: _navy.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$trustScore / 100',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: visuals.color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -----------------------------
              // MERCHANT NAME
              // -----------------------------
              _InfoCard(
                accentColor: _navy,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 20,
                      color: _navy,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merchant Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: _navy.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            merchantName ?? 'Unknown / Not available',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -----------------------------
              // REASONS
              // -----------------------------
              if (reasons.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Why is this QR ${classification.toLowerCase()}?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _InfoCard(
                  accentColor: _navy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < reasons.length; i++) ...[
                        if (i > 0) const Divider(height: 20),
                        _ReasonRow(
                          reason: reasons[i],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // -----------------------------
              // CAUTION WARNING
              // -----------------------------
              if (classification == 'CAUTION')
                const _WarningBanner(
                  color: _cautionColor,
                  icon: Icons.info_outline,
                  message:
                      'Some details about this QR look unusual. '
                      'Please review carefully before proceeding.',
                ),

              // -----------------------------
              // SUSPICIOUS WARNING
              // -----------------------------
              if (classification == 'SUSPICIOUS')
                const _WarningBanner(
                  color: _suspiciousColor,
                  icon: Icons.block,
                  message:
                      'This QR shows strong signs of risk. '
                      'Payment has been blocked to keep you safe.',
                ),

              const SizedBox(height: 24),

              // -----------------------------
              // ACTION BUTTONS
              // -----------------------------
              ..._buildActions(
                context,
                visuals,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds actions according to the backend classification.
  List<Widget> _buildActions(
    BuildContext context,
    _StateVisuals visuals,
  ) {
    switch (classification) {
      // -------------------------------------
      // VERIFIED
      // -------------------------------------
      case 'VERIFIED':
        return [
          _PrimaryButton(
            label: 'Pay Now',
            color: visuals.color,
            onPressed: () => _openPayment(context),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Scan Another QR',
            onPressed: () => _scanAnother(context),
          ),
        ];

      // -------------------------------------
      // CAUTION
      // -------------------------------------
      case 'CAUTION':
        return [
          _PrimaryButton(
            label: 'Pay Anyway',
            color: visuals.color,
            onPressed: () => _payAnyway(context),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Report QR',
            onPressed: () => _reportQr(context),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Scan Another QR',
            onPressed: () => _scanAnother(context),
          ),
        ];

      // -------------------------------------
      // SUSPICIOUS
      // -------------------------------------
      case 'SUSPICIOUS':
        return [
          _PrimaryButton(
            label: 'Report QR',
            color: visuals.color,
            onPressed: () => _reportQr(context),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Scan Another QR',
            onPressed: () => _scanAnother(context),
          ),
        ];

      // -------------------------------------
      // UNKNOWN
      // -------------------------------------
      default:
        return [
          _SecondaryButton(
            label: 'Scan Another QR',
            onPressed: () => _scanAnother(context),
          ),
        ];
    }
  }
}

/// Bundles visual properties for a classification.
class _StateVisuals {
  const _StateVisuals({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
}

/// Rounded information card.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.child,
    required this.accentColor,
  });

  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Displays one backend-provided reason.
class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
  });

  final ResultReason reason;

  IconData get _icon {
    switch (reason.status) {
      case 'positive':
        return Icons.check_circle;
      case 'negative':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color get _color {
    switch (reason.status) {
      case 'positive':
        return const Color(0xFF1FA25A);
      case 'negative':
        return const Color(0xFFD8342A);
      default:
        return const Color(0xFF102A43);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _icon,
          size: 18,
          color: _color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reason.text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF102A43),
            ),
          ),
        ),
      ],
    );
  }
}

/// Warning banner.
class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width filled primary button.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined secondary button.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF102A43),
          side: BorderSide(
            color: const Color(0xFF102A43).withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}