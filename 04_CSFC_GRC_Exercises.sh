#!/bin/bash
# ==============================================================================
# CYBERSHIELD FINANCIAL CORP - GRC EXERCISE RUNNER
# Run from: Kali Linux (192.168.56.30)
# Purpose: Pre-built scripts for each GRC exercise with expected outputs
# ==============================================================================

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

print_header() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}$1${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}\n"
}

print_finding() {
    local sev="$1"; local msg="$2"
    case $sev in
        CRITICAL) echo -e "  ${RED}[CRITICAL]${NC} $msg" ;;
        HIGH)     echo -e "  ${YELLOW}[HIGH]${NC}     $msg" ;;
        MEDIUM)   echo -e "  ${PURPLE}[MEDIUM]${NC}   $msg" ;;
        INFO)     echo -e "  ${CYAN}[INFO]${NC}     $msg" ;;
        PASS)     echo -e "  ${GREEN}[PASS]${NC}     $msg" ;;
    esac
}

# ─── EXERCISE 1: Network Discovery ──────────────────────────────────────────
exercise_network_discovery() {
    print_header "EXERCISE 1 — Network Discovery & Asset Inventory"
    echo -e "${YELLOW}GRC Purpose:${NC} CIS Control 1 requires a complete, up-to-date asset inventory."
    echo -e "${YELLOW}CSFC Issue:${NC}  Incomplete asset inventory — unknown attack surface (FINDING-007)\n"

    echo -e "${CYAN}[RUNNING] Nmap network discovery scan on 192.168.56.0/24...${NC}"
    echo "Command: nmap -sn -T4 192.168.56.0/24 --oG - | grep 'Up'"
    echo ""
    echo "Simulated output (run with actual nmap when VMs are up):"
    echo "  Host: 192.168.56.1   (VirtualBox Host)         [Host NIC]"
    echo "  Host: 192.168.56.10  (CSFC-DC01)               [Windows Server 2022 - AD/DNS]"
    echo "  Host: 192.168.56.20  (CSFC-WAZUH)              [Ubuntu 22.04 - Wazuh SIEM]"
    echo "  Host: 192.168.56.30  (CSFC-KALI)               [Kali Linux - Analyst WS]"
    echo "  Host: 192.168.56.40  (CSFC-WEBAPPP)            [Ubuntu - Vulnerable App]"
    echo ""

    echo -e "${CYAN}[RUNNING] Port scan on discovered hosts...${NC}"
    echo "Command: nmap -sV -sC -T4 -p 21,22,80,135,139,443,445,1433,3389,5000,5432 192.168.56.10,20,30,40"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│ HOST: 192.168.56.10 (CSFC-DC01 - Windows Server)               │"
    echo "├──────────┬──────────┬───────────────────────────────────────────┤"
    echo "│ PORT     │ STATE    │ SERVICE                                   │"
    echo "├──────────┼──────────┼───────────────────────────────────────────┤"
    echo "│ 53/tcp   │ open     │ dns (Microsoft DNS)                       │"
    echo "│ 88/tcp   │ open     │ kerberos-sec                              │"
    echo "│ 135/tcp  │ open     │ msrpc                                     │"
    echo "│ 139/tcp  │ open     │ netbios-ssn                               │"
    echo "│ 389/tcp  │ open     │ ldap                                      │"
    echo "│ 445/tcp  │ open     │ microsoft-ds (SMB)                        │"
    echo "│ 3268/tcp │ open     │ ldap (GC)                                 │"
    echo "│ 3389/tcp │ open     │ ms-wbt-server (RDP)  ← FINDING: exposed! │"
    echo "└──────────┴──────────┴───────────────────────────────────────────┘"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│ HOST: 192.168.56.40 (CSFC-WEBAPP - Ubuntu)                     │"
    echo "├──────────┬──────────┬───────────────────────────────────────────┤"
    echo "│ 21/tcp   │ open     │ ftp (vsftpd) ← FINDING: anon FTP!        │"
    echo "│ 22/tcp   │ open     │ ssh (OpenSSH)                             │"
    echo "│ 5000/tcp │ open     │ http (Flask debug mode!) ← FINDING!       │"
    echo "│ 5432/tcp │ open     │ postgresql ← FINDING: exposed to network! │"
    echo "└──────────┴──────────┴───────────────────────────────────────────┘"
    echo ""

    print_finding CRITICAL "RDP (3389) exposed on Domain Controller - no firewall rule"
    print_finding CRITICAL "PostgreSQL (5432) accessible from network - should be localhost only"
    print_finding HIGH "FTP running without encryption on webapp server"
    print_finding HIGH "Flask debug mode exposes interactive debugger on port 5000"
    print_finding MEDIUM "3 hosts discovered vs expected 4 - asset inventory incomplete"
    echo ""
    echo -e "${GREEN}📋 DOCUMENT IN RISK REGISTER:${NC} Add as R-07 refinement"
    echo -e "${GREEN}📋 CONTROL MAPPING:${NC} CIS Control 1.1, PCI-DSS 1.2.1, NIST CM-8"
}

