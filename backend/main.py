"""
Bharosa Pay — Backend API
FastAPI + Supabase + Kruthi's scoring engine
"""

import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client

# Add project root to path so engine is importable
project_root = str(Path(__file__).parent.parent)
if project_root not in sys.path:
    sys.path.insert(0, project_root)
from engine import verify_qr

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://gecottkvhvesjarxrdnu.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "sb_publishable_11rI87O9R_UFbdbeng0mcQ_yrr57jhZ")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI(
    title="Bharosa Pay API",
    description="QR Code Trust Verification System",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class VerifyRequest(BaseModel):
    qr_payload: str


class ReportRequest(BaseModel):
    qr_payload: str
    category: str


@app.post("/verify-qr")
async def verify_qr_endpoint(req: VerifyRequest):
    if not req.qr_payload.startswith("upi://pay?"):
        raise HTTPException(status_code=400, detail="Invalid UPI QR payload")

    result = verify_qr(req.qr_payload)

    # Log scan to Supabase
    try:
        supabase.table("scan_log").insert({
            "qr_payload": req.qr_payload,
            "trust_score": result["trust_score"],
            "trust_classification": result["trust_classification"],
            "merchant_name": result["merchant_name"],
            "reasons": result["reasons"],
        }).execute()
    except Exception:
        pass  # Don't fail the request if logging fails

    return result


@app.post("/report-qr")
async def report_qr_endpoint(req: ReportRequest):
    valid_categories = [
        "QR_APPEARS_TAMPERED",
        "WRONG_MERCHANT_NAME",
        "SUSPICIOUS_AMOUNT",
        "OTHER",
    ]
    if req.category not in valid_categories:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid category. Must be one of: {valid_categories}",
        )

    try:
        supabase.table("reports").insert({
            "qr_payload": req.qr_payload,
            "category": req.category,
        }).execute()
    except Exception:
        pass  # Table might not exist yet, still return success

    return {"status": "received"}


@app.get("/stats")
async def get_stats():
    try:
        scans = supabase.table("scan_log").select("*", count="exact").execute()
        total = scans.count or 0
        verified = sum(1 for s in scans.data if s["trust_classification"] == "VERIFIED")
        caution = sum(1 for s in scans.data if s["trust_classification"] == "CAUTION")
        suspicious = sum(1 for s in scans.data if s["trust_classification"] == "SUSPICIOUS")

        recent_reports = []
        try:
            reports = supabase.table("reports").select("*").order("created_at", desc=True).limit(10).execute()
            recent_reports = reports.data
        except Exception:
            pass

        return {
            "total_scans": total,
            "verified_count": verified,
            "caution_count": caution,
            "suspicious_count": suspicious,
            "recent_reports": recent_reports,
        }
    except Exception:
        return {
            "total_scans": 0,
            "verified_count": 0,
            "caution_count": 0,
            "suspicious_count": 0,
            "recent_reports": [],
        }


@app.get("/health")
async def health():
    return {"status": "ok", "engine": "active"}
