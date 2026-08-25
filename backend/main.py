"""
Bharosa Pay — Backend API (Track 2: Likhith)

FastAPI service with Supabase (Postgres) implementing the shared contract:
- POST /verify-qr
- POST /report-qr
- GET /stats

Setup:
1. Create a Supabase project at https://supabase.com
2. Create tables as defined in CONTRACT.md (merchants, qr_registry, reports, scan_stats)
3. Seed merchants and qr_registry from engine/data/*.json
4. Set env vars: SUPABASE_URL, SUPABASE_KEY

Dependencies:
    pip install fastapi uvicorn supabase python-dotenv
"""

# TODO(Likhith): Implement endpoints per CONTRACT.md
#
# from fastapi import FastAPI
# from supabase import create_client
# from engine import verify_qr
# import os
#
# app = FastAPI(title="Bharosa Pay API")
# supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
#
# @app.post("/verify-qr")
# async def verify_qr_endpoint(payload: dict):
#     result = verify_qr(payload["qr_payload"])
#     # Increment scan_stats in Supabase
#     return result
#
# @app.post("/report-qr")
# async def report_qr_endpoint(payload: dict):
#     # Insert into reports table in Supabase
#     return {"status": "received"}
#
# @app.get("/stats")
# async def get_stats():
#     # Read from scan_stats + recent reports in Supabase
#     return {...}
