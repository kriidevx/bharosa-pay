"""
Rule-based trust scoring engine.

Takes a QR payload, analyses signals, and returns a trust score (0-100)
with classification (VERIFIED/CAUTION/SUSPICIOUS).
"""

import json
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

from .explain import generate_reasons
from .graph_analyzer import get_upi_risk_from_graph

DATA_DIR = Path(__file__).parent / "data"

_merchants_cache: list[dict] | None = None
_qr_registry_cache: list[dict] | None = None


def _load_merchants() -> list[dict]:
    global _merchants_cache
    if _merchants_cache is None:
        path = DATA_DIR / "merchants.json"
        with open(path) as f:
            _merchants_cache = json.load(f)
    return _merchants_cache


def _load_qr_registry() -> list[dict]:
    global _qr_registry_cache
    if _qr_registry_cache is None:
        path = DATA_DIR / "qr_registry.json"
        with open(path) as f:
            _qr_registry_cache = json.load(f)
    return _qr_registry_cache


def parse_qr_payload(qr_payload: str) -> dict:
    """Parse a UPI QR payload string into components."""
    parsed = urlparse(qr_payload)
    params = parse_qs(parsed.query)

    return {
        "pa": params.get("pa", [None])[0],       # payee address (UPI ID)
        "pn": unquote(params.get("pn", [""])[0]), # payee name
        "am": params.get("am", [None])[0],        # amount
        "cu": params.get("cu", ["INR"])[0],       # currency
    }


def _find_merchant_by_upi(upi_id: str) -> dict | None:
    """Look up a merchant by UPI ID."""
    merchants = _load_merchants()
    for m in merchants:
        if m["upi_id"] == upi_id:
            return m
    return None


def _find_merchant_by_name(name: str) -> dict | None:
    """Fuzzy match merchant by display name."""
    merchants = _load_merchants()
    name_lower = name.lower().strip()
    for m in merchants:
        if m["name"].lower().strip() == name_lower:
            return m
    return None


# Signal weights: (signal_name, condition_met_delta, condition_failed_delta)
SIGNAL_TABLE = {
    "merchant_registered": (+20, -25),
    "upi_id_match": (+15, -30),
    "name_match": (+10, -15),
    "low_report_count": (+5, -20),
    "high_transaction_volume": (+10, -5),
    "reasonable_amount": (+5, -10),
    "verified_status": (+10, -15),
}

BASE_SCORE = 50
VERIFIED_THRESHOLD = 70
CAUTION_THRESHOLD = 40


def classify(score: int) -> str:
    if score >= VERIFIED_THRESHOLD:
        return "VERIFIED"
    elif score >= CAUTION_THRESHOLD:
        return "CAUTION"
    else:
        return "SUSPICIOUS"


