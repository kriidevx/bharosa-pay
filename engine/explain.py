"""
Explainability module — maps fired signals to plain-language reasons.

Returns the top 3-5 most relevant reasons ranked by importance.
"""

SIGNAL_TEMPLATES = {
    "merchant_registered": {
        "positive": "This merchant is registered in our verified database.",
        "negative": "This UPI ID is not registered to any known merchant.",
    },
    "upi_id_match": {
        "positive": "The UPI ID matches the registered merchant identity.",
        "negative": "The scanned UPI ID does not match the expected merchant registration.",
    },
    "name_match": {
        "positive": "The displayed merchant name matches our records.",
        "negative": "The merchant name in the QR does not match what we have on file — possible spoofing.",
    },
    "low_report_count": {
        "positive": "No fraud reports have been filed against this merchant.",
        "negative": "Multiple users have reported this QR code or merchant as suspicious.",
    },
    "high_transaction_volume": {
        "positive": "This merchant has a healthy transaction history indicating legitimacy.",
        "negative": "This merchant has very few prior transactions — newly created or inactive.",
    },
    "reasonable_amount": {
        "positive": "The requested payment amount appears normal.",
        "negative": "The payment amount is unusually high — verify before paying.",
    },
    "verified_status": {
        "positive": "This merchant holds verified status on the platform.",
        "negative": "This merchant is not verified — exercise caution.",
    },
    # Graph-based signals (NetworkX anomaly detection)
    "graph_multi_merchant_link": {
        "negative": None,  # Uses dynamic detail from graph_analyzer
    },
    "graph_fraud_ring_member": {
        "negative": None,
    },
    "graph_network_bridge": {
        "negative": None,
    },
    "graph_linked_to_multi_upi_merchant": {
        "negative": None,
    },
}

SIGNAL_PRIORITY = [
    "graph_fraud_ring_member",
    "graph_multi_merchant_link",
    "graph_network_bridge",
    "merchant_registered",
    "upi_id_match",
    "name_match",
    "low_report_count",
    "verified_status",
    "high_transaction_volume",
    "reasonable_amount",
    "graph_linked_to_multi_upi_merchant",
]


def generate_reasons(signals: list[dict], max_reasons: int = 5) -> list[dict]:
    """
    Convert raw signals into ranked plain-language reasons.

    Args:
        signals: List of {"signal": str, "status": "positive"|"negative"|"neutral"}
        max_reasons: Maximum number of reasons to return (3-5)

    Returns:
        List of {"signal": str, "status": str, "text": str}
    """
    reasons = []

    # Sort by priority (negative signals first within same priority for user attention)
    sorted_signals = sorted(
        signals,
        key=lambda s: (
            s["status"] != "negative",  # negatives first
            SIGNAL_PRIORITY.index(s["signal"]) if s["signal"] in SIGNAL_PRIORITY else 99,
        ),
    )

    for sig in sorted_signals:
        if sig["status"] == "neutral":
            continue

        # Graph signals carry their own detail text
        if sig["signal"].startswith("graph_") and sig.get("detail"):
            reasons.append({
                "signal": sig["signal"].replace("graph_", "").replace("_", " ").title(),
                "status": sig["status"],
                "text": sig["detail"],
            })
        else:
            template = SIGNAL_TEMPLATES.get(sig["signal"], {}).get(sig["status"])
            if template:
                reasons.append({
                    "signal": sig["signal"].replace("_", " ").title(),
                    "status": sig["status"],
                    "text": template,
                })

        if len(reasons) >= max_reasons:
            break

    return reasons
