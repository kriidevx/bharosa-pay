# Bharosa Pay

**QR Code Trust Verification System** — Scan any UPI QR code and instantly know if it's safe to pay.

## Team

| Track | Owner | Responsibility |
|-------|-------|----------------|
| 1 | Kruthi | Scoring & Explainability Engine |
| 2 | Likhith | Backend API (FastAPI + Supabase) |
| 3 | Roweena | Flutter QR Scanner App |
| 4 | Aaradhya | Validation, Dashboard & Deployment |

## Tech Stack

- **Engine:** Python, pandas, NetworkX (graph anomaly detection)
- **Backend:** FastAPI, Supabase (Postgres), Python
- **Mobile:** Flutter (Dart)
- **Dashboard:** Streamlit + Supabase real-time
- **Deployment:** Docker Compose

## Project Structure

```
bharosa-pay/
├── CONTRACT.md          # Shared API contract (read first)
├── engine/              # Track 1: Scoring engine (Kruthi)
│   ├── generate_data.py # Synthetic merchant/QR dataset generator
│   ├── scorer.py        # Rule-based trust scoring
│   ├── explain.py       # Plain-language reason generation
│   ├── graph_analyzer.py# NetworkX graph anomaly detection
│   └── __init__.py      # Exposes verify_qr()
├── backend/             # Track 2: FastAPI + Supabase (Likhith)
│   └── main.py
├── frontend/            # Track 3: Flutter app (Roweena)
├── dashboard/           # Track 4: Streamlit analytics (Aaradhya)
│   └── app.py
├── tests/               # Track 4: Adversarial test suite (Aaradhya)
│   └── test_scenarios.py
└── docker-compose.yml   # Track 4: Full-stack deployment
```

## Quick Start

```bash
# 1. Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Generate synthetic data (Kruthi's engine)
python -m engine.generate_data

# 3. Seed Supabase (Likhith)
# Upload engine/data/merchants.json and engine/data/qr_registry.json to Supabase tables

# 4. Run the backend (Likhith's API)
cd backend && uvicorn main:app --reload

# 5. Run Flutter app (Roweena)
cd frontend && flutter run

# 6. Run the dashboard (Aaradhya)
cd dashboard && streamlit run app.py
```

## API Contract

See [CONTRACT.md](./CONTRACT.md) for the full shared API specification and Supabase table schemas.
