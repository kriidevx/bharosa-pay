import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static Future<void> openUpiPayment(String qrPayload) async {
    final Uri? uri = Uri.tryParse(qrPayload);

    if (uri == null) {
      throw Exception('Invalid UPI payment link.');
    }

    if (uri.scheme.toLowerCase() != 'upi') {
      throw Exception('This QR does not contain a valid UPI payment link.');
    }

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception('Could not open a UPI payment app.');
    }
  }
}