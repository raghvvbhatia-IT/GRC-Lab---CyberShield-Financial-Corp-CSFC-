#!/bin/bash
# ==============================================================================
# CYBERSHIELD FINANCIAL CORP - Vulnerable Web App + Database Setup
# Run as: sudo bash on Ubuntu 22.04 (192.168.56.30 - Kali or separate Ubuntu)
# Purpose: Creates intentionally vulnerable fintech app with realistic data
# ==============================================================================

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN} CSFC Vulnerable Lab Environment Setup${NC}"
echo -e "${CYAN} CyberShield Financial Corp${NC}"
echo -e "${CYAN}============================================${NC}"

# ── Install dependencies ──────────────────────────────────────────────────────
echo -e "\n${YELLOW}[+] Installing dependencies...${NC}"
apt-get update -qq
apt-get install -y postgresql postgresql-contrib python3 python3-pip python3-flask \
    python3-psycopg2 nginx openssh-server vsftpd samba nmap curl git \
    apache2 php php-pgsql libapache2-mod-php unzip wget 2>/dev/null
pip3 install flask flask-sqlalchemy psycopg2-binary flask-login werkzeug 2>/dev/null
echo -e "${GREEN}    Dependencies installed${NC}"

# ── PostgreSQL: Create CSFC Database with Realistic Data ─────────────────────
echo -e "\n${YELLOW}[+] Setting up CSFC PostgreSQL database with sample data...${NC}"

sudo -u postgres psql <<'EOSQL'
-- Drop and recreate for clean install
DROP DATABASE IF EXISTS csfc_production;
DROP USER IF EXISTS csfc_admin;
DROP USER IF EXISTS csfc_app;
DROP USER IF EXISTS csfc_readonly;

-- Create users with weak passwords (intentional findings)
CREATE USER csfc_admin WITH PASSWORD 'admin123';           -- FINDING: weak password
CREATE USER csfc_app WITH PASSWORD 'AppP@ss2024';
CREATE USER csfc_readonly WITH PASSWORD 'readonly';        -- FINDING: weak password

-- Create database
CREATE DATABASE csfc_production OWNER csfc_admin;
GRANT ALL PRIVILEGES ON DATABASE csfc_production TO csfc_admin;
GRANT CONNECT ON DATABASE csfc_production TO csfc_app;
GRANT CONNECT ON DATABASE csfc_production TO csfc_readonly;
EOSQL

sudo -u postgres psql -d csfc_production <<'EOSQL'
-- ==============================================================
-- CUSTOMERS TABLE (PII + PCI Data)
-- ==============================================================
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    email           VARCHAR(100) UNIQUE,
    phone           VARCHAR(20),
    dob             DATE,
    ssn             VARCHAR(15),          -- GDPR/PII - stored in plain text (FINDING!)
    address         TEXT,
    city            VARCHAR(50),
    country         VARCHAR(50),
    account_number  VARCHAR(20) UNIQUE,
    account_balance DECIMAL(12,2),
    account_type    VARCHAR(20),
    kyc_status      VARCHAR(20),
    risk_rating     VARCHAR(10),
    created_at      TIMESTAMP DEFAULT NOW(),
    last_login      TIMESTAMP
);