# ─── EXERCISE 2: AD Compliance Audit ────────────────────────────────────────
exercise_ad_audit() {
    print_header "EXERCISE 2 — Active Directory Compliance Audit"
    echo -e "${YELLOW}GRC Purpose:${NC} PCI-DSS Req 8 requires strong authentication policies."
    echo -e "${YELLOW}Framework:${NC}  PCI-DSS 8.x, CIS Control 5, NIST AC-2, AC-7\n"

    echo "════ SECTION 1: Password Policy Assessment ════"
    echo ""
    echo "PowerShell Command: Get-ADDefaultDomainPasswordPolicy | Format-List"
    echo ""
    echo "--- CURRENT CSFC AD PASSWORD POLICY ---"
    echo "  MinPasswordLength      : 6        ← FAIL (PCI requires 12+)"
    echo "  PasswordHistoryCount   : 3        ← FAIL (PCI requires 4+)"
    echo "  MaxPasswordAge         : 180 days ← FAIL (PCI requires 90 days)"
    echo "  MinPasswordAge         : 0 days"
    echo "  ComplexityEnabled      : False    ← FAIL (PCI requires complexity)"
    echo "  LockoutThreshold       : 0        ← FAIL (PCI requires lockout after 10 attempts)"
    echo "  LockoutDuration        : 0:00:30"
    echo ""
    print_finding CRITICAL "Minimum password length 6 chars — PCI-DSS 8.2.4 requires 12+"
    print_finding CRITICAL "No account lockout — enables brute force attacks (PCI-DSS 8.3.9)"
    print_finding HIGH "Password complexity disabled — PCI-DSS 8.2.4 requires mixed case+numbers"
    print_finding HIGH "Max password age 180 days — PCI-DSS 8.3.6 requires max 90 days"
    print_finding MEDIUM "Password history only 3 — PCI-DSS 8.3.7 requires 4+ (ISO 27001 says 5)"
    echo ""

    echo "════ SECTION 2: Privileged Account Review ════"
    echo ""
    echo "PowerShell: Get-ADGroupMember 'Domain Admins' | Select Name,SamAccountName"
    echo ""
    echo "  Domain Admins members:"
    echo "  - Administrator      (built-in - OK)"
    echo "  - local.admin        ← CRITICAL: shared admin account!"
    echo "  - svc.appserver      ← CRITICAL: service account in Domain Admins!"
    echo ""
    echo "PowerShell: Get-ADGroupMember 'GRP_CardholderData' | Select Name,SamAccountName"
    echo ""
    echo "  CDE Access Group (PCI-DSS scope):"
    echo "  - j.whitfield (CEO)    - p.sharma (CFO)   - l.chen (Controller)"
    echo "  - d.moss (Accountant)  - c.vega (Analyst)  - o.hussain (Payment)"
    echo "  - dev.c2 (CONTRACTOR!) ← CRITICAL: contractor should NOT have CDE access"
    echo "  - o.employee           ← CRITICAL: terminated employee still in CDE group!"
    echo ""
    print_finding CRITICAL "local.admin (shared account) has Domain Admin privileges"
    print_finding CRITICAL "svc.appserver service account has Domain Admin privileges"
    print_finding CRITICAL "dev.c2 contractor has access to Cardholder Data Environment"
    print_finding CRITICAL "o.employee (terminated) still in CDE group - privilege not revoked"
    echo ""

    echo "════ SECTION 3: Stale & Dormant Accounts ════"
    echo ""
    echo "PowerShell: Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly"
    echo ""
    echo "  Inactive accounts (>90 days no login):"
    echo "  - o.employee    Last login: NEVER   Status: ENABLED ← FINDING: zombie account"
    echo "  - test.user     Last login: NEVER   Status: ENABLED ← FINDING: test account active"
    echo "  - vendor.admin  Last login: NEVER   Status: ENABLED ← FINDING: unused contractor"
    echo ""
    print_finding HIGH "3 inactive/dormant accounts still enabled (PCI-DSS 8.3.7)"
    print_finding HIGH "test.user account has IT Admin rights with no business justification"
    echo ""

    echo -e "${GREEN}📋 REMEDIATION COMMANDS (run after documentation):${NC}"
    echo "  # Fix password policy:"
    echo "  Set-ADDefaultDomainPasswordPolicy -Identity csfc.local \\"
    echo "    -MinPasswordLength 12 -ComplexityEnabled \$true \\"
    echo "    -MaxPasswordAge 90.00:00:00 -PasswordHistoryCount 5 \\"
    echo "    -LockoutThreshold 10 -LockoutDuration 00:30:00"
    echo ""
    echo "  # Remove from Domain Admins:"
    echo "  Remove-ADGroupMember -Identity 'Domain Admins' -Members 'local.admin','svc.appserver'"
    echo ""
    echo "  # Disable terminated/test accounts:"
    echo "  Disable-ADAccount -Identity 'o.employee'"
    echo "  Disable-ADAccount -Identity 'test.user'"
    echo ""
    echo "  # Remove contractor from CDE:"
    echo "  Remove-ADGroupMember -Identity 'GRP_CardholderData' -Members 'dev.c2','o.employee'"
}

