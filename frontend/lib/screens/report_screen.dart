import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  /// The exact string the backend expects.
  final String backendValue;

  /// Friendly text shown to the user.
  final String label;
}

/// Lets the user report a QR they believe is suspicious,
/// incorrect, or tampered with.
class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.qrPayload,
  });

  /// The original scanned QR payload.
  final String qrPayload;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Brand colors.
  static const Color _navy = Color(0xFF102A43);
  static const Color _green = Color(0xFF1FA25A);
  static const Color _lightBackground = Color(0xFFF7F9FC);

  ReportCategory? _selectedCategory;

  final ApiService _apiService = ApiService();

  bool _isSubmitting = false;

  /// A category must be selected before submission is allowed.
  bool get _canSubmit => _selectedCategory != null;

  /// Sends the report to the backend.
  Future<void> _onSubmitPressed() async {
    // Prevent submission without a category or while already submitting.
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.reportQr(
        qrPayload: widget.qrPayload,
        category: _selectedCategory!.backendValue,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully.'),
        ),
      );

      // Return to the result screen after successful submission.
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while submitting your report.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
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
                  child: const Icon(
                    Icons.flag_outlined,
                    size: 44,
                    color: _navy,
                  ),
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
                  border: Border.all(
                    color: _navy.withOpacity(0.15),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: Text(
                      'Choose a category',
                      style: TextStyle(
                        color: _navy.withOpacity(0.5),
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: _navy,
                    ),
                    items: ReportCategory.values.map((category) {
                      return DropdownMenuItem<ReportCategory>(
                        value: category,
                        child: Text(
                          category.label,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _navy,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                  ),
                ),
              ),

              // --- Selection hint ---
              if (_selectedCategory == null) ...[
                const SizedBox(height: 6),
                Text(
                  'Please select a category to continue.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _navy.withOpacity(0.5),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // --- Submit button ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _canSubmit && !_isSubmitting
                          ? _onSubmitPressed
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: _navy.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Reassurance ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: _green,
                    ),
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