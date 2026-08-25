"""
Synthetic merchant & QR dataset generator.

Generates ~400 merchants with ~20% having fraudulent QR variants.
Output: engine/data/merchants.json, engine/data/qr_registry.json

Usage:
    python -m engine.generate_data
"""

import json
import os
import random
from pathlib import Path

from faker import Faker

fake = Faker("en_IN")
random.seed(42)
Faker.seed(42)

DATA_DIR = Path(__file__).parent / "data"

UPI_PROVIDERS = ["@upi", "@ybl", "@paytm", "@okaxis", "@oksbi", "@ibl"]

BUSINESS_TYPES = [
    "Restaurant", "Grocery Store", "Medical Store", "Electronics Shop",
    "Clothing Store", "Salon", "Cafe", "Bakery", "Stationery Shop",
    "Hardware Store", "Mobile Repair", "Juice Shop", "Sweet Shop",
    "Book Store", "Gym", "Laundry", "Pet Store", "Flower Shop",
    "Auto Parts", "Tailoring Shop"
]

CITIES = [
    "Bangalore", "Mumbai", "Delhi", "Chennai", "Hyderabad",
    "Pune", "Kolkata", "Ahmedabad", "Jaipur", "Lucknow",
    "Kochi", "Chandigarh", "Indore", "Bhopal", "Coimbatore"
]


def generate_upi_id(name: str) -> str:
    """Generate a realistic UPI ID from merchant name."""
    clean = name.lower().replace(" ", "").replace("'", "")[:12]
    provider = random.choice(UPI_PROVIDERS)
    return f"{clean}{provider}"


def generate_merchants(count: int = 400) -> list[dict]:
    """Generate synthetic merchant records."""
    merchants = []

    for i in range(count):
        city = random.choice(CITIES)
        biz_type = random.choice(BUSINESS_TYPES)
        name = f"{fake.first_name()}'s {biz_type}" if random.random() < 0.4 else fake.company()
        name = f"{name} {city}" if random.random() < 0.3 else name

        upi_id = generate_upi_id(name)
        is_verified = random.random() < 0.80

        merchant = {
            "id": f"M{i+1:04d}",
            "name": name,
            "upi_id": upi_id,
            "city": city,
            "business_type": biz_type,
            "is_verified": is_verified,
            "registered_since": fake.date_between(start_date="-3y", end_date="today").isoformat(),
            "total_transactions": random.randint(10, 5000) if is_verified else random.randint(0, 20),
            "report_count": 0 if is_verified else random.randint(0, 5),
        }
        merchants.append(merchant)

    return merchants


def generate_qr_registry(merchants: list[dict]) -> list[dict]:
    """
    Generate QR registry with legitimate and fraudulent variants.
    ~20% of entries will be fraudulent (mismatched UPI, tampered names, etc.)
    """
    qr_entries = []

    for merchant in merchants:
        # Legitimate QR
        amount = random.choice([None, 50, 100, 150, 200, 250, 500, 1000])
        qr_entries.append({
            "merchant_id": merchant["id"],
            "upi_id": merchant["upi_id"],
            "display_name": merchant["name"],
            "amount": amount,
            "is_fraudulent": False,
            "fraud_type": None,
        })

    # Generate fraudulent QRs (~20% of total)
    fraud_count = int(len(merchants) * 0.20)
    fraud_merchants = random.sample(merchants, fraud_count)

    for merchant in fraud_merchants:
        fraud_type = random.choice([
            "upi_mismatch",
            "name_spoof",
            "amount_tampered",
            "unregistered_redirect",
        ])

        fraudulent_qr = {
            "merchant_id": merchant["id"],
            "is_fraudulent": True,
            "fraud_type": fraud_type,
        }

        if fraud_type == "upi_mismatch":
            fake_upi = generate_upi_id(fake.first_name() + fake.last_name())
            fraudulent_qr["upi_id"] = fake_upi
            fraudulent_qr["display_name"] = merchant["name"]
            fraudulent_qr["amount"] = random.choice([100, 250, 500])

        elif fraud_type == "name_spoof":
            spoofed = merchant["name"].replace("a", "á").replace("e", "é")
            if spoofed == merchant["name"]:
                spoofed = merchant["name"] + " "
            fraudulent_qr["upi_id"] = merchant["upi_id"]
            fraudulent_qr["display_name"] = spoofed
            fraudulent_qr["amount"] = random.choice([100, 250, 500])

        elif fraud_type == "amount_tampered":
            fraudulent_qr["upi_id"] = merchant["upi_id"]
            fraudulent_qr["display_name"] = merchant["name"]
            fraudulent_qr["amount"] = random.choice([2500, 5000, 9999])

        elif fraud_type == "unregistered_redirect":
            fake_upi = f"fraud{random.randint(100,999)}@upi"
            fraudulent_qr["upi_id"] = fake_upi
            fraudulent_qr["display_name"] = f"{merchant['name']} Official"
            fraudulent_qr["amount"] = random.choice([100, 200, 500])

        qr_entries.append(fraudulent_qr)

    # Generate money-mule patterns: single UPI ID linked to many merchants
    # This is the key graph anomaly the NetworkX analyzer should detect
    mule_upis = [f"mule{i}@upi" for i in range(1, 6)]
    for mule_upi in mule_upis:
        target_merchants = random.sample(merchants, random.randint(4, 8))
        for m in target_merchants:
            qr_entries.append({
                "merchant_id": m["id"],
                "upi_id": mule_upi,
                "display_name": m["name"],
                "amount": random.choice([100, 200, 500, 1000]),
                "is_fraudulent": True,
                "fraud_type": "money_mule_network",
            })

    random.shuffle(qr_entries)
    return qr_entries


def build_qr_payload(entry: dict) -> str:
    """Build a UPI QR payload string from a registry entry."""
    from urllib.parse import quote

    parts = [
        f"pa={entry['upi_id']}",
        f"pn={quote(entry['display_name'])}",
    ]
    if entry.get("amount"):
        parts.append(f"am={entry['amount']}")
    parts.append("cu=INR")

    return "upi://pay?" + "&".join(parts)


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("Generating merchants...")
    merchants = generate_merchants(400)

    print("Generating QR registry...")
    qr_registry = generate_qr_registry(merchants)

    # Add payload strings to QR entries
    for entry in qr_registry:
        entry["qr_payload"] = build_qr_payload(entry)

    # Save
    merchants_path = DATA_DIR / "merchants.json"
    qr_path = DATA_DIR / "qr_registry.json"

    with open(merchants_path, "w") as f:
        json.dump(merchants, f, indent=2)

    with open(qr_path, "w") as f:
        json.dump(qr_registry, f, indent=2)

    # Stats
    legit = sum(1 for q in qr_registry if not q["is_fraudulent"])
    fraud = sum(1 for q in qr_registry if q["is_fraudulent"])
    print(f"\nDone! {len(merchants)} merchants, {len(qr_registry)} QR entries ({legit} legit, {fraud} fraudulent)")
    print(f"Saved to: {merchants_path}")
    print(f"          {qr_path}")


if __name__ == "__main__":
    main()
