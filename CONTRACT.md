# Bharosa Pay — Shared API Contract

Agreed upon before any code is written. All tracks build against this contract.

**Stack:** FastAPI + Supabase (Postgres) + Flutter + Streamlit

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

## Tech Stack

| Layer | Technology | Owner |
|-------|-----------|-------|
| Scoring Engine | Python (pandas, NetworkX) | Kruthi |
| Backend API | FastAPI + Supabase (Postgres) | Likhith |
| Database | Supabase (hosted Postgres + real-time) | Likhith |
| Mobile App | Flutter (Dart) | Roweena |
| Dashboard | Streamlit (can also use Supabase real-time) | Aaradhya |
| Deployment | Docker Compose / Supabase hosted | Aaradhya |

---

## Architecture

```
Kruthi's engine  ──imported by──►  Likhith's API (FastAPI + Supabase)
                                        │
                                        ├──called by──►  Roweena's Flutter app
                                        │
                                        └──feeds /stats──►  Aaradhya's dashboard

Supabase handles:
  - Merchant table (seeded from Kruthi's dataset)
  - QR Registry table
  - Reports table (user submissions)
  - Scan stats (running counts)
  - Real-time subscriptions (dashboard can listen live)

Aaradhya's test suite validates the whole pipeline (Kruthi + Likhith combined)
Aaradhya's Docker setup packages the backend for deployment
```

---

## Supabase Tables

### `merchants`
| Column | Type | Notes |
|--------|------|-------|
| id | text (PK) | e.g. "M0001" |
| name | text | |
| upi_id | text (unique) | |
| city | text | |
| business_type | text | |
| is_verified | boolean | |
| registered_since | date | |
| total_transactions | integer | |
| report_count | integer | default 0 |

### `qr_registry`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid (PK) | auto-generated |
| merchant_id | text (FK → merchants) | |
| upi_id | text | |
| display_name | text | |
| amount | numeric | nullable |
| is_fraudulent | boolean | |
| fraud_type | text | nullable |
| qr_payload | text | |

### `reports`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid (PK) | auto-generated |
| qr_payload | text | |
| category | text | enum values above |
| created_at | timestamptz | default now() |

### `scan_stats`
| Column | Type | Notes |
|--------|------|-------|
| id | integer (PK) | single row, id=1 |
| total_scans | integer | |
| verified_count | integer | |
| caution_count | integer | |
| suspicious_count | integer | |
