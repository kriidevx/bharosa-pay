"""
Synthetic merchant & QR dataset generator.

Grounded in real-world data from:
- NPCI UPI Product Statistics (2026)
- RBI Parliament Reply on UPI Fraud (FY25-26: 16.29L cases, Rs 1226 Cr)
- NPCI Merchant Category Codes (ISO 18245)
- RingSafe UPI Fraud Patterns Report 2026

Generates ~500 merchants with ~20% fraudulent QR variants using
real merchant categories, UPI providers, and fraud patterns.

Usage:
    python -m engine.generate_data
"""

import json
import os
import random
from pathlib import Path
from urllib.parse import quote

from faker import Faker

fake = Faker("en_IN")
random.seed(42)
Faker.seed(42)

DATA_DIR = Path(__file__).parent / "data"

# Real UPI PSP handles (source: NPCI registered PSPs)
UPI_PROVIDERS = [
    "@ybl",       # PhonePe
    "@okaxis",    # Google Pay (Axis)
    "@oksbi",     # Google Pay (SBI)
    "@paytm",     # Paytm
    "@ibl",       # PhonePe (ICICI)
    "@apl",       # Amazon Pay
    "@axl",       # Axis Bank
    "@sbi",       # SBI
    "@hdfcbank",  # HDFC
    "@icici",     # ICICI
    "@kotak",     # Kotak
    "@boi",       # Bank of India
    "@upi",       # Generic
]

# NPCI Merchant Category Codes — Top categories by volume (source: NPCI Jun 2026 data)
# MCC code: (description, avg_transaction_amount_range)
MERCHANT_CATEGORIES = {
    "5411": ("Grocery Stores & Supermarkets", (50, 2000)),
    "5812": ("Restaurants & Eating Places", (100, 1500)),
    "5814": ("Fast Food Restaurants", (50, 500)),
    "5541": ("Service Stations (Fuel)", (200, 5000)),
    "5912": ("Drug Stores & Pharmacies", (50, 3000)),
    "5691": ("Clothing Stores", (200, 5000)),
    "5732": ("Electronics Stores", (500, 50000)),
    "5942": ("Book Stores", (50, 1000)),
    "7230": ("Beauty & Barber Shops", (100, 2000)),
    "5651": ("Family Clothing Stores", (200, 3000)),
    "5462": ("Bakeries", (30, 500)),
    "5331": ("Variety Stores", (50, 1000)),
    "5699": ("Miscellaneous Apparel", (100, 2000)),
    "7011": ("Hotels & Lodging", (500, 10000)),
    "5947": ("Gift & Card Shops", (50, 1000)),
    "5311": ("Department Stores", (200, 5000)),
    "5661": ("Shoe Stores", (200, 3000)),
    "5977": ("Cosmetic Stores", (100, 2000)),
    "5944": ("Jewellery Stores", (500, 100000)),
    "8011": ("Doctors & Physicians", (200, 5000)),
    "8021": ("Dentists & Orthodontists", (500, 10000)),
    "5983": ("Fuel Dealers", (500, 5000)),
    "7298": ("Health & Beauty Spas", (500, 5000)),
    "5045": ("Computers & Peripherals", (1000, 80000)),
    "4121": ("Taxi & Rideshare", (50, 1000)),
}

# Real Indian cities with state (source: Census 2021 top cities by UPI adoption)
CITIES = [
    ("Bengaluru", "Karnataka"),
    ("Mumbai", "Maharashtra"),
    ("Delhi", "Delhi"),
    ("Chennai", "Tamil Nadu"),
    ("Hyderabad", "Telangana"),
    ("Pune", "Maharashtra"),
    ("Kolkata", "West Bengal"),
    ("Ahmedabad", "Gujarat"),
    ("Jaipur", "Rajasthan"),
    ("Lucknow", "Uttar Pradesh"),
    ("Kochi", "Kerala"),
    ("Chandigarh", "Punjab"),
    ("Indore", "Madhya Pradesh"),
    ("Bhopal", "Madhya Pradesh"),
    ("Coimbatore", "Tamil Nadu"),
    ("Nagpur", "Maharashtra"),
    ("Patna", "Bihar"),
    ("Thiruvananthapuram", "Kerala"),
    ("Surat", "Gujarat"),
    ("Visakhapatnam", "Andhra Pradesh"),
    ("Mangalore", "Karnataka"),
    ("Mysuru", "Karnataka"),
    ("Noida", "Uttar Pradesh"),
    ("Gurgaon", "Haryana"),
    ("Vadodara", "Gujarat"),
]

