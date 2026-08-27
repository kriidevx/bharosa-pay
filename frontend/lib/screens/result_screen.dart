import 'package:flutter/material.dart';

import 'report_screen.dart';
import 'scanner_screen.dart';

/// A single reason/signal returned by the backend for a QR result.
///
/// This is a lightweight local representation only — it will later be
/// replaced by whatever `models/verification_result.dart` defines.
/// Nothing here invents, reorders, or reinterprets backend text.
class ResultReason {
  const ResultReason({
    required this.signal,
    required this.status,
    required this.text,
  });

  /// Short label for the signal, e.g. "Merchant verified".
  final String signal;

  /// Backend-provided status string, e.g. "positive" or "negative".
  /// Used only to pick an icon/color — not to decide anything.
  final String status;

  /// Full explanation text, shown exactly as returned by the backend.
  final String text;
}

/// Displays the verification result for a scanned QR.
///
/// Bharosa Pay's backend is the only source of truth for
/// [classification] and [trustScore] — this screen only renders
/// whatever it is given. It does not calculate, guess, or override
/// any of these values.
///
/// [classification] is expected to be one of:
///   "VERIFIED", "CAUTION", "SUSPICIOUS"
/// exactly as returned by the backend.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.classification,
    required this.trustScore,
    required this.merchantName,
    required this.reasons,
    required this.qrPayload,
    this.onPayNow,
    this.onPayAnyway,
  });

  final String classification;
  final int trustScore;
  final String? merchantName;
  final List<ResultReason> reasons;
  final String qrPayload;

  /// TODO: Replace with real UPI payment-app redirection once
  /// payment_service.dart exists. Currently a placeholder callback.
  final VoidCallback? onPayNow;

  /// TODO: Replace with real UPI payment-app redirection once
  /// payment_service.dart exists. Currently a placeholder callback.
  final VoidCallback? onPayAnyway;

  // Brand colors, kept consistent with Home/Scanner/Processing.
  static const Color _navy = Color(0xFF102A43);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  static const Color _verifiedColor = Color(0xFF1FA25A);
  static const Color _cautionColor = Color(0xFFE58A00);
  static const Color _suspiciousColor = Color(0xFFD8342A);

  /// Visual configuration for each of the three backend-driven states.
  /// This only maps a given classification string to presentation —
  /// it never decides which classification applies.
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
        // Defensive fallback only — the backend contract guarantees
        // one of the three values above. This is not scoring logic,
        // just a safe display fallback if something unexpected arrives.
        return _StateVisuals(
          color: _navy,
          icon: Icons.help_outline,
          title: classification,
          subtitle: 'Unknown result',
        );
    }
  }

  void _showNotConnectedYet(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action is not connected yet.')),
    );
  }

  /// Navigates to the scanner so the user can scan a new QR.
  void _scanAnother(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  /// Navigates to ReportScreen, passing the original qrPayload
  /// unchanged.
  void _reportQr(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(qrPayload: qrPayload),
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
              // --- Status header ---
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
                      child: Icon(visuals.icon, size: 48, color: visuals.color),
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

              // --- Trust score card ---
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

              // --- Merchant name card ---
              _InfoCard(
                accentColor: _navy,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 20, color: _navy),
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

              // --- Reasons ---
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
                        _ReasonRow(reason: reasons[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- Classification-specific warning banner ---
              if (classification == 'CAUTION')
                _WarningBanner(
                  color: _cautionColor,
                  icon: Icons.info_outline,
                  message:
                      'Some details about this QR look unusual. Please review carefully before proceeding.',
                ),
              if (classification == 'SUSPICIOUS')
                _WarningBanner(
                  color: _suspiciousColor,
                  icon: Icons.block,
                  message:
                      'This QR shows strong signs of risk. Payment has been blocked to keep you safe.',
                ),

              const SizedBox(height: 24),

              // --- Actions, based on classification ---
              ..._buildActions(context, visuals),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the action buttons appropriate for the given classification.
  /// This only changes what buttons are SHOWN based on the value the
  /// backend already provided — it does not decide the classification
  /// itself.
  List<Widget> _buildActions(BuildContext context, _StateVisuals visuals) {
    switch (classification) {
      case 'VERIFIED':
        return [
          _PrimaryButton(
            label: 'Pay Now',
            color: visuals.color,
            // Still a clearly marked placeholder — payment integration
            // is not implemented yet.
            onPressed: onPayNow ?? () => _showNotConnectedYet(context, 'Pay Now'),
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Scan Another QR',
            onPressed: () => _scanAnother(context),
          ),
        ];

      case 'CAUTION':
        return [
          _PrimaryButton(
            label: 'Pay Anyway',
            color: visuals.color,
            // Still a clearly marked placeholder — payment integration
            // is not implemented yet.
            onPressed:
                onPayAnyway ?? () => _showNotConnectedYet(context, 'Pay Anyway'),
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

      case 'SUSPICIOUS':
        return [
          // No Pay Now / Pay Anyway button here — payment must never
          // be offered in the suspicious state.
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

/// Bundles the icon/color/title/subtitle used to present a
/// classification, purely for display purposes.
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

/// A rounded white card with a thin accent-colored left border,
/// used to present the score, merchant, and reasons sections.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child, required this.accentColor});

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
          left: BorderSide(color: accentColor, width: 4),
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

/// Renders a single backend-provided reason exactly as given —
/// no reordering, rewriting, or reinterpreting of the text.
class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.reason});

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
        Icon(_icon, size: 18, color: _color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reason.text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF102A43)),
          ),
        ),
      ],
    );
  }
}

/// A colored warning banner used for CAUTION/SUSPICIOUS states.
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
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width filled primary action button.
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Full-width outlined secondary action button.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

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
          side: BorderSide(color: const Color(0xFF102A43).withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}