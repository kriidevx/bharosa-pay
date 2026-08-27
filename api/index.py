"""
Vercel serverless entry point.
Wraps the FastAPI app for Vercel's Python runtime.
"""

import sys
from pathlib import Path

# Add project root so engine/ is importable
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from backend.main import app