-- 40 realistic customers
INSERT INTO customers (first_name, last_name, email, phone, dob, ssn, address, city, country, account_number, account_balance, account_type, kyc_status, risk_rating) VALUES
('James',     'Abernathy',  'j.abernathy@gmail.com',      '555-0101', '1985-03-14', '847-23-9134', '42 Oak Street',        'New York',      'US', 'CSFC-10000142', 125480.50, 'PREMIUM',  'VERIFIED', 'LOW'),
('Maria',     'Santos',     'm.santos@hotmail.com',        '555-0102', '1990-07-22', '392-67-4521', '17 Elm Avenue',        'Miami',         'US', 'CSFC-10000143',  34290.75, 'STANDARD', 'VERIFIED', 'LOW'),
('Robert',    'Chen',       'r.chen@outlook.com',          '555-0103', '1978-11-05', '561-89-2347', '8 Pine Road',          'San Francisco', 'US', 'CSFC-10000144', 892340.00, 'BUSINESS', 'VERIFIED', 'MEDIUM'),
('Emma',      'Wilson',     'e.wilson@yahoo.com',          '555-0104', '1995-02-28', '728-34-8821', '23 Maple Drive',       'Chicago',       'US', 'CSFC-10000145',   8920.25, 'STANDARD', 'PENDING',  'LOW'),
('David',     'Okafor',     'd.okafor@gmail.com',          '555-0105', '1982-09-17', '445-92-1183', '55 Cedar Lane',        'Houston',       'US', 'CSFC-10000146',  67830.00, 'PREMIUM',  'VERIFIED', 'LOW'),
('Sophie',    'Leclerc',    's.leclerc@gmail.com',         '555-0106', '1988-06-03', '332-17-8834', '12 Rue de la Paix',    'Paris',         'FR', 'CSFC-10000147',  42100.50, 'STANDARD', 'VERIFIED', 'LOW'),
('Amir',      'Al-Rashid',  'a.alrashid@gmail.com',        '555-0107', '1975-12-20', '119-45-7823', '78 Sheikh Zayed Rd',  'Dubai',         'AE', 'CSFC-10000148', 540000.00, 'BUSINESS', 'VERIFIED', 'HIGH'),  -- HIGH risk!
('Yuki',      'Tanaka',     'y.tanaka@gmail.com',          '555-0108', '1992-04-11', '887-23-1156', '3-5 Shibuya',          'Tokyo',         'JP', 'CSFC-10000149',  98430.25, 'PREMIUM',  'VERIFIED', 'MEDIUM'),
('Isabella',  'Rossi',      'i.rossi@libero.it',           '555-0109', '1987-08-29', '654-32-9871', 'Via Roma 15',          'Rome',          'IT', 'CSFC-10000150',  28750.00, 'STANDARD', 'VERIFIED', 'LOW'),
('Marcus',    'Johnson',    'm.johnson@gmail.com',          '555-0110', '1980-01-16', '223-87-4456', '901 Broadway',         'New York',      'US', 'CSFC-10000151', 213450.75, 'PREMIUM',  'VERIFIED', 'LOW'),
('Chen',      'Wei',        'c.wei@gmail.com',              '555-0111', '1993-10-07', '776-54-2231', '56 Nathan Road',       'Hong Kong',     'HK', 'CSFC-10000152',  75200.00, 'STANDARD', 'PENDING',  'MEDIUM'),
('Nina',      'Petrova',    'n.petrova@mail.ru',            '555-0112', '1986-05-23', '341-98-7763', '14 Tverskaya St',      'Moscow',        'RU', 'CSFC-10000153', 189000.00, 'PREMIUM',  'VERIFIED', 'HIGH'),  -- HIGH risk + Russia
('Andre',     'Dupont',     'a.dupont@orange.fr',           '555-0113', '1979-07-04', '512-76-8834', '8 Avenue Montaigne',  'Paris',         'FR', 'CSFC-10000154',  91340.50, 'STANDARD', 'VERIFIED', 'LOW'),
('Fatima',    'Al-Zahra',   'f.alzahra@gmail.com',          '555-0114', '1991-03-18', '234-65-9912', '22 King Fahd Road',   'Riyadh',        'SA', 'CSFC-10000155',  34500.00, 'STANDARD', 'VERIFIED', 'MEDIUM'),
('Tom',       'MacAllister','t.macallister@gmail.com',      '555-0115', '1984-11-30', '667-23-1145', '45 Princes St',       'Edinburgh',     'UK', 'CSFC-10000156',  52800.25, 'PREMIUM',  'VERIFIED', 'LOW'),
('Olga',      'Ivanova',    'o.ivanova@yandex.ru',          '555-0116', '1990-08-14', '889-43-2267', '7 Nevsky Prospect',   'St Petersburg', 'RU', 'CSFC-10000157',  28900.00, 'STANDARD', 'PENDING',  'HIGH'),  -- HIGH risk
('Kevin',     'Park',       'k.park@gmail.com',             '555-0117', '1996-02-05', '423-11-8876', '88 Gangnam-gu',        'Seoul',         'KR', 'CSFC-10000158',  14320.75, 'STANDARD', 'VERIFIED', 'LOW'),
('Camila',    'Reyes',      'c.reyes@gmail.com',            '555-0118', '1988-06-25', '556-78-3312', 'Calle 45 No. 12',     'Bogota',        'CO', 'CSFC-10000159',  67100.00, 'PREMIUM',  'VERIFIED', 'MEDIUM'),
('Lars',      'Eriksson',   'l.eriksson@gmail.com',         '555-0119', '1977-09-09', '312-45-9967', 'Drottninggatan 12',   'Stockholm',     'SE', 'CSFC-10000160', 143000.00, 'BUSINESS', 'VERIFIED', 'LOW'),
('Priya',     'Nair',       'p.nair@gmail.com',             '555-0120', '1994-04-17', '678-23-4456', '24 MG Road',          'Bangalore',     'IN', 'CSFC-10000161',  22450.00, 'STANDARD', 'VERIFIED', 'LOW'),
-- Additional 20 customers
('Zach',      'Morrison',   'z.morrison@gmail.com',        '555-0121', '1983-12-01', '190-34-5678', '303 Sunset Blvd',     'Los Angeles',   'US', 'CSFC-10000162',  89234.00, 'PREMIUM',  'VERIFIED', 'LOW'),
('Ana',       'Gutierrez',  'a.gutierrez@gmail.com',       '555-0122', '1991-07-15', '223-56-7890', 'Paseo de la Reforma', 'Mexico City',   'MX', 'CSFC-10000163',  31450.75, 'STANDARD', 'VERIFIED', 'LOW'),
('Ben',       'Holt',       'b.holt@gmail.com',            '555-0123', '1987-03-28', '334-67-8901', '14 King St',          'Toronto',       'CA', 'CSFC-10000164',  58900.00, 'PREMIUM',  'VERIFIED', 'LOW'),
('Leila',     'Hosseini',   'l.hosseini@gmail.com',        '555-0124', '1985-09-22', '445-78-9012', '22 Valiasr Ave',      'Tehran',        'IR', 'CSFC-10000165',  45200.00, 'STANDARD', 'PENDING',  'HIGH'),  -- HIGH risk
('Dmitri',    'Volkov',     'd.volkov@mail.ru',            '555-0125', '1979-06-11', '556-89-0123', '9 Kutuzovsky Pr',     'Moscow',        'RU', 'CSFC-10000166', 780000.00, 'BUSINESS', 'VERIFIED', 'HIGH'),  -- CRITICAL: large balance + Russia
('Grace',     'Achebe',     'g.achebe@gmail.com',          '555-0126', '1993-01-30', '667-90-1234', '5 Broad Street',      'Lagos',         'NG', 'CSFC-10000167',  12300.00, 'STANDARD', 'PENDING',  'MEDIUM'),
('Victor',    'Huang',      'v.huang@gmail.com',           '555-0127', '1980-08-18', '778-01-2345', '88 Collins St',       'Melbourne',     'AU', 'CSFC-10000168',  94500.25, 'PREMIUM',  'VERIFIED', 'LOW'),
('Sana',      'Malik',      's.malik@gmail.com',           '555-0128', '1989-04-07', '889-12-3456', '45 Gulberg III',      'Lahore',        'PK', 'CSFC-10000169',  18750.00, 'STANDARD', 'VERIFIED', 'LOW'),
('Thomas',    'Meier',      't.meier@gmail.com',           '555-0129', '1976-11-25', '990-23-4567', 'Unter den Linden 5', 'Berlin',        'DE', 'CSFC-10000170', 234000.00, 'BUSINESS', 'VERIFIED', 'LOW'),
('Adaeze',    'Okonkwo',    'a.okonkwo@gmail.com',         '555-0130', '1995-05-14', '101-34-5678', '12 Awolowo Road',     'Abuja',         'NG', 'CSFC-10000171',   8900.00, 'STANDARD', 'PENDING',  'MEDIUM'),
('Paulo',     'Ferreira',   'p.ferreira@gmail.com',        '555-0131', '1982-02-20', '212-45-6789', 'Av. Paulista 1000',   'Sao Paulo',     'BR', 'CSFC-10000172', 156000.00, 'PREMIUM',  'VERIFIED', 'MEDIUM'),
('Mei',       'Zhang',      'm.zhang@gmail.com',           '555-0132', '1990-10-08', '323-56-7890', '88 East Nanjing Rd', 'Shanghai',      'CN', 'CSFC-10000173',  67890.00, 'STANDARD', 'VERIFIED', 'MEDIUM'),
('Abebe',     'Tadesse',    'a.tadesse@gmail.com',         '555-0133', '1984-07-17', '434-67-8901', 'Bole Road 23',        'Addis Ababa',   'ET', 'CSFC-10000174',   5400.00, 'STANDARD', 'PENDING',  'LOW'),
('Claire',    'Fontaine',   'c.fontaine@gmail.com',        '555-0134', '1988-12-03', '545-78-9012', '3 Rue Lepic',         'Paris',         'FR', 'CSFC-10000175',  43200.75, 'PREMIUM',  'VERIFIED', 'LOW'),
('Miguel',    'Torres',     'm.torres@gmail.com',          '555-0135', '1977-04-26', '656-89-0123', 'Gran Via 45',         'Madrid',        'ES', 'CSFC-10000176',  89100.00, 'PREMIUM',  'VERIFIED', 'LOW'),
('Anya',      'Kovalenko',  'a.kovalenko@gmail.com',       '555-0136', '1992-09-13', '767-90-1234', 'Kreschatyk 10',       'Kyiv',          'UA', 'CSFC-10000177',  28300.00, 'STANDARD', 'VERIFIED', 'MEDIUM'),
('Jack',      'O''Sullivan','j.osullivan@gmail.com',       '555-0137', '1986-06-08', '878-01-2345', '14 O''Connell St',   'Dublin',        'IE', 'CSFC-10000178',  71200.50, 'PREMIUM',  'VERIFIED', 'LOW'),
('Riya',      'Bose',       'r.bose@gmail.com',            '555-0138', '1994-03-21', '989-12-3456', '22 Park Street',      'Kolkata',       'IN', 'CSFC-10000179',  14500.00, 'STANDARD', 'VERIFIED', 'LOW'),
('Kwame',     'Asante',     'k.asante@gmail.com',          '555-0139', '1981-08-04', '010-23-4567', '8 Airport Road',      'Accra',         'GH', 'CSFC-10000180',  32100.25, 'STANDARD', 'VERIFIED', 'LOW'),
('Hannah',    'Schmidt',    'h.schmidt@gmail.com',         '555-0140', '1989-01-17', '121-34-5678', 'Friedrichstr 120',   'Berlin',        'DE', 'CSFC-10000181',  94300.00, 'PREMIUM',  'VERIFIED', 'LOW');