# ─── EXERCISE 3: Vulnerability Assessment ───────────────────────────────────
exercise_vuln_scan() {
    print_header "EXERCISE 3 — Vulnerability Assessment (OpenVAS Simulation)"
    echo -e "${YELLOW}GRC Purpose:${NC} PCI-DSS Req 11.3 requires internal vulnerability scans quarterly."
    echo -e "${YELLOW}Framework:${NC}  PCI-DSS 11.3, CIS Control 7, NIST RA-5\n"

    echo "Run OpenVAS scan from Kali:"
    echo "  1. Open browser → https://localhost:9392"
    echo "  2. Scans → Tasks → New Task"
    echo "  3. Target: 192.168.56.0/24, Scan Config: Full and Fast"
    echo "  4. Start Scan (takes 30-60 mins)"
    echo ""
    echo "════ SIMULATED SCAN RESULTS ════"
    echo ""
    echo "┌──────────────────────────────────────────────────────────────────────┐"
    echo "│ HOST: 192.168.56.10 (CSFC-DC01)                                     │"
    echo "├───────────┬────────────┬──────────────────────────────────────────────┤"
    echo "│ CVSS      │ CVE        │ VULNERABILITY                               │"
    echo "├───────────┼────────────┼──────────────────────────────────────────────┤"
    echo "│ 9.8 CRIT  │ CVE-2024-  │ Windows Server Remote Code Execution         │"
    echo "│           │ 38063      │ (netlogon heap overflow)                     │"
    echo "│ 8.8 HIGH  │ CVE-2023-  │ Windows CryptoAPI Spoofing                  │"
    echo "│           │ 36792      │ Allows bypassing certificate validation      │"
    echo "│ 8.1 HIGH  │ CVE-2024-  │ LDAP Remote Code Execution                  │"
    echo "│           │ 30044      │ Unauthenticated via LDAP port 389            │"
    echo "│ 7.5 HIGH  │ CVE-2023-  │ SMB Ghost - EternalBlue variant             │"
    echo "│           │ 28252      │ SMB signing disabled                        │"
    echo "│ 5.9 MED   │ CVE-2024-  │ RDP Exposed - BlueKeep successor variant    │"
    echo "│           │ 21407      │ RDP should not be internet-facing           │"
    echo "└───────────┴────────────┴──────────────────────────────────────────────┘"
    echo ""
    echo "┌──────────────────────────────────────────────────────────────────────┐"
    echo "│ HOST: 192.168.56.40 (CSFC-WEBAPP)                                   │"
    echo "├───────────┬────────────┬──────────────────────────────────────────────┤"
    echo "│ 10.0 CRIT │ Custom     │ SQL Injection in /customers search           │"
    echo "│           │            │ CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H│"
    echo "│ 9.8 CRIT  │ Custom     │ Unauthenticated API returns PAN + CVV        │"
    echo "│ 8.6 HIGH  │ CVE-2023-  │ Flask debug mode RCE via Werkzeug debugger  │"
    echo "│           │ 25577      │ Interactive console accessible at /console  │"
    echo "│ 8.1 HIGH  │ CVE-2021-  │ PostgreSQL Privilege Escalation             │"
    echo "│           │ 3393       │ Running as root user                        │"
    echo "│ 7.5 HIGH  │ Custom     │ Anonymous FTP allows data exfiltration      │"
    echo "│ 5.3 MED   │ CVE-2024-  │ OpenSSH < 9.8 - Username enumeration       │"
    echo "│           │ 6387       │ 'regreSSHion' vulnerability                 │"
    echo "│ 5.0 MED   │ Custom     │ SSH allows root login                       │"
    echo "│ 4.3 MED   │ Custom     │ HTTP (no TLS) on admin portal               │"
    echo "└───────────┴────────────┴──────────────────────────────────────────────┘"
    echo ""
    echo "Summary: 4 Critical | 6 High | 3 Medium | Total Risk Score: CRITICAL"
    echo ""
    echo -e "${GREEN}📋 ADD TO POA&M:${NC}"
    echo "  POA-016: CVE-2024-38063 - Patch Windows Server - CRITICAL - 14 days"
    echo "  POA-017: SQL Injection remediation - CRITICAL - 7 days"
    echo "  POA-018: Remove anonymous FTP - HIGH - 7 days"
    echo "  POA-019: Disable Flask debug mode - HIGH - 3 days"
}

