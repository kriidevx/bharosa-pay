-- Bharosa Pay — Supabase Schema
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- Table 1: test_qr_data
-- Curated QR codes for Roweena to test the Flutter app
CREATE TABLE IF NOT EXISTS test_qr_data (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    qr_payload TEXT NOT NULL,
    display_name TEXT,
    upi_id TEXT NOT NULL,
    merchant_id TEXT,
    merchant_name TEXT,
    is_fraudulent BOOLEAN DEFAULT false,
    fraud_type TEXT,
    expected_result TEXT CHECK (expected_result IN ('VERIFIED', 'CAUTION', 'SUSPICIOUS'))
);

-- Table 2: scan_log
-- Stores results every time a user scans a QR in the live app
CREATE TABLE IF NOT EXISTS scan_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    qr_payload TEXT NOT NULL,
    trust_score INTEGER NOT NULL CHECK (trust_score >= 0 AND trust_score <= 100),
    trust_classification TEXT NOT NULL CHECK (trust_classification IN ('VERIFIED', 'CAUTION', 'SUSPICIOUS')),
    merchant_name TEXT,
    reasons JSONB,
    scanned_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security (open read for anon, write for authenticated)
ALTER TABLE test_qr_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_log ENABLE ROW LEVEL SECURITY;

-- Policies: allow read access for everyone (app needs to read test data)
CREATE POLICY "Allow public read on test_qr_data"
    ON test_qr_data FOR SELECT
    USING (true);

CREATE POLICY "Allow public read on scan_log"
    ON scan_log FOR SELECT
    USING (true);

-- Allow inserts to scan_log from the app (via anon key)
CREATE POLICY "Allow public insert on scan_log"
    ON scan_log FOR INSERT
    WITH CHECK (true);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_scan_log_scanned_at ON scan_log (scanned_at DESC);
CREATE INDEX IF NOT EXISTS idx_test_qr_data_fraudulent ON test_qr_data (is_fraudulent);