-- ==============================================================
-- PAYMENT CARDS TABLE (PCI Data - Stored without proper masking)
-- ==============================================================
CREATE TABLE payment_cards (
    card_id         SERIAL PRIMARY KEY,
    customer_id     INTEGER REFERENCES customers(customer_id),
    card_number     VARCHAR(20),          -- FINDING: Full PAN stored unmasked!
    card_type       VARCHAR(20),
    expiry_month    INTEGER,
    expiry_year     INTEGER,
    cvv             VARCHAR(5),           -- CRITICAL FINDING: CVV stored in DB!
    card_name       VARCHAR(100),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT NOW()
);

INSERT INTO payment_cards (customer_id, card_number, card_type, expiry_month, expiry_year, cvv, card_name) VALUES
(1,  '4532789123456789', 'VISA',       9, 2026, '847', 'James Abernathy'),
(2,  '5425233456789012', 'MASTERCARD', 12,2025, '392', 'Maria Santos'),
(3,  '371449635398431',  'AMEX',       3, 2027, '2847','Robert Chen'),
(4,  '6011123456789012', 'DISCOVER',   6, 2026, '591', 'Emma Wilson'),
(5,  '4916234567890123', 'VISA',       11,2025, '273', 'David Okafor'),
(6,  '5425123456789012', 'MASTERCARD', 4, 2026, '128', 'Sophie Leclerc'),
(7,  '4532891234567890', 'VISA',       8, 2027, '934', 'Amir Al-Rashid'),
(8,  '4539234567890123', 'VISA',       2, 2026, '445', 'Yuki Tanaka'),
(10, '5412345678901234', 'MASTERCARD', 7, 2025, '782', 'Marcus Johnson'),
(20, '4916789012345678', 'VISA',       9, 2026, '341', 'Priya Nair');