# ─── EXERCISE 4: GDPR Data Discovery ────────────────────────────────────────
exercise_gdpr_discovery() {
    print_header "EXERCISE 4 — GDPR Data Discovery & PII Inventory"
    echo -e "${YELLOW}GRC Purpose:${NC} GDPR Art 30 requires Records of Processing Activities (ROPA)."
    echo -e "${YELLOW}Framework:${NC}  GDPR Art 5, 25, 30, 32 | NIST SP 800-188\n"

    echo "════ PII DATA DISCOVERY SCAN ════"
    echo ""
    echo "Tool: grep/find to locate PII in file system (simulates DLP scan)"
    echo "Command: grep -rI --include='*.csv' --include='*.txt' -l 'SSN\\|DOB\\|passport' /CSFC_Data/"
    echo ""
    echo "DISCOVERED PII LOCATIONS:"
    echo "  📁 C:\\CSFC_Data\\Finance\\Q3_transactions_UNENCRYPTED.csv"
    echo "     Contains: Full PANs (credit card numbers), cardholder names"
    echo "     Records: ~1,000 transactions | Classification: PCI SCOPE + GDPR"
    echo ""
    echo "  📁 C:\\CSFC_Data\\HR\\Salary_Register_2024.csv"
    echo "     Contains: Names, SSNs, DOBs, bank accounts, salary"
    echo "     Records: 50 employees | Classification: GDPR SENSITIVE (Art 9)"
    echo ""
    echo "  📁 C:\\CSFC_Data\\Engineering\\.env.production"
    echo "     Contains: Production DB credentials, AWS keys, payment API keys"
    echo "     Records: 8 credentials | Classification: CONFIDENTIAL"
    echo ""
    echo "  🗄️  csfc_production.customers table"
    echo "     Contains: SSNs, DOBs, addresses, email, phone, bank accounts"
    echo "     Records: 40 customers | Classification: GDPR PERSONAL DATA"
    echo ""
    echo "  🗄️  csfc_production.payment_cards table"
    echo "     Contains: Full PAN, expiry, CVV, cardholder name"
    echo "     Records: 10 cards | Classification: PCI CARDHOLDER DATA"
    echo ""

    echo "════ GDPR VIOLATIONS FOUND ════"
    print_finding CRITICAL "SSNs stored in plain text in database (GDPR Art 5(1)(f) - integrity)"
    print_finding CRITICAL "CVV values stored in payment_cards (PCI-DSS + GDPR Art 32)"
    print_finding CRITICAL "Full PANs unmasked in transactions file (GDPR + PCI-DSS 3.4)"
    print_finding HIGH "No data retention policy - how long is customer data kept?"
    print_finding HIGH "HR salary data (special category) not encrypted (GDPR Art 9)"
    print_finding HIGH "No ROPA document exists (GDPR Art 30 requires this)"
    print_finding MEDIUM "No DPO (Data Protection Officer) appointed (check if required)"
    print_finding MEDIUM "Privacy notice not reviewed against GDPR Art 13/14 requirements"
    echo ""

    echo "════ RECORDS OF PROCESSING ACTIVITIES (ROPA) TEMPLATE ════"
    echo ""
    echo "| Activity | Data Types | Purpose | Lawful Basis | Retention | Recipients |"
    echo "|----------|------------|---------|--------------|-----------|------------|"
    echo "| Customer onboarding | Name,email,DOB,SSN | KYC/AML | Legal obligation | 7 years | Regulators |"
    echo "| Payment processing | PAN,expiry | Contract fulfilment | Contract | 5 years (PCI) | Payment processor |"
    echo "| Fraud detection | Txn data,location | Legitimate interest | LI | 3 years | Internal only |"
    echo "| Employee HR | Salary,SSN,DOB | Employment | Contract | Duration+7yr | HR,Payroll |"
    echo ""
    echo -e "${GREEN}📋 YOUR TASK:${NC} Complete the ROPA for all 8 processing activities at CSFC"
    echo -e "${GREEN}📋 TOOL:${NC} Use the template at /opt/csfc-grc/gap-analysis/ to document findings"
}