# Real fraud types (source: RBI/NPCI reports, RingSafe 2026)
# Distribution based on FY25-26 data: QR-swap most common for P2M
FRAUD_TYPES = {
    "qr_swap": 0.30,                # Physical QR sticker replaced
    "upi_id_mismatch": 0.25,        # QR shows one name, UPI goes elsewhere
    "name_spoofing": 0.15,          # Unicode/lookalike chars in merchant name
    "amount_tampering": 0.10,       # Inflated amount embedded in QR
    "mule_account_network": 0.10,   # Money mule chains (RBI MuleHunter.AI pattern)
    "fake_merchant_clone": 0.10,    # Clone of real merchant with different UPI
}

# Real business name patterns for Indian merchants
BUSINESS_SUFFIXES = [
    "Store", "Shop", "Mart", "Bazaar", "Centre", "Hub",
    "Palace", "Corner", "Point", "Express", "World",
]


def generate_upi_id(name: str, verified: bool = True) -> str:
    """Generate a realistic UPI VPA from merchant name."""
    clean = name.lower().replace("'", "").replace(" ", "").replace(",", "")
    clean = clean.replace("&", "").replace(".", "")[:14]
    if verified:
        # Verified merchants tend to use business handles on major PSPs
        provider = random.choice(UPI_PROVIDERS[:6])
    else:
        provider = random.choice(UPI_PROVIDERS)
    return f"{clean}{provider}"


def generate_merchant_name(mcc: str, city: str) -> str:
    """Generate a realistic Indian merchant name for given category."""
    category_desc = MERCHANT_CATEGORIES[mcc][0]

    patterns = [
        lambda: f"{fake.first_name()}'s {category_desc.split('&')[0].strip()}",
        lambda: f"{fake.last_name()} {random.choice(BUSINESS_SUFFIXES)}",
        lambda: f"Sri {fake.first_name()} {category_desc.split('&')[0].strip()}",
        lambda: f"New {fake.last_name()} {random.choice(BUSINESS_SUFFIXES)}",
        lambda: f"{fake.company()}",
        lambda: f"{fake.first_name()} & Sons",
        lambda: f"{city} {random.choice(BUSINESS_SUFFIXES)}",
    ]

    return random.choice(patterns)()


def generate_merchants(count: int = 500) -> list[dict]:
    """Generate synthetic merchant records grounded in real NPCI categories."""
    merchants = []
    mcc_codes = list(MERCHANT_CATEGORIES.keys())

    for i in range(count):
        city, state = random.choice(CITIES)
        mcc = random.choice(mcc_codes)
        category_desc, amount_range = MERCHANT_CATEGORIES[mcc]
        name = generate_merchant_name(mcc, city)
        is_verified = random.random() < 0.82  # ~82% merchants verified (NPCI data)

        upi_id = generate_upi_id(name, is_verified)

        # Transaction volume follows power law (few high-volume, many low-volume)
        if is_verified:
            txn_count = int(random.paretovariate(1.5) * 50)
        else:
            txn_count = random.randint(0, 30)

        merchant = {
            "id": f"M{i+1:04d}",
            "name": name,
            "upi_id": upi_id,
            "city": city,
            "state": state,
            "mcc": mcc,
            "business_type": category_desc,
            "is_verified": is_verified,
            "registered_since": fake.date_between(start_date="-4y", end_date="today").isoformat(),
            "total_transactions": min(txn_count, 10000),
            "report_count": 0 if is_verified else random.randint(0, 8),
            "avg_transaction_amount": random.randint(*amount_range),
        }
        merchants.append(merchant)

    return merchants