-- ==============================================================
-- TRANSACTIONS TABLE
-- ==============================================================
CREATE TABLE transactions (
    txn_id          SERIAL PRIMARY KEY,
    customer_id     INTEGER REFERENCES customers(customer_id),
    card_id         INTEGER REFERENCES payment_cards(card_id),
    txn_date        TIMESTAMP,
    amount          DECIMAL(10,2),
    currency        VARCHAR(5),
    merchant        VARCHAR(100),
    merchant_cat    VARCHAR(50),
    txn_type        VARCHAR(20),
    status          VARCHAR(20),
    country         VARCHAR(50),
    suspicious      BOOLEAN DEFAULT false,
    aml_flag        VARCHAR(20)
);

-- Suspicious transactions for AML exercise
INSERT INTO transactions (customer_id, card_id, txn_date, amount, currency, merchant, merchant_cat, txn_type, status, country, suspicious, aml_flag) VALUES
-- Normal transactions
(1, 1, '2024-09-01 09:15:00', 1250.00, 'USD', 'Amazon',              'E-COMMERCE',   'PURCHASE', 'COMPLETED', 'US', false, 'CLEAR'),
(2, 2, '2024-09-01 11:30:00', 89.99,   'USD', 'Netflix',             'STREAMING',    'PURCHASE', 'COMPLETED', 'US', false, 'CLEAR'),
(3, 3, '2024-09-02 14:45:00', 3400.00, 'USD', 'Apple Store',         'ELECTRONICS',  'PURCHASE', 'COMPLETED', 'US', false, 'CLEAR'),
(5, 5, '2024-09-03 16:20:00', 675.25,  'USD', 'Delta Airlines',      'TRAVEL',       'PURCHASE', 'COMPLETED', 'US', false, 'CLEAR'),
-- SUSPICIOUS: Structuring (multiple transactions just under $10,000)
(7, 7, '2024-09-10 08:00:00', 9800.00, 'USD', 'Wire Transfer',       'WIRE',         'TRANSFER', 'COMPLETED', 'AE', true,  'STRUCTURING'),
(7, 7, '2024-09-10 08:05:00', 9750.00, 'USD', 'Wire Transfer',       'WIRE',         'TRANSFER', 'COMPLETED', 'AE', true,  'STRUCTURING'),
(7, 7, '2024-09-10 08:10:00', 9600.00, 'USD', 'Wire Transfer',       'WIRE',         'TRANSFER', 'COMPLETED', 'AE', true,  'STRUCTURING'),
-- SUSPICIOUS: Large cash transactions
(12, NULL,'2024-09-11 10:00:00',50000.00,'USD','ATM Withdrawal',     'CASH',         'WITHDRAWAL','COMPLETED','RU', true,  'LARGE_CASH'),
-- SUSPICIOUS: Sanctioned country transactions
(16, NULL,'2024-09-12 14:00:00',45000.00,'USD','International Wire', 'WIRE',         'TRANSFER', 'PENDING',   'RU', true,  'SANCTIONS_RISK'),
(25, NULL,'2024-09-15 09:30:00',75000.00,'USD','Business Payment',   'BUSINESS',     'TRANSFER', 'COMPLETED', 'RU', true,  'SANCTIONS_RISK'),
-- SUSPICIOUS: Rapid succession transactions (fraud pattern)
(4, 4, '2024-09-20 02:14:00', 2500.00, 'USD', 'Unknown Merchant',   'UNKNOWN',      'PURCHASE', 'COMPLETED', 'NG', true,  'UNUSUAL_PATTERN'),
(4, 4, '2024-09-20 02:15:00', 2499.00, 'USD', 'Unknown Merchant',   'UNKNOWN',      'PURCHASE', 'COMPLETED', 'GH', true,  'UNUSUAL_PATTERN'),
(4, 4, '2024-09-20 02:16:00', 2498.00, 'USD', 'Unknown Merchant',   'UNKNOWN',      'PURCHASE', 'COMPLETED', 'CI', true,  'UNUSUAL_PATTERN'),
-- Normal
(8, 8, '2024-09-22 11:00:00', 450.00,  'USD', 'Hotel Booking',      'TRAVEL',       'PURCHASE', 'COMPLETED', 'JP', false, 'CLEAR'),
(10,10, '2024-09-23 15:30:00',1800.00, 'USD', 'Jewelry Store',      'RETAIL',       'PURCHASE', 'COMPLETED', 'US', false, 'CLEAR');

