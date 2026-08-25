# Bharosa Pay — Shared API Contract

Agreed upon before any code is written. All tracks build against this contract.

---

## `POST /verify-qr`

### Request

```json
{
  "qr_payload": "upi://pay?pa=abc@upi&pn=ABC%20Restaurant&am=250&cu=INR"
}
```

### Response

```json
{
  "trust_classification": "VERIFIED | CAUTION | SUSPICIOUS",
  "trust_score": 0-100,
  "merchant_name": "ABC Restaurant Bangalore",
  "reasons": [
    {
      "signal": "Merchant verified",
      "status": "positive",
      "text": "This merchant is registered and matches known records."
    },
    {
      "signal": "UPI ID mismatch",
      "status": "negative",
      "text": "Scanned ID does not match registered merchant UPI."
    }
  ]
}
```

**Classification thresholds:**
- `VERIFIED`: trust_score >= 70
- `CAUTION`: 40 <= trust_score < 70
- `SUSPICIOUS`: trust_score < 40

---

## `POST /report-qr`

### Request

```json
{
  "qr_payload": "upi://pay?pa=abc@upi&pn=ABC%20Restaurant&am=250&cu=INR",
  "category": "QR_APPEARS_TAMPERED"
}
```

**Valid categories:** `QR_APPEARS_TAMPERED`, `WRONG_MERCHANT_NAME`, `SUSPICIOUS_AMOUNT`, `OTHER`

### Response

```json
{
  "status": "received"
}
```

---

## `GET /stats`

### Response

```json
{
  "total_scans": 142,
  "verified_count": 118,
  "suspicious_count": 15,
  "caution_count": 9,
  "recent_reports": [
    {
      "qr_payload": "upi://pay?pa=...",
      "category": "QR_APPEARS_TAMPERED",
      "timestamp": "2026-08-25T10:30:00Z"
    }
  ]
}
```

---

## Architecture

```
Kruthi's engine  ──imported by──►  Likhith's API  ──called by──►  Roweena's app
                                        │
                                        └──feeds /stats into──►  Aaradhya's dashboard

Aaradhya's test suite validates the whole pipeline (Kruthi + Likhith combined)
Aaradhya's Docker setup packages the whole pipeline for deployment
```