def score_qr(qr_payload: str) -> dict:
    """
    Score a QR payload and return signals with their status.

    Returns:
        {
            "trust_score": int,
            "trust_classification": str,
            "merchant_name": str,
            "signals": [{"signal": str, "status": "positive"|"negative", "fired": bool}, ...]
        }
    """
    parsed = parse_qr_payload(qr_payload)
    upi_id = parsed["pa"]
    display_name = parsed["pn"]
    amount = parsed["am"]

    score = BASE_SCORE
    signals = []

    # Signal 1: Is the UPI ID registered to a known merchant?
    merchant_by_upi = _find_merchant_by_upi(upi_id)
    if merchant_by_upi:
        score += SIGNAL_TABLE["merchant_registered"][0]
        signals.append({"signal": "merchant_registered", "status": "positive"})
    else:
        score += SIGNAL_TABLE["merchant_registered"][1]
        signals.append({"signal": "merchant_registered", "status": "negative"})

    # Signal 2: Does UPI ID match the display name's merchant?
    merchant_by_name = _find_merchant_by_name(display_name)
    if merchant_by_upi and merchant_by_name and merchant_by_upi["id"] == merchant_by_name["id"]:
        score += SIGNAL_TABLE["upi_id_match"][0]
        signals.append({"signal": "upi_id_match", "status": "positive"})
    elif merchant_by_upi and merchant_by_name:
        score += SIGNAL_TABLE["upi_id_match"][1]
        signals.append({"signal": "upi_id_match", "status": "negative"})
    else:
        signals.append({"signal": "upi_id_match", "status": "negative" if merchant_by_name else "neutral"})
        if merchant_by_name and not merchant_by_upi:
            score += SIGNAL_TABLE["upi_id_match"][1]

    # Signal 3: Name consistency check
    if merchant_by_upi and display_name:
        if merchant_by_upi["name"].lower().strip() == display_name.lower().strip():
            score += SIGNAL_TABLE["name_match"][0]
            signals.append({"signal": "name_match", "status": "positive"})
        else:
            score += SIGNAL_TABLE["name_match"][1]
            signals.append({"signal": "name_match", "status": "negative"})
    elif not merchant_by_upi:
        signals.append({"signal": "name_match", "status": "negative"})
        score += SIGNAL_TABLE["name_match"][1]

    # Signal 4: Report count
    target_merchant = merchant_by_upi or merchant_by_name
    if target_merchant:
        if target_merchant["report_count"] <= 1:
            score += SIGNAL_TABLE["low_report_count"][0]
            signals.append({"signal": "low_report_count", "status": "positive"})
        else:
            score += SIGNAL_TABLE["low_report_count"][1]
            signals.append({"signal": "low_report_count", "status": "negative"})

    # Signal 5: Transaction volume (trust indicator)
    if target_merchant and target_merchant.get("total_transactions", 0) > 100:
        score += SIGNAL_TABLE["high_transaction_volume"][0]
        signals.append({"signal": "high_transaction_volume", "status": "positive"})
    elif target_merchant:
        score += SIGNAL_TABLE["high_transaction_volume"][1]
        signals.append({"signal": "high_transaction_volume", "status": "negative"})

    # Signal 6: Amount reasonableness
    if amount:
        try:
            amt = float(amount)
            if amt <= 2000:
                score += SIGNAL_TABLE["reasonable_amount"][0]
                signals.append({"signal": "reasonable_amount", "status": "positive"})
            else:
                score += SIGNAL_TABLE["reasonable_amount"][1]
                signals.append({"signal": "reasonable_amount", "status": "negative"})
        except ValueError:
            score += SIGNAL_TABLE["reasonable_amount"][1]
            signals.append({"signal": "reasonable_amount", "status": "negative"})

    # Signal 7: Verified merchant status
    if target_merchant and target_merchant.get("is_verified"):
        score += SIGNAL_TABLE["verified_status"][0]
        signals.append({"signal": "verified_status", "status": "positive"})
    elif target_merchant:
        score += SIGNAL_TABLE["verified_status"][1]
        signals.append({"signal": "verified_status", "status": "negative"})

    # Signal 8: Graph-based anomaly detection (NetworkX)
    if upi_id:
        graph_risk = get_upi_risk_from_graph(upi_id)
        if graph_risk["is_anomalous"]:
            score += graph_risk["graph_score_modifier"]
            for anomaly in graph_risk["anomaly_signals"]:
                signals.append({
                    "signal": f"graph_{anomaly['signal']}",
                    "status": "negative",
                    "severity": anomaly["severity"],
                    "detail": anomaly["detail"],
                })

    # Clamp score
    score = max(0, min(100, score))

    merchant_name = ""
    if merchant_by_upi:
        merchant_name = merchant_by_upi["name"]
    elif merchant_by_name:
        merchant_name = merchant_by_name["name"]
    elif display_name:
        merchant_name = display_name

    return {
        "trust_score": score,
        "trust_classification": classify(score),
        "merchant_name": merchant_name,
        "signals": signals,
    }


def verify_qr(qr_payload: str) -> dict:
    """
    Main entry point. Matches the Step 0 contract exactly.

    Args:
        qr_payload: Full UPI QR string, e.g. "upi://pay?pa=abc@upi&pn=ABC&am=250&cu=INR"

    Returns:
        {
            "trust_classification": "VERIFIED" | "CAUTION" | "SUSPICIOUS",
            "trust_score": 0-100,
            "merchant_name": "...",
            "reasons": [{"signal": "...", "status": "positive"|"negative", "text": "..."}, ...]
        }
    """
    result = score_qr(qr_payload)
    reasons = generate_reasons(result["signals"])

    return {
        "trust_classification": result["trust_classification"],
        "trust_score": result["trust_score"],
        "merchant_name": result["merchant_name"],
        "reasons": reasons,
    }
