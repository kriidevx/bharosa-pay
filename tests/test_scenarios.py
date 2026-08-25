"""
Adversarial test suite (Track 4: Aaradhya)

Edge-case QR scenarios:
- Exact merchant match (should be VERIFIED)
- Close-but-wrong UPI ID (should be SUSPICIOUS)
- Unregistered merchant (should be SUSPICIOUS/CAUTION)
- High report-count QR (should be SUSPICIOUS)
- Geographically impossible scan pattern

Usage:
    pytest tests/test_scenarios.py -v
"""

# TODO(Aaradhya): Write structured edge-case scenarios
# from engine import verify_qr