# ─── EXERCISE 5: Incident Response Simulation ───────────────────────────────
exercise_incident_response() {
    print_header "EXERCISE 5 — GitHub Credential Leak Incident Response"
    echo -e "${YELLOW}GRC Purpose:${NC} Test Incident Response Plan against NIST SP 800-61 Rev 3."
    echo -e "${YELLOW}Scenario:${NC}   Developer pushed .env.production to public GitHub on Sept 1\n"

    echo "════ INCIDENT TIMELINE ════"
    echo ""
    echo "  T+0:00  Sept 1, 14:23  Developer s.dev commits .env.production to GitHub"
    echo "  T+0:05  Sept 1, 14:28  GitHub Actions CI/CD triggers (first access)"
    echo "  T+2:30  Sept 1, 16:53  External scanner (Shodan) discovers credentials"
    echo "  T+4:00  Sept 1, 18:23  First suspicious DB login: IP 41.66.224.10 (Nigeria)"
    echo "  T+4:01  Sept 1, 18:24  3 rapid transactions inserted by suspect IP (audit_log)"
    echo "  T+6:10  Sept 1, 20:33  Wazuh alert fires: Unusual pattern transactions"
    echo "  T+6:15  Sept 1, 20:38  j.lee (CISO) notified by Wazuh email alert"
    echo "  T+6:30  Sept 1, 20:53  CSFC Incident declared — IRP activated"
    echo "  T+7:00  Sept 1, 21:23  GitHub repo made private, credentials rotated"
    echo "  T+8:00  Sept 1, 22:23  DB connections from 41.66.224.10 blocked"
    echo ""
    echo "════ EVIDENCE TO COLLECT ════"
    echo ""
    echo "  1. Database audit_log showing 41.66.224.10 access:"
    echo "     SELECT * FROM audit_log WHERE ip_address = '41.66.224.10';"
    echo ""
    echo "  2. Suspicious transactions from that IP window:"
    echo "     SELECT * FROM transactions WHERE txn_date BETWEEN '2024-09-01 18:23:00' AND '2024-09-01 18:27:00';"
    echo ""
    echo "  3. Wazuh SIEM alerts timeline:"
    echo "     Wazuh Dashboard → Security Events → filter: 'csfc_critical'"
    echo ""
    echo "  4. Check for data exfiltration:"
    echo "     Was customer PII accessed? Were any bulk SELECTs run?"
    echo "     SELECT * FROM audit_log WHERE action = 'SELECT' AND event_time BETWEEN ..."
    echo ""
    echo "════ NIST 800-61 PHASES EXERCISE ════"
    echo ""
    echo "  PHASE 1 - DETECTION & ANALYSIS:"
    echo "    □ Confirm incident scope - what data was accessible?"
    echo "    □ Identify affected systems and credentials"
    echo "    □ Determine if breach occurred (confirmed access by attacker?)"
    echo "    □ Rate severity: P1/P2/P3?"
    echo ""
    echo "  PHASE 2 - CONTAINMENT:"
    echo "    □ Rotate ALL credentials in .env.production immediately"
    echo "    □ Revoke AWS access keys"
    echo "    □ Block IP 41.66.224.10 in WAF/firewall"
    echo "    □ Invalidate all active JWT tokens"
    echo "    □ Force password reset for all accounts"
    echo ""
    echo "  PHASE 3 - ERADICATION:"
    echo "    □ Remove .env from all git history (git-filter-repo)"
    echo "    □ Scan all repos for other credential leaks"
    echo "    □ Implement git pre-commit hooks to prevent future leaks"
    echo ""
    echo "  PHASE 4 - RECOVERY:"
    echo "    □ Re-enable services with new credentials"
    echo "    □ Monitor for re-exploitation attempts (Wazuh)"
    echo "    □ Verify transactions flagged are fraud vs legitimate"
    echo ""
    echo "  PHASE 5 - POST-INCIDENT:"
    echo "    □ GDPR: Was EU customer data exposed? 72hr notification required!"
    echo "    □ PCI-DSS: Was cardholder data exposed? Notify payment brands"
    echo "    □ Board report: Exec summary within 5 business days"
    echo "    □ Lessons learned: Root cause analysis"
    echo ""
    echo -e "${RED}⏰ GDPR CLOCK:${NC} If EU customer data was accessed, you have 72 hours from"
    echo "   discovery (T+6:15) to notify the supervisory authority!"
    echo "   Deadline: September 4, 20:38 UTC"
}

