import 'package:flutter/material.dart';

/// The exact category values the backend accepts for `/report-qr`.
/// These must NEVER be renamed — only the labels shown to the user
/// are friendly text; the value sent later to the backend must stay
/// exactly as defined here.
enum ReportCategory {
  qrAppearsTampered('QR_APPEARS_TAMPERED', 'QR appears tampered'),
  wrongMerchantName('WRONG_MERCHANT_NAME', 'Wrong merchant name'),
  suspiciousAmount('SUSPICIOUS_AMOUNT', 'Suspicious amount'),
  other('OTHER', 'Other');

  const ReportCategory(this.backendValue, this.label);

  /// The exact string the backend expects, e.g. "QR_APPEARS_TAMPERED".
  final String backendValue;

  /// Friendly text shown to the user in the dropdown.
  final String label;
}

/// Lets the user report a QR they believe is suspicious, incorrect,
/// or tampered with.
///
/// This screen only handles UI + local selection state for this
/// stage. It does NOT call ApiService.reportQr() yet — that wiring
/// comes in a later stage once we're ready to connect the real
/// `/report-qr` call using [qrPayload] and the category selected here.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.qrPayload});

  /// The original scanned QR payload. Kept as data only — not shown
  /// prominently on screen — for future API integration.
  final String qrPayload;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Brand colors, kept consistent with the rest of Bharosa Pay.
  static const Color _navy = Color(0xFF102A43);
  static const Color _green = Color(0xFF1FA25A);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  ReportCategory? _selectedCategory;

  /// Whether the form has enough info to allow submission.
  /// A category must be selected before "Submit Report" is enabled.
  bool get _canSubmit => _selectedCategory != null;

  void _onSubmitPressed() {
    if (!_canSubmit) return;

    // TODO: Replace this with the real backend call once wired up:
    //   await ApiService().reportQr(
    //     qrPayload: widget.qrPayload,
    //     category: _selectedCategory!.backendValue,
    //   );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submission will be connected soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        backgroundColor: _lightBackground,
        elevation: 0,
        foregroundColor: _navy,
        title: const Text(
          'Report QR',
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
              const SizedBox(height: 8),

              // --- Icon + explanation ---
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _navy.withOpacity(0.08),
                  ),
                  child: const Icon(Icons.flag_outlined, size: 44, color: _navy),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Help us keep Bharosa Pay users safe by telling us what looks wrong with this QR.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _navy.withOpacity(0.75),
                ),
              ),

              const SizedBox(height: 28),

              // --- Category dropdown ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "What's wrong with this QR?",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _navy.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _navy.withOpacity(0.15)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: Text(
                      'Choose a category',
                      style: TextStyle(color: _navy.withOpacity(0.5)),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down, color: _navy),
                    items: ReportCategory.values.map((category) {
                      return DropdownMenuItem<ReportCategory>(
                        value: category,
                        child: Text(
                          category.label,
                          style: const TextStyle(fontSize: 15, color: _navy),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                ),
              ),

              // Clear hint if nothing is selected yet, so the user
              // understands why the button below is disabled.
              if (_selectedCategory == null) ...[
                const SizedBox(height: 6),
                Text(
                  'Please select a category to continue.',
                  style: TextStyle(fontSize: 12, color: _navy.withOpacity(0.5)),
                ),
              ],

              const SizedBox(height: 28),

              // --- Submit button ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _onSubmitPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: _navy.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Reassurance ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: _green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This report is only about the QR/payment information. Bharosa Pay does not process or store your actual payment.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _navy.withOpacity(0.7),
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