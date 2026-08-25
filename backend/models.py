"""
Supabase table definitions (Track 2: Likhith)

Tables (create these in Supabase SQL editor):

-- merchants
CREATE TABLE merchants (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    upi_id TEXT UNIQUE NOT NULL,
    city TEXT,
    business_type TEXT,
    is_verified BOOLEAN DEFAULT false,
    registered_since DATE,
    total_transactions INTEGER DEFAULT 0,
    report_count INTEGER DEFAULT 0
);

-- qr_registry
CREATE TABLE qr_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id TEXT REFERENCES merchants(id),
    upi_id TEXT NOT NULL,
    display_name TEXT,
    amount NUMERIC,
    is_fraudulent BOOLEAN DEFAULT false,
    fraud_type TEXT,
    qr_payload TEXT NOT NULL
);

-- reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    qr_payload TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'QR_APPEARS_TAMPERED', 'WRONG_MERCHANT_NAME', 'SUSPICIOUS_AMOUNT', 'OTHER'
    )),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- scan_stats (single row)
CREATE TABLE scan_stats (
    id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    total_scans INTEGER DEFAULT 0,
    verified_count INTEGER DEFAULT 0,
    caution_count INTEGER DEFAULT 0,
    suspicious_count INTEGER DEFAULT 0
);
INSERT INTO scan_stats (id) VALUES (1);
"""