# ─── EXERCISE 6: SQL Injection Demonstration ────────────────────────────────
exercise_sqli_demo() {
    print_header "EXERCISE 6 — SQL Injection Finding Documentation"
    echo -e "${YELLOW}GRC Purpose:${NC} Document web app vulnerabilities for PCI-DSS Req 6.4 findings."
    echo -e "${YELLOW}Framework:${NC}  PCI-DSS 6.4, NIST SA-11, CIS Control 16\n"

    echo "NOTE: Only test against your OWN lab systems. Never test without authorisation."
    echo ""
    echo "════ SQL INJECTION TESTS (against 192.168.56.40:5000) ════"
    echo ""
    echo "TEST 1: Basic injection to extract all customers"
    echo "  URL: http://192.168.56.40:5000/customers?search=' OR '1'='1"
    echo "  Expected: Returns ALL 40 customer records (bypass filter)"
    echo "  Finding: SQL Injection — attacker can dump entire customer database"
    echo ""
    echo "TEST 2: UNION injection to extract payment cards"
    echo "  URL: http://192.168.56.40:5000/customers?search=' UNION SELECT card_id,card_number,card_type,card_name,cvv,NULL,NULL FROM payment_cards--"
    echo "  Expected: Returns all credit card numbers and CVVs mixed into results"
    echo "  Finding: CRITICAL — Full PAN extraction via SQL injection"
    echo ""
    echo "TEST 3: Unauthenticated API"
    echo "  Command: curl http://192.168.56.40:5000/api/customers | python3 -m json.tool | head -50"
    echo "  Expected: Returns JSON with 40 customers including SSN field"
    echo "  Finding: CRITICAL — API requires no authentication, exposes PII"
    echo ""
    echo "TEST 4: Card data API"
    echo "  Command: curl http://192.168.56.40:5000/api/cards | python3 -m json.tool"
    echo "  Expected: Returns all card numbers, expiry dates, and CVV values"
    echo "  Finding: CRITICAL — PCI-DSS prohibits storage or transmission of CVV"
    echo ""
    echo "════ DOCUMENTATION TEMPLATE ════"
    echo ""
    echo "Finding ID: WEB-001"
    echo "Title: SQL Injection in Customer Search Endpoint"
    echo "Severity: CRITICAL (CVSS 9.8)"
    echo "Component: http://192.168.56.40:5000/customers"
    echo "Parameter: search"
    echo "CWE: CWE-89 (SQL Injection)"
    echo "PCI-DSS: Requirement 6.4.1 - Prevent common vulnerabilities"
    echo "OWASP: A03:2021 - Injection"
    echo "Business Impact: Attacker can extract all 40 customer records, PAN data,"
    echo "                 SSNs, and account balances. Regulatory fines up to €20M (GDPR)"
    echo "                 or loss of payment processing ability (PCI-DSS)."
    echo "Remediation: Use parameterized queries (prepared statements) in all DB calls"
    echo "Evidence: [ATTACH SCREENSHOT OF /customers?search=' OR 1=1--]"
    echo "Verified Fix: Re-test after patch to confirm remediation"
}

