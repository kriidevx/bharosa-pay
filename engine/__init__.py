"""
Bharosa Pay — Scoring & Explainability Engine (Track 1: Kruthi)

Public API:
    verify_qr(qr_payload: str) -> dict
"""

from .scorer import verify_qr

__all__ = ["verify_qr"]
