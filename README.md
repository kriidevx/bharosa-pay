# Bharosa Pay

**QR Code Trust Verification System** — Scan any UPI QR code and instantly know if it's safe to pay.

## Team

| Track | Owner | Responsibility |
|-------|-------|----------------|
| 1 | Kruthi | Scoring & Explainability Engine |
| 2 | Likhith | Backend API (FastAPI) |
| 3 | Roweena | Mobile/Frontend QR Scanner |
| 4 | Aaradhya | Validation, Dashboard & Deployment |

## Project Structure

```
bharosa-pay/
├── CONTRACT.md          # Shared API contract (read first)
├── engine/              # Track 1: Scoring engine (Kruthi)
│   ├── generate_data.py # Synthetic merchant/QR dataset generator
│   ├── scorer.py        # Rule-based trust scoring
│   ├── explain.py       # Plain-language reason generation
│   └── __init__.py      # Exposes verify_qr()
├── backend/             # Track 2: FastAPI service (Likhith)
│   ├── main.py
│   ├── models.py
│   └── requirements.txt
├── frontend/            # Track 3: QR Scanner web app (Roweena)
├── dashboard/           # Track 4: Streamlit analytics (Aaradhya)
│   └── app.py
├── tests/               # Track 4: Adversarial test suite (Aaradhya)
│   └── test_scenarios.py
└── docker-compose.yml   # Track 4: Full-stack deployment
```

## Quick Start

```bash
# 1. Set up Python environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Generate synthetic data (Kruthi's engine)
python -m engine.generate_data

# 3. Run the backend (Likhith's API)
cd backend && uvicorn main:app --reload

# 4. Run the dashboard (Aaradhya)
cd dashboard && streamlit run app.py
```

## API Contract

See [CONTRACT.md](./CONTRACT.md) for the full shared API specification.