-- ==============================================================
-- AUDIT_LOG TABLE (should be immutable - FINDING: it's not!)
-- ==============================================================
CREATE TABLE audit_log (
    log_id      SERIAL PRIMARY KEY,
    event_time  TIMESTAMP DEFAULT NOW(),
    user_name   VARCHAR(50),
    action      VARCHAR(100),
    table_name  VARCHAR(50),
    record_id   INTEGER,
    old_value   TEXT,
    new_value   TEXT,
    ip_address  VARCHAR(20)
);

INSERT INTO audit_log (event_time, user_name, action, table_name, record_id, ip_address) VALUES
('2024-09-01 08:00:00', 'csfc_admin', 'SELECT',  'customers',     NULL, '10.0.1.50'),
('2024-09-05 14:23:00', 'csfc_app',   'UPDATE',  'customers',     7,    '10.0.1.10'),
('2024-09-10 09:15:00', 'csfc_admin', 'SELECT',  'payment_cards', NULL, '192.168.1.55'),   -- FINDING: External IP accessing cardholder data!
('2024-09-10 09:16:00', 'csfc_admin', 'SELECT',  'payment_cards', NULL, '192.168.1.55'),
('2024-09-15 03:47:00', 'csfc_app',   'INSERT',  'transactions',  NULL, '10.0.1.10'),
('2024-09-20 02:13:00', 'csfc_app',   'INSERT',  'transactions',  NULL, '41.66.224.10'),   -- FINDING: African IP inserting transactions at 2AM!
('2024-09-20 02:14:00', 'csfc_app',   'INSERT',  'transactions',  NULL, '41.66.224.10'),
('2024-09-20 02:15:00', 'csfc_app',   'INSERT',  'transactions',  NULL, '41.66.224.10');

-- ==============================================================
-- GRANT PERMISSIONS (overly permissive - intentional finding)
-- ==============================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO csfc_app;         -- FINDING: app user has INSERT/UPDATE/DELETE on ALL tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO csfc_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO csfc_admin;

-- FINDING: csfc_readonly can read payment_cards including CVV!
EOSQL

echo -e "${GREEN}    CSFC PostgreSQL database created with 40 customers, cards, transactions${NC}"

# ── Create Intentionally Vulnerable Flask Web Application ─────────────────────
echo -e "\n${YELLOW}[+] Creating vulnerable CSFC web application...${NC}"

mkdir -p /opt/csfc-app/{templates,static}

# Main application with intentional vulnerabilities
cat > /opt/csfc-app/app.py <<'PYEOF'
#!/usr/bin/env python3
"""
CYBERSHIELD FINANCIAL CORP - Internal Banking Portal
INTENTIONALLY VULNERABLE - FOR GRC LAB USE ONLY
Vulnerabilities included for security testing exercises:
  - SQL Injection in customer search
  - Weak authentication (no lockout, no MFA)
  - Sensitive data exposed in API
  - Missing input validation
  - No CSRF protection
  - Insecure direct object reference (IDOR)
  - Debug mode enabled in production
"""
from flask import Flask, render_template, request, jsonify, redirect, url_for, session
import psycopg2
import os
import hashlib

app = Flask(__name__)
app.secret_key = 'csfc_super_secret_2024'  # FINDING: weak secret key hardcoded
app.debug = True  # FINDING: debug mode in production!

# FINDING: DB credentials hardcoded in source code
DB_CONFIG = {
    'host': 'localhost',
    'database': 'csfc_production',
    'user': 'csfc_admin',
    'password': 'admin123'  # FINDING: weak DB password
}

def get_db():
    return psycopg2.connect(**DB_CONFIG)

# Weak authentication - no lockout, no MFA
USERS = {
    'admin':    hashlib.md5(b'admin123').hexdigest(),    # FINDING: MD5 hashing!
    'j.lee':    hashlib.md5(b'Password1').hexdigest(),
    'a.nguyen': hashlib.md5(b'Password1').hexdigest(),
}

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET','POST'])
def login():
    error = None
    if request.method == 'POST':
        user = request.form.get('username','')
        pwd  = request.form.get('password','')
        hashed = hashlib.md5(pwd.encode()).hexdigest()
        if user in USERS and USERS[user] == hashed:
            session['user'] = user
            return redirect(url_for('dashboard'))
        error = 'Invalid credentials'
        # FINDING: No lockout after failed attempts
        # FINDING: Error reveals whether user exists
    return render_template('login.html', error=error)

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        return redirect(url_for('login'))
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM customers")
    total_customers = cur.fetchone()[0]
    cur.execute("SELECT SUM(account_balance) FROM customers")
    total_aum = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM transactions WHERE suspicious = true")
    suspicious_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM transactions WHERE txn_date > NOW() - INTERVAL '30 days'")
    recent_txns = cur.fetchone()[0]
    conn.close()
    return render_template('dashboard.html', 
        user=session['user'],
        total_customers=total_customers,
        total_aum=f"{total_aum:,.2f}",
        suspicious_count=suspicious_count,
        recent_txns=recent_txns)

@app.route('/customers')
def customers():
    if 'user' not in session:
        return redirect(url_for('login'))
    search = request.args.get('search', '')
    conn = get_db()
    cur = conn.cursor()
    # CRITICAL FINDING: SQL INJECTION VULNERABILITY!
    query = f"SELECT customer_id, first_name, last_name, email, account_number, account_balance, risk_rating FROM customers WHERE first_name ILIKE '%{search}%' OR last_name ILIKE '%{search}%' OR email ILIKE '%{search}%'"
    cur.execute(query)
    rows = cur.fetchall()
    conn.close()
    return render_template('customers.html', customers=rows, search=search)

@app.route('/customer/<int:customer_id>')
def customer_detail(customer_id):
    if 'user' not in session:
        return redirect(url_for('login'))
    conn = get_db()
    cur = conn.cursor()
    # FINDING: IDOR - no authorization check, any logged-in user can view any customer
    cur.execute("SELECT * FROM customers WHERE customer_id = %s", (customer_id,))
    customer = cur.fetchone()
    cur.execute("SELECT * FROM payment_cards WHERE customer_id = %s", (customer_id,))
    cards = cur.fetchall()  # FINDING: Returns full PAN and CVV!
    cur.execute("SELECT * FROM transactions WHERE customer_id = %s ORDER BY txn_date DESC LIMIT 10", (customer_id,))
    transactions = cur.fetchall()
    conn.close()
    return render_template('customer_detail.html', customer=customer, cards=cards, transactions=transactions)

@app.route('/api/customers')
def api_customers():
    # FINDING: API requires no authentication!
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT customer_id, first_name, last_name, email, ssn, dob, account_number, account_balance FROM customers")
    rows = cur.fetchall()
    conn.close()
    # FINDING: API returns SSN and DOB without authentication!
    return jsonify([{
        'id': r[0], 'first_name': r[1], 'last_name': r[2],
        'email': r[3], 'ssn': r[4], 'dob': str(r[5]),
        'account': r[6], 'balance': float(r[7])
    } for r in rows])

@app.route('/api/cards')
def api_cards():
    # FINDING: Exposes ALL card data including CVV with no auth
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM payment_cards")
    rows = cur.fetchall()
    conn.close()
    return jsonify([{
        'card_id': r[0], 'customer_id': r[1], 'card_number': r[2],
        'card_type': r[3], 'expiry_month': r[4], 'expiry_year': r[5],
        'cvv': r[6], 'card_name': r[7]
    } for r in rows])

@app.route('/transactions/suspicious')
def suspicious_transactions():
    if 'user' not in session:
        return redirect(url_for('login'))
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT t.txn_id, c.first_name || ' ' || c.last_name, t.amount, t.currency,
               t.merchant, t.txn_date, t.country, t.aml_flag
        FROM transactions t
        JOIN customers c ON t.customer_id = c.customer_id
        WHERE t.suspicious = true
        ORDER BY t.txn_date DESC
    """)
    rows = cur.fetchall()
    conn.close()
    return render_template('suspicious.html', transactions=rows)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)  # FINDING: debug=True, listening on all interfaces
PYEOF

# HTML Templates
cat > /opt/csfc-app/templates/base.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>CyberShield Financial Corp - Internal Portal</title>
    <style>
        body { font-family: Arial, sans-serif; background: #0d1117; color: #c9d1d9; margin: 0; }
        nav { background: #161b22; padding: 1rem 2rem; border-bottom: 1px solid #30363d; display: flex; align-items: center; gap: 2rem; }
        nav .logo { color: #38bdf8; font-weight: 700; font-size: 1.1rem; }
        nav a { color: #8b949e; text-decoration: none; font-size: 0.9rem; }
        nav a:hover { color: #38bdf8; }
        .container { max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }
        .card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1.5rem; margin-bottom: 1rem; }
        .stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }
        .stat { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1.25rem; text-align: center; }
        .stat .num { font-size: 2rem; font-weight: 700; color: #38bdf8; }
        .stat .lbl { font-size: 0.8rem; color: #8b949e; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0d1117; color: #38bdf8; padding: 0.75rem; text-align: left; font-size: 0.75rem; letter-spacing: 0.1em; text-transform: uppercase; border-bottom: 2px solid #30363d; }
        td { padding: 0.75rem; border-bottom: 1px solid #21262d; font-size: 0.875rem; }
        tr:hover td { background: #21262d; }
        .badge-red { background: rgba(248,113,113,0.15); color: #f87171; border: 1px solid rgba(248,113,113,0.3); padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.7rem; }
        .badge-green { background: rgba(52,211,153,0.15); color: #34d399; border: 1px solid rgba(52,211,153,0.3); padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.7rem; }
        .badge-amber { background: rgba(251,191,36,0.15); color: #fbbf24; border: 1px solid rgba(251,191,36,0.3); padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.7rem; }
        input[type=text], input[type=password] { background: #0d1117; border: 1px solid #30363d; color: #c9d1d9; padding: 0.6rem 0.9rem; border-radius: 6px; width: 100%; box-sizing: border-box; margin-bottom: 1rem; }
        button, .btn { background: #38bdf8; color: #0d1117; border: none; padding: 0.6rem 1.5rem; border-radius: 6px; cursor: pointer; font-weight: 700; text-decoration: none; display: inline-block; }
        h1, h2 { color: #e6edf3; }
        .finding { background: rgba(248,113,113,0.08); border: 1px solid rgba(248,113,113,0.25); border-left: 3px solid #f87171; padding: 0.75rem 1rem; border-radius: 4px; font-size: 0.8rem; color: #f87171; margin: 0.5rem 0; }
    </style>
</head>
<body>
{% if session.user %}
<nav>
    <span class="logo">🏦 CyberShield Financial Corp</span>
    <a href="/dashboard">Dashboard</a>
    <a href="/customers">Customers</a>
    <a href="/transactions/suspicious">🚨 Suspicious Activity</a>
    <a href="/api/customers" target="_blank">API</a>
    <span style="margin-left:auto;color:#8b949e;font-size:0.8rem">{{ session.user }} | <a href="/logout">Logout</a></span>
</nav>
{% endif %}
{% block content %}{% endblock %}
</body>
</html>
HTML

cat > /opt/csfc-app/templates/login.html <<'HTML'
{% extends 'base.html' %}
{% block content %}
<div style="max-width:400px;margin:5rem auto;padding:2rem">
    <div class="card">
        <h2>🏦 CSFC Internal Portal</h2>
        <p style="color:#8b949e;font-size:0.875rem">CyberShield Financial Corp Employee Login</p>
        {% if error %}<div class="finding">{{ error }}</div>{% endif %}
        <form method="POST">
            <label style="font-size:0.8rem;color:#8b949e">Username</label>
            <input type="text" name="username" placeholder="j.lee" required>
            <label style="font-size:0.8rem;color:#8b949e">Password</label>
            <input type="password" name="password" required>
            <button type="submit" style="width:100%">Sign In</button>
        </form>
        <div class="finding" style="margin-top:1rem">
            ⚠️ LAB CREDS: admin/admin123 | j.lee/Password1 | a.nguyen/Password1
        </div>
    </div>
</div>
{% endblock %}
HTML

cat > /opt/csfc-app/templates/dashboard.html <<'HTML'
{% extends 'base.html' %}
{% block content %}
<div class="container">
    <h1>Dashboard</h1>
    <p style="color:#8b949e">Welcome, {{ user }} — CyberShield Financial Corp Operations Portal</p>
    <div class="stat-grid" style="margin:1.5rem 0">
        <div class="stat"><div class="num">{{ total_customers }}</div><div class="lbl">Total Customers</div></div>
        <div class="stat"><div class="num" style="color:#34d399">${{ total_aum }}</div><div class="lbl">Assets Under Management</div></div>
        <div class="stat"><div class="num" style="color:#f87171">{{ suspicious_count }}</div><div class="lbl">🚨 Suspicious Transactions</div></div>
        <div class="stat"><div class="num" style="color:#fbbf24">{{ recent_txns }}</div><div class="lbl">Transactions (30 days)</div></div>
    </div>
    <div class="card">
        <h2>🔴 Security Findings (Lab Exercise)</h2>
        <div class="finding">CRITICAL: This portal has NO MFA — anyone with credentials can log in</div>
        <div class="finding">CRITICAL: SQL Injection in /customers?search= endpoint</div>
        <div class="finding">CRITICAL: /api/customers returns SSN and DOB with NO authentication</div>
        <div class="finding">CRITICAL: /api/cards returns full PAN and CVV with NO authentication</div>
        <div class="finding">HIGH: CVV stored in database (PCI-DSS prohibits this)</div>
        <div class="finding">HIGH: Full PAN stored unmasked (PCI-DSS Req 3 violation)</div>
        <div class="finding">MEDIUM: Debug mode enabled in production (Flask)</div>
        <div class="finding">MEDIUM: Hardcoded credentials in app.py</div>
        <p style="font-size:0.8rem;color:#8b949e;margin-top:1rem">
            Your GRC task: Document each finding with severity, control mapping (PCI-DSS/NIST), business impact, and remediation steps.
        </p>
    </div>
</div>
{% endblock %}
HTML

cat > /opt/csfc-app/templates/customers.html <<'HTML'
{% extends 'base.html' %}
{% block content %}
<div class="container">
    <h1>Customer Database</h1>
    <form style="margin-bottom:1rem">
        <input type="text" name="search" value="{{ search }}" placeholder="Search customers... (try: ' OR 1=1 --)" style="max-width:400px;display:inline-block;width:auto">
        <button type="submit">Search</button>
        <span style="font-size:0.75rem;color:#f87171;margin-left:1rem">⚠️ SQL Injection vulnerable endpoint</span>
    </form>
    <div class="card">
        <table>
            <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Account</th><th>Balance</th><th>Risk</th><th>Action</th></tr></thead>
            <tbody>
            {% for c in customers %}
            <tr>
                <td>{{ c[0] }}</td>
                <td>{{ c[1] }} {{ c[2] }}</td>
                <td>{{ c[3] }}</td>
                <td style="font-family:monospace">{{ c[4] }}</td>
                <td>${{ "{:,.2f}".format(c[5]) }}</td>
                <td><span class="badge-{% if c[6]=='HIGH' %}red{% elif c[6]=='MEDIUM' %}amber{% else %}green{% endif %}">{{ c[6] }}</span></td>
                <td><a href="/customer/{{ c[0] }}" style="color:#38bdf8;font-size:0.8rem">View →</a></td>
            </tr>
            {% endfor %}
            </tbody>
        </table>
    </div>
</div>
{% endblock %}
HTML

cat > /opt/csfc-app/templates/suspicious.html <<'HTML'
{% extends 'base.html' %}
{% block content %}
<div class="container">
    <h1>🚨 Suspicious Transactions — AML Review</h1>
    <p style="color:#8b949e">These transactions have been flagged by automated rules. Review for SAR filing requirements.</p>
    <div class="card">
        <table>
            <thead><tr><th>TXN ID</th><th>Customer</th><th>Amount</th><th>Merchant</th><th>Date</th><th>Country</th><th>AML Flag</th></tr></thead>
            <tbody>
            {% for t in transactions %}
            <tr>
                <td style="font-family:monospace">{{ t[0] }}</td>
                <td>{{ t[1] }}</td>
                <td style="color:#f87171">${{ "{:,.2f}".format(t[2]) }} {{ t[3] }}</td>
                <td>{{ t[4] }}</td>
                <td>{{ t[5] }}</td>
                <td><span class="badge-amber">{{ t[6] }}</span></td>
                <td><span class="badge-red">{{ t[7] }}</span></td>
            </tr>
            {% endfor %}
            </tbody>
        </table>
    </div>
</div>
{% endblock %}
HTML

cat > /opt/csfc-app/templates/index.html <<'HTML'
{% extends 'base.html' %}
{% block content %}
<div style="text-align:center;padding:5rem 2rem">
    <h1 style="font-size:2.5rem">🏦 CyberShield Financial Corp</h1>
    <p style="color:#8b949e;font-size:1.1rem">Internal Banking Operations Portal</p>
    <a href="/login" class="btn" style="margin-top:2rem">Employee Login →</a>
    <br><br>
    <p style="font-size:0.8rem;color:#f87171">⚠️ GRC Lab Environment — Intentionally Vulnerable for Training</p>
</div>
{% endblock %}
HTML

cat > /opt/csfc-app/templates/customer_detail.html <<'HTML'
{% extends 'base.html' %}
{% block content %}
<div class="container">
    {% if customer %}
    <h1>{{ customer[1] }} {{ customer[2] }}</h1>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="card">
            <h2>Personal Information</h2>
            <div class="finding">⚠️ PII Data — GDPR Sensitive. SSN visible = finding!</div>
            <table><tr><th>Field</th><th>Value</th></tr>
            <tr><td>Email</td><td>{{ customer[3] }}</td></tr>
            <tr><td>Phone</td><td>{{ customer[4] }}</td></tr>
            <tr><td>DOB</td><td>{{ customer[5] }}</td></tr>
            <tr><td style="color:#f87171"><strong>SSN</strong></td><td style="color:#f87171"><strong>{{ customer[6] }}</strong></td></tr>
            <tr><td>Address</td><td>{{ customer[7] }}, {{ customer[8] }}, {{ customer[9] }}</td></tr>
            <tr><td>Account</td><td>{{ customer[10] }}</td></tr>
            <tr><td>Balance</td><td>${{ "{:,.2f}".format(customer[11]) }}</td></tr>
            <tr><td>Risk Rating</td><td>{{ customer[14] }}</td></tr>
            </table>
        </div>
        <div class="card">
            <h2>Payment Cards</h2>
            <div class="finding">🚨 CRITICAL: Full PAN and CVV exposed — PCI-DSS violation!</div>
            {% for card in cards %}
            <div style="background:#0d1117;border:1px solid #30363d;border-radius:6px;padding:1rem;margin:0.5rem 0">
                <div style="font-family:monospace;color:#38bdf8;font-size:1.1rem">{{ card[2] }}</div>
                <div style="font-size:0.8rem;color:#8b949e">{{ card[3] }} | Exp: {{ card[4] }}/{{ card[5] }}</div>
                <div style="color:#f87171;font-size:0.8rem">CVV: <strong>{{ card[6] }}</strong></div>
            </div>
            {% endfor %}
        </div>
    </div>
    {% endif %}
</div>
{% endblock %}
HTML

# Create systemd service
cat > /etc/systemd/system/csfc-app.service <<'EOF'
[Unit]
Description=CSFC Lab Web Application
After=network.target postgresql.service

[Service]
User=www-data
WorkingDirectory=/opt/csfc-app
ExecStart=/usr/bin/python3 /opt/csfc-app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

chown -R www-data:www-data /opt/csfc-app
systemctl daemon-reload
systemctl enable csfc-app
systemctl start csfc-app

echo -e "${GREEN}    Vulnerable web app running at http://localhost:5000${NC}"

# ── Intentionally vulnerable SSH config ──────────────────────────────────────
echo -e "\n${YELLOW}[+] Configuring SSH with intentional weaknesses...${NC}"
cat >> /etc/ssh/sshd_config <<'EOF'
# CSFC Lab - Intentional Findings
PermitRootLogin yes          # FINDING: Root SSH login enabled
PasswordAuthentication yes   # FINDING: No key-only auth
MaxAuthTries 10              # FINDING: Too many auth tries before lockout
Banner /etc/ssh/csfc-banner
EOF

cat > /etc/ssh/csfc-banner <<'EOF'
##############################################
  CYBERSHIELD FINANCIAL CORP
  Authorised Users Only
  CSFC Internal Systems
  192.168.56.0/24
##############################################
EOF
# FINDING: SSH banner reveals company name and internal IP range

systemctl restart sshd

# ── Create weak FTP service ────────────────────────────────────────────────────
echo -e "\n${YELLOW}[+] Setting up FTP server (intentionally insecure)...${NC}"
cat > /etc/vsftpd.conf <<'EOF'
listen=YES
anonymous_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
# FINDING: Anonymous FTP upload enabled!
# FINDING: No encryption (no SSL/TLS)
EOF
mkdir -p /var/ftp/pub/csfc_reports
echo "CSFC Monthly Report Q3 2024 - CONFIDENTIAL" > /var/ftp/pub/csfc_reports/Q3_report.txt
systemctl enable vsftpd && systemctl restart vsftpd
echo -e "${RED}    [FINDING] Anonymous FTP enabled and writable!${NC}"

# ── Summary ────────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}============================================${NC}"
echo -e "${CYAN} LAB SETUP COMPLETE - ALL FINDINGS${NC}"
echo -e "${CYAN}============================================${NC}"
echo -e "${RED}CRITICAL:${NC}"
echo "  SQL Injection: http://localhost:5000/customers?search=' OR 1=1 --"
echo "  Unauthenticated API: http://localhost:5000/api/customers (SSN exposed)"
echo "  Unauthenticated API: http://localhost:5000/api/cards (Full PAN + CVV)"
echo "  CVV stored in DB: csfc_production.payment_cards"
echo ""
echo -e "${YELLOW}HIGH:${NC}"
echo "  Anonymous FTP writable: ftp://localhost"
echo "  Root SSH login enabled"
echo "  Weak DB passwords: csfc_admin/admin123"
echo "  40 customers with SSN in plain text"
echo "  AML suspicious transactions available for review"
echo ""
echo -e "${GREEN}WEB APP:${NC} http://localhost:5000 (admin/admin123)"
echo -e "${GREEN}DATABASE:${NC} postgresql://csfc_admin:admin123@localhost/csfc_production"