# ─── MAIN MENU ───────────────────────────────────────────────────────────────
main_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}CYBERSHIELD FINANCIAL CORP — GRC EXERCISE RUNNER${NC}      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   CyberShield Lab v2.0 | Run from Kali Linux             ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}1${NC} — Network Discovery & Asset Inventory (CIS 1)        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}2${NC} — Active Directory Compliance Audit (PCI-DSS 8)       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}3${NC} — Vulnerability Assessment (PCI-DSS 11, CIS 7)        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}4${NC} — GDPR Data Discovery & PII Inventory (GDPR Art 30)   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}5${NC} — Incident Response Simulation (NIST 800-61)          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}6${NC} — Web App Vulnerability Documentation (PCI-DSS 6.4)   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}7${NC} — Run ALL exercises                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}0${NC} — Exit                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -n "Select exercise [0-7]: "
    read choice
    case $choice in
        1) exercise_network_discovery ;;
        2) exercise_ad_audit ;;
        3) exercise_vuln_scan ;;
        4) exercise_gdpr_discovery ;;
        5) exercise_incident_response ;;
        6) exercise_sqli_demo ;;
        7)
            exercise_network_discovery
            exercise_ad_audit
            exercise_vuln_scan
            exercise_gdpr_discovery
            exercise_incident_response
            exercise_sqli_demo
            ;;
        0) exit 0 ;;
        *) echo "Invalid choice"; sleep 1 ;;
    esac
    echo ""
    echo -n "Press Enter to return to menu..."
    read
    main_menu
}

# Run with argument or show menu
case "${1:-menu}" in
    network)  exercise_network_discovery ;;
    adaudit)  exercise_ad_audit ;;
    vulnscan) exercise_vuln_scan ;;
    gdpr)     exercise_gdpr_discovery ;;
    ir)       exercise_incident_response ;;
    sqli)     exercise_sqli_demo ;;
    all)
        exercise_network_discovery
        exercise_ad_audit
        exercise_vuln_scan
        exercise_gdpr_discovery
        exercise_incident_response
        exercise_sqli_demo
        ;;
    menu|*) main_menu ;;
esac
