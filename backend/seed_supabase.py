"""
Seed Supabase tables with Kruthi's synthetic data.

Usage:
    export SUPABASE_URL="https://gecottkvhvesjarxrdnu.supabase.co"
    export SUPABASE_KEY="your-service-role-key"
    python backend/seed_supabase.py

Creates and populates:
    - test_qr_data: curated QR codes for Roweena to test with (legit + fraudulent)
    - scan_log: stores results when users scan QRs in the live app
"""

import json
import os
import sys
from pathlib import Path

from supabase import create_client

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://gecottkvhvesjarxrdnu.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_KEY:
    print("ERROR: Set SUPABASE_KEY environment variable")
    print("  export SUPABASE_KEY='your-service-role-key-here'")
    sys.exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

DATA_DIR = Path(__file__).parent.parent / "engine" / "data"


def seed_test_qr_data():
    """
    Table 1: test_qr_data
    Curated QR codes Roweena uses to test the Flutter app.
    Mix of legit and fraudulent for demo purposes.
    """
    with open(DATA_DIR / "qr_registry.json") as f:
        all_qrs = json.load(f)
    with open(DATA_DIR / "merchants.json") as f:
        merchants = json.load(f)

    merchant_map = {m["id"]: m for m in merchants}

    # Pick 10 legit + 10 fraudulent (2 of each fraud type)
    legit = [q for q in all_qrs if not q["is_fraudulent"]][:10]
    fraud_by_type = {}
    for q in all_qrs:
        if q["is_fraudulent"]:
            ft = q["fraud_type"]
            if ft not in fraud_by_type:
                fraud_by_type[ft] = []
            if len(fraud_by_type[ft]) < 2:
                fraud_by_type[ft].append(q)

    fraud = []
    for entries in fraud_by_type.values():
        fraud.extend(entries)

    test_data = []
    for q in legit + fraud:
        merchant = merchant_map.get(q["merchant_id"], {})
        test_data.append({
            "qr_payload": q["qr_payload"],
            "display_name": q.get("display_name", ""),
            "upi_id": q["upi_id"],
            "merchant_id": q["merchant_id"],
            "merchant_name": merchant.get("name", ""),
            "is_fraudulent": q["is_fraudulent"],
            "fraud_type": q.get("fraud_type"),
            "expected_result": "SUSPICIOUS" if q["is_fraudulent"] else "VERIFIED",
        })

    print(f"Seeding test_qr_data with {len(test_data)} entries...")
    # Clear existing data
    supabase.table("test_qr_data").delete().neq("id", 0).execute()
    # Insert
    result = supabase.table("test_qr_data").insert(test_data).execute()
    print(f"  Inserted {len(result.data)} rows")


def verify_scan_log_table():
    """
    Table 2: scan_log
    Just verify it exists (it stores live scan results from the app).
    """
    print("Verifying scan_log table exists...")
    try:
        result = supabase.table("scan_log").select("*").limit(1).execute()
        print("  scan_log table ready")
    except Exception as e:
        print(f"  WARNING: scan_log table might not exist yet: {e}")
        print("  Run the SQL from backend/supabase_schema.sql in your Supabase SQL editor")


if __name__ == "__main__":
    print(f"Connecting to: {SUPABASE_URL}")
    seed_test_qr_data()
    verify_scan_log_table()
    print("\nDone! Roweena can now test with data from test_qr_data table.")