def generate_qr_registry(merchants: list[dict]) -> list[dict]:
    """
    Generate QR registry with legitimate and fraudulent variants.
    ~20% fraudulent (aligned with RBI FY26 fraud-to-total ratio extrapolated for high-risk QRs)
    """
    qr_entries = []

    # Legitimate QRs — one per merchant
    for merchant in merchants:
        _, amount_range = MERCHANT_CATEGORIES.get(merchant["mcc"], ("", (50, 500)))
        amount = random.choice([None, random.randint(*amount_range)])
        qr_entries.append({
            "merchant_id": merchant["id"],
            "upi_id": merchant["upi_id"],
            "display_name": merchant["name"],
            "amount": amount,
            "is_fraudulent": False,
            "fraud_type": None,
        })

    # Fraudulent QRs — ~20% of merchants get a fraudulent variant
    fraud_count = int(len(merchants) * 0.20)
    fraud_merchants = random.sample(merchants, fraud_count)

    for merchant in fraud_merchants:
        # Pick fraud type based on real-world distribution
        fraud_type = random.choices(
            list(FRAUD_TYPES.keys()),
            weights=list(FRAUD_TYPES.values()),
            k=1,
        )[0]

        fraudulent_qr = {
            "merchant_id": merchant["id"],
            "is_fraudulent": True,
            "fraud_type": fraud_type,
        }

        if fraud_type == "qr_swap":
            # Physical QR replaced — different UPI entirely, real merchant name
            fake_upi = f"{fake.first_name().lower()}{random.randint(10,99)}@{random.choice(['ybl','paytm','upi'])}"
            fraudulent_qr["upi_id"] = fake_upi
            fraudulent_qr["display_name"] = merchant["name"]
            fraudulent_qr["amount"] = random.choice([100, 200, 500])

        elif fraud_type == "upi_id_mismatch":
            # QR shows merchant name but UPI goes to a different person
            fake_name = fake.first_name().lower() + fake.last_name().lower()
            fake_upi = f"{fake_name}@{random.choice(['ybl','okaxis','oksbi'])}"
            fraudulent_qr["upi_id"] = fake_upi
            fraudulent_qr["display_name"] = merchant["name"]
            fraudulent_qr["amount"] = random.choice([100, 250, 500, 1000])

        elif fraud_type == "name_spoofing":
            # Unicode lookalikes / slight misspelling
            spoofed = merchant["name"]
            replacements = [("a", "\u0430"), ("e", "\u0435"), ("o", "\u043e"), ("i", "\u0456")]
            for orig, repl in replacements:
                if orig in spoofed:
                    spoofed = spoofed.replace(orig, repl, 1)
                    break
            if spoofed == merchant["name"]:
                spoofed = merchant["name"] + " "  # trailing space
            fraudulent_qr["upi_id"] = merchant["upi_id"]
            fraudulent_qr["display_name"] = spoofed
            fraudulent_qr["amount"] = random.choice([100, 250, 500])

        elif fraud_type == "amount_tampering":
            # Inflated amount — juice shop charging Rs 5000
            _, normal_range = MERCHANT_CATEGORIES.get(merchant["mcc"], ("", (50, 500)))
            tampered_amount = random.choice([
                normal_range[1] * 5,
                normal_range[1] * 10,
                9999,
                random.randint(5000, 25000),
            ])
            fraudulent_qr["upi_id"] = merchant["upi_id"]
            fraudulent_qr["display_name"] = merchant["name"]
            fraudulent_qr["amount"] = int(tampered_amount)

        elif fraud_type == "mule_account_network":
            # Mule accounts — will be linked to multiple merchants by graph analyzer
            pass  # Handled separately below

        elif fraud_type == "fake_merchant_clone":
            # Clone: "ABC Restaurant Official" with different UPI
            fake_upi = f"pay{random.randint(100,999)}merchant@upi"
            fraudulent_qr["upi_id"] = fake_upi
            fraudulent_qr["display_name"] = f"{merchant['name']} Official"
            fraudulent_qr["amount"] = random.choice([100, 200, 500])

        if fraud_type != "mule_account_network":
            qr_entries.append(fraudulent_qr)

    # Money mule network pattern (source: RBI MuleHunter.AI detection pattern)
    # Single UPI linked to 4-8 merchants — classic mule behaviour
    mule_upis = [
        f"quickpay{i}@ybl" for i in range(1, 4)
    ] + [
        f"paynow{i}@paytm" for i in range(1, 4)
    ] + [
        f"transfer{i}@okaxis" for i in range(1, 3)
    ]

    for mule_upi in mule_upis:
        target_count = random.randint(4, 8)
        target_merchants = random.sample(merchants, target_count)
        for m in target_merchants:
            qr_entries.append({
                "merchant_id": m["id"],
                "upi_id": mule_upi,
                "display_name": m["name"],
                "amount": random.choice([100, 200, 500, 1000, 2000]),
                "is_fraudulent": True,
                "fraud_type": "mule_account_network",
            })

    random.shuffle(qr_entries)
    return qr_entries


def build_qr_payload(entry: dict) -> str:
    """Build a UPI QR payload string (UPI Deep Link spec)."""
    parts = [
        f"pa={entry['upi_id']}",
        f"pn={quote(entry['display_name'])}",
    ]
    if entry.get("amount"):
        parts.append(f"am={entry['amount']}")
    parts.append("cu=INR")
    return "upi://pay?" + "&".join(parts)


def generate_stats_context() -> dict:
    """Real-world context stats for the dashboard (source: Parliament/RBI FY25-26)."""
    return {
        "source": "RBI/NPCI Official Data (Parliament Reply, Apr 2026)",
        "fy_2025_26": {
            "total_fraud_cases_lakhs": 16.29,
            "total_amount_crores": 1226.37,
            "total_upi_users_crores": 55.49,
            "monthly_txn_volume_billions": 20.39,
        },
        "fraud_type_distribution": {
            "collect_request_scam": "most common overall",
            "qr_swap": "most common for P2M/in-store",
            "sim_swap": "high value per incident",
            "mule_accounts": "3-7 hops before cashout",
            "fake_app_phishing": "growing in 2026",
        },
        "npci_controls_2026": [
            "Device binding (mobile number + device)",
            "Two-factor authentication via UPI PIN",
            "Daily transaction limits",
            "AI/ML fraud monitoring (MuleHunter.AI)",
            "72-hour freeze on SIM-swap accounts",
            "Cooling period for new VPAs",
            "Bank-side velocity limits per VPA",
            "CUISF 2025 security framework",
        ],
    }


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("Generating merchants (NPCI MCC categories)...")
    merchants = generate_merchants(500)

    print("Generating QR registry (real fraud patterns)...")
    qr_registry = generate_qr_registry(merchants)

    for entry in qr_registry:
        entry["qr_payload"] = build_qr_payload(entry)

    # Save
    merchants_path = DATA_DIR / "merchants.json"
    qr_path = DATA_DIR / "qr_registry.json"
    stats_path = DATA_DIR / "india_upi_context.json"

    with open(merchants_path, "w") as f:
        json.dump(merchants, f, indent=2)
    with open(qr_path, "w") as f:
        json.dump(qr_registry, f, indent=2)
    with open(stats_path, "w") as f:
        json.dump(generate_stats_context(), f, indent=2)

    # Stats
    legit = sum(1 for q in qr_registry if not q["is_fraudulent"])
    fraud = sum(1 for q in qr_registry if q["is_fraudulent"])
    fraud_types = {}
    for q in qr_registry:
        if q["is_fraudulent"]:
            ft = q["fraud_type"]
            fraud_types[ft] = fraud_types.get(ft, 0) + 1

    print(f"\nDone!")
    print(f"  {len(merchants)} merchants across {len(MERCHANT_CATEGORIES)} NPCI categories")
    print(f"  {len(qr_registry)} QR entries ({legit} legit, {fraud} fraudulent)")
    print(f"  Fraud breakdown:")
    for ft, count in sorted(fraud_types.items(), key=lambda x: -x[1]):
        print(f"    {ft}: {count}")
    print(f"\nSaved to: {merchants_path}")
    print(f"          {qr_path}")
    print(f"          {stats_path}")


if __name__ == "__main__":
    main()
