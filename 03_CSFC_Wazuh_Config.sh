#!/bin/bash
# ==============================================================================
# CYBERSHIELD FINANCIAL CORP - Wazuh SIEM Custom Rules + Log Population
# Run as: sudo bash on Wazuh Ubuntu server (192.168.56.20)
# Purpose: Inject realistic security events so dashboards show findings
# ==============================================================================

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN} CSFC Wazuh SIEM Configuration${NC}"
echo -e "${CYAN}============================================${NC}"

# ── Custom Wazuh Rules for CSFC ───────────────────────────────────────────────
echo -e "\n${YELLOW}[+] Installing CSFC custom detection rules...${NC}"

cat > /var/ossec/etc/rules/csfc_custom_rules.xml <<'XMLEOF'
<!-- CYBERSHIELD FINANCIAL CORP - Custom Detection Rules -->
<!-- Maps to PCI-DSS, NIST 800-53, CIS Controls -->
<group name="csfc,pci_dss,gdpr,nist">

  <!-- PCI-DSS Req 8: Account Management Violations -->
  <rule id="100001" level="12">
    <if_sid>18107,5402</if_sid>
    <description>PCI-DSS Req 8.2.1: Multiple failed authentications - possible brute force</description>
    <group>authentication_failures,pci_dss_8.1.6,nist_800-53_AC-7</group>
  </rule>

  <rule id="100002" level="14">
    <if_sid>18107</if_sid>
    <match>local.admin|vendor.admin|test.user</match>
    <description>CRITICAL: Shared/generic account login detected - PCI-DSS violation</description>
    <group>pci_dss_8.2.1,nist_800-53_IA-2,csfc_critical</group>
  </rule>

  <rule id="100003" level="10">
    <if_sid>18107</if_sid>
    <match>svc.appserver|svc.db|svc.backup</match>
    <description>Service account interactive login - segregation violation</description>
    <group>pci_dss_8.2.5,nist_800-53_AC-5,csfc_high</group>
  </rule>

  <!-- PCI-DSS Req 10: Audit Logging -->
  <rule id="100010" level="9">
    <if_sid>591,592</if_sid>
    <description>PCI-DSS Req 10.2: Audit log cleared or stopped</description>
    <group>pci_dss_10.7,nist_800-53_AU-9,gdpr_art32</group>
  </rule>

  <!-- PCI-DSS Req 6: Unpatched Systems -->
  <rule id="100020" level="13">
    <match>CVE-2023|CVE-2024</match>
    <description>Known CVE detected on CSFC system - patch management failure</description>
    <group>pci_dss_6.3.3,nist_800-53_SI-2,cis_control_7</group>
  </rule>

  <!-- GDPR: PII Access Outside Business Hours -->
  <rule id="100030" level="11">
    <if_sid>18107,4624</if_sid>
    <time>10 pm - 6 am</time>
    <description>GDPR Art 32: PII database accessed outside business hours</description>
    <group>gdpr_art32,pci_dss_10.2.3,nist_800-53_AC-2</group>
  </rule>

  <!-- CIS Control 5: Privileged Access -->
  <rule id="100040" level="12">
    <if_sid>4728,4732</if_sid>
    <match>Domain Admins|GRP_IT_Admins</match>
    <description>Privileged group membership change - CIS Control 5 violation</description>
    <group>cis_control_5,pci_dss_8.2.7,nist_800-53_AC-6</group>
  </rule>

  <!-- File Integrity: Sensitive Data Access -->
  <rule id="100050" level="13">
    <if_sid>550,554</if_sid>
    <match>Q3_transactions|Salary_Register|.env.production</match>
    <description>CRITICAL: Sensitive file modified or accessed - DLP event</description>
    <group>pci_dss_3.4,gdpr_art5,nist_800-53_MP-3</group>
  </rule>

  <!-- Anomalous Network: Port Scanning -->
  <rule id="100060" level="10">
    <if_sid>40101</if_sid>
    <description>Port scan detected against CSFC infrastructure</description>
    <group>pci_dss_11.4,nist_800-53_SI-4,cis_control_13</group>
  </rule>

  <!-- Vulnerability: Web App Attack -->
  <rule id="100070" level="14">
    <if_sid>31101,31151</if_sid>
    <match>OR 1=1|UNION SELECT|DROP TABLE|script>|../</match>
    <description>CRITICAL: Web application attack - SQL injection or XSS attempt</description>
    <group>pci_dss_6.4,nist_800-53_SI-10,csfc_critical</group>
  </rule>

  <!-- CSFC: Contractor After-Hours Access -->
  <rule id="100080" level="10">
    <if_sid>18107</if_sid>
    <match>vendor.admin|dev.c1|dev.c2</match>
    <time>6 pm - 8 am</time>
    <description>Contractor accessing systems after hours - policy violation</description>
    <group>csfc_medium,pci_dss_8.2.6,nist_800-53_AC-17</group>
  </rule>

</group>
XMLEOF

echo -e "${GREEN}    Custom rules installed${NC}"

# ── Wazuh ossec.conf: Add CDE File Integrity Monitoring ──────────────────────
echo -e "\n${YELLOW}[+] Configuring File Integrity Monitoring for CDE...${NC}"

cat > /var/ossec/etc/shared/default/agent.conf <<'CONFEOF'
<!-- CSFC Agent Configuration - Deployed to all agents -->
<agent_config>

  <!-- File Integrity Monitoring - PCI-DSS Req 11.5 -->
  <syscheck>
    <frequency>3600</frequency>
    <scan_on_start>yes</scan_on_start>

    <!-- Monitor sensitive CSFC data locations -->
    <directories check_all="yes" realtime="yes" report_changes="yes">C:\CSFC_Data\Finance</directories>
    <directories check_all="yes" realtime="yes" report_changes="yes">C:\CSFC_Data\HR</directories>
    <directories check_all="yes" realtime="yes" report_changes="yes">C:\CSFC_Data\Engineering</directories>
    <directories check_all="yes" realtime="yes">C:\Windows\System32\drivers\etc</directories>
    <directories check_all="yes" realtime="yes">C:\Windows\System32\config</directories>

    <!-- Windows Registry Monitoring - PCI-DSS Req 10 -->
    <windows_registry>HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion</windows_registry>
    <windows_registry>HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services</windows_registry>

    <!-- Ignore noisy paths -->
    <ignore>C:\Windows\System32\LogFiles</ignore>
    <ignore>C:\Windows\SoftwareDistribution</ignore>
  </syscheck>

  <!-- Log Collection - PCI-DSS Req 10 -->
  <localfile>
    <log_format>eventchannel</log_format>
    <location>Security</location>
  </localfile>
  <localfile>
    <log_format>eventchannel</log_format>
    <location>System</location>
  </localfile>
  <localfile>
    <log_format>eventchannel</log_format>
    <location>Application</location>
  </localfile>
  <localfile>
    <log_format>eventchannel</log_format>
    <location>Microsoft-Windows-PowerShell/Operational</location>
  </localfile>

  <!-- Vulnerability Detection -->
  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <scan_on_start>yes</scan_on_start>
    <packages>yes</packages>
    <os>yes</os>
    <network>yes</network>
  </wodle>

</agent_config>
CONFEOF

echo -e "${GREEN}    FIM and log collection configured${NC}"

# ── Inject Realistic Log Events for Dashboard Population ─────────────────────
echo -e "\n${YELLOW}[+] Injecting realistic CSFC security events into Wazuh...${NC}"

OSSEC_LOG="/var/ossec/logs/archives/archives.log"
TIMESTAMP=$(date '+%Y %b %d %H:%M:%S')
HOST="CSFC-DC01"

# Inject events to the archives log for dashboard population
inject_event() {
    echo "$1" >> "$OSSEC_LOG" 2>/dev/null || true
}

# Failed logins (PCI-DSS finding)
for i in {1..15}; do
    inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST sshd[1234]: Failed password for local.admin from 192.168.56.30 port 4$i ssh2"
done

inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST sshd[1234]: Failed password for vendor.admin from 10.10.10.55 port 4422 ssh2"
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST sshd[1234]: Accepted password for local.admin from 192.168.56.30 port 4423 ssh2"
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST sshd[1234]: Accepted password for root from 192.168.56.30 port 4424 ssh2"

# Web app SQL injection attempts
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST nginx: 192.168.56.30 - - \"GET /customers?search=%27+OR+1%3D1+-- HTTP/1.1\" 200 4521"
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST nginx: 192.168.56.30 - - \"GET /api/customers HTTP/1.1\" 200 28456"
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST nginx: 192.168.56.30 - - \"GET /api/cards HTTP/1.1\" 200 3421"

# After-hours access
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST sshd[1234]: Accepted password for dev.c1 from 203.45.67.89 port 5566 ssh2"

# File access events  
inject_event "$(date '+%Y %b %d %H:%M:%S') $HOST kernel: audit: type=1400 msg=audit: avc: denied { read } for comm=explorer name=Q3_transactions_UNENCRYPTED.csv"

echo -e "${GREEN}    Security events injected${NC}"

# ── Configure Vulnerability Scanning ─────────────────────────────────────────
echo -e "\n${YELLOW}[+] Configuring vulnerability detection...${NC}"

cat >> /var/ossec/etc/ossec.conf <<'CONFEOF'

<!-- Vulnerability Detection - PCI-DSS Req 6 -->
<vulnerability-detection>
  <enabled>yes</enabled>
  <interval>12h</interval>
  <min_full_scan_interval>6h</min_full_scan_interval>
  <run_on_start>yes</run_on_start>
  <provider name="canonical">
    <enabled>yes</enabled>
    <os>focal</os>
    <os>jammy</os>
    <update_interval>1h</update_interval>
  </provider>
  <provider name="nvd">
    <enabled>yes</enabled>
    <update_interval>1h</update_interval>
  </provider>
  <provider name="msu">
    <enabled>yes</enabled>
    <update_interval>12h</update_interval>
  </provider>
</vulnerability-detection>
CONFEOF

# ── Create GRC Assessment Report Template ─────────────────────────────────────
echo -e "\n${YELLOW}[+] Creating pre-populated GRC finding reports...${NC}"

mkdir -p /opt/csfc-grc/{reports,evidence,poam,gap-analysis}

cat > /opt/csfc-grc/gap-analysis/PCI-DSS-Gap-Analysis-CSFC.md <<'MDEOF'
# CyberShield Financial Corp
# PCI-DSS 4.0 Gap Analysis Report
# Date: Q4 2024 | Analyst: [YOUR NAME] | Status: DRAFT

## Executive Summary
This gap analysis assesses CyberShield Financial Corp against the 12 PCI-DSS 4.0 requirements.
Based on initial assessment, CSFC is **NON-COMPLIANT** with multiple critical requirements.

---

## Requirement 1: Install and Maintain Network Security Controls
| Sub-Req | Description | Status | Evidence | Gap |
|---------|-------------|--------|----------|-----|
| 1.2.1 | Network security controls defined and documented | PARTIAL | No current network policy found | Policy required |
| 1.3.2 | Inbound/outbound traffic restricted to necessary | NON-COMPLIANT | Admin panel (10.0.1.50) accessible from internet | Firewall rule required |
| 1.4.3 | Security controls on portable computing devices | NON-COMPLIANT | No MDM solution | MDM deployment required |

**Finding Count: 3 (1 Critical, 2 High)**

---

## Requirement 2: Apply Secure Configurations
| Sub-Req | Description | Status | Evidence | Gap |
|---------|-------------|--------|----------|-----|
| 2.2.1 | System components configured to prevent misuse | NON-COMPLIANT | Debug mode enabled in Flask app | Disable debug mode |
| 2.2.7 | All non-console admin access encrypted | NON-COMPLIANT | FTP service running without SSL | Replace FTP with SFTP |

**Finding Count: 2 (1 Critical, 1 High)**

---

## Requirement 3: Protect Stored Account Data
| Sub-Req | Description | Status | Evidence | Gap |
|---------|-------------|--------|----------|-----|
| 3.3.1 | SAD not retained after authorization | NON-COMPLIANT | CVV stored in payment_cards table | **CRITICAL - Remove CVV immediately** |
| 3.4.1 | PAN masked when displayed | NON-COMPLIANT | Full PAN visible in web app and API | Masking required (show last 4 only) |
| 3.5.1 | PAN protected with strong cryptography | NON-COMPLIANT | PAN stored in plain text in DB | Encryption at rest required |

**Finding Count: 3 (3 Critical) - IMMEDIATE ACTION REQUIRED**

---

## Requirement 7: Restrict Access to System Components
| Sub-Req | Description | Status | Evidence | Gap |
|---------|-------------|--------|----------|-----|
| 7.2.1 | All access to system components and cardholder data is defined | NON-COMPLIANT | dev.c2 contractor has CDE access | Remove contractor from GRP_CardholderData |
| 7.3.1 | All access to system components and cardholder data controlled via IAM | NON-COMPLIANT | /api/customers and /api/cards require no auth | API authentication required |

**Finding Count: 2 (2 Critical)**

---

## Requirement 8: Identify Users and Authenticate Access
| Sub-Req | Description | Status | Evidence | Gap |
|---------|-------------|--------|----------|-----|
| 8.2.1 | All user IDs and auth factors managed for CDE | NON-COMPLIANT | 45/50 accounts use 'Password1' | Password reset and policy enforcement |
| 8.2.4 | Min password length 12 chars | NON-COMPLIANT | Current minimum: 6 chars | GPO change required |
| 8.3.1 | MFA for all non-console CDE access | NON-COMPLIANT | No MFA on VPN or web app | MFA deployment required |
| 8.3.6 | Passwords changed every 90 days | NON-COMPLIANT | Current max age: 180 days | GPO change required |
| 8.3.9 | Account lockout after 10 failed attempts | NON-COMPLIANT | No lockout configured | GPO change required |
| 8.6.1 | System/app accounts managed via policies | NON-COMPLIANT | svc.appserver in Domain Admins | Remove from admin groups |

**Finding Count: 6 (3 Critical, 3 High)**

---

## Requirement 10: Log and Monitor All Access
| Sub-Req | Description | Status | Evidence | Gap |
|---------|-------------|--------|----------|-----|
| 10.2.1 | Audit logs for CDE access | PARTIAL | Wazuh deployed but audit_log DB table is mutable | Immutable logging required |
| 10.3.2 | Audit log files protected from destruction | NON-COMPLIANT | Security event log 1MB (too small) | Increase to 1GB+, central logging |
| 10.5.1 | Retain audit log history for 12 months | NON-COMPLIANT | No log retention policy configured | Retention policy required |

**Finding Count: 3 (1 High, 2 Medium)**

---

## SUMMARY

| Requirement | Status | Critical | High | Medium |
|-------------|--------|----------|------|--------|
| Req 1 Network Security | NON-COMPLIANT | 1 | 2 | 0 |
| Req 2 Secure Config | NON-COMPLIANT | 1 | 1 | 0 |
| Req 3 Stored Data | NON-COMPLIANT | 3 | 0 | 0 |
| Req 6 Secure Software | NON-COMPLIANT | 2 | 1 | 0 |
| Req 7 Access Restriction | NON-COMPLIANT | 2 | 0 | 0 |
| Req 8 Authentication | NON-COMPLIANT | 3 | 3 | 0 |
| Req 10 Logging | PARTIAL | 0 | 1 | 2 |
| **TOTAL** | **NON-COMPLIANT** | **12** | **8** | **2** |

**Overall PCI-DSS Compliance: 23% — FAIL**

---

## YOUR EXERCISE TASKS:
1. Complete the remaining requirements (4, 5, 9, 11, 12) by reviewing the lab
2. Add evidence column with actual findings from Wazuh dashboard
3. Write remediation steps for each finding
4. Prioritise: fix all Critical findings first
5. Create a POA&M with completion dates
MDEOF

cat > /opt/csfc-grc/poam/CSFC-POAM-2024.md <<'MDEOF'
# CYBERSHIELD FINANCIAL CORP
# Plan of Action & Milestones (POA&M) — Q4 2024
# System: CSFC Production Environment | Owner: Jane Lee (CISO)

| POA&M ID | Finding | Severity | Control | Scheduled Completion | Owner | Status | Resources Needed |
|----------|---------|----------|---------|---------------------|-------|--------|-----------------|
| POA-001 | CVV stored in production database | CRITICAL | PCI-DSS 3.3.1 | 2024-11-01 | Tom Brecker (IT) | OPEN | DB schema change + app update |
| POA-002 | No MFA on VPN | CRITICAL | PCI-DSS 8.3.1 | 2024-11-15 | Alice Nguyen (IT) | OPEN | Duo or Okta MFA licence ~$5k |
| POA-003 | SQL Injection in customer search | CRITICAL | PCI-DSS 6.4 | 2024-11-01 | Liam O'Brien (Dev) | OPEN | Code fix - parameterized queries |
| POA-004 | Unauthenticated API endpoints | CRITICAL | PCI-DSS 6.4 | 2024-11-01 | Liam O'Brien (Dev) | OPEN | API authentication layer |
| POA-005 | Contractor (dev.c2) in CDE | CRITICAL | PCI-DSS 7.2.1 | 2024-10-15 | Alice Nguyen (IT) | OPEN | AD group membership change |
| POA-006 | local.admin in Domain Admins | CRITICAL | PCI-DSS 8.2.1 | 2024-10-15 | Alice Nguyen (IT) | OPEN | Remove from group, disable account |
| POA-007 | Weak password policy (6 chars) | HIGH | PCI-DSS 8.2.4 | 2024-11-01 | Alice Nguyen (IT) | OPEN | GPO change + user comms |
| POA-008 | No account lockout policy | HIGH | PCI-DSS 8.3.9 | 2024-11-01 | Alice Nguyen (IT) | OPEN | GPO change |
| POA-009 | PAN stored unmasked | HIGH | PCI-DSS 3.4.1 | 2024-12-01 | Tom Brecker (IT) | OPEN | DB encryption + masking |
| POA-010 | Terminated employee account active | HIGH | PCI-DSS 8.3.7 | 2024-10-15 | Rachel Thompson (HR) | OPEN | Disable o.employee account |
| POA-011 | Service accounts have admin rights | HIGH | PCI-DSS 8.6.1 | 2024-11-15 | Alice Nguyen (IT) | OPEN | Remove svc accounts from admins |
| POA-012 | Anonymous FTP enabled | HIGH | PCI-DSS 2.2.1 | 2024-11-01 | Tom Brecker (IT) | OPEN | Disable vsftpd anonymous |
| POA-013 | Security event log 1MB | MEDIUM | PCI-DSS 10.3.2 | 2024-12-01 | Alice Nguyen (IT) | OPEN | Increase to 1GB, configure SIEM |
| POA-014 | Password max age 180 days | MEDIUM | PCI-DSS 8.3.6 | 2024-11-01 | Alice Nguyen (IT) | OPEN | GPO change |
| POA-015 | SSH banner reveals internal IPs | MEDIUM | PCI-DSS 2.2.1 | 2024-12-01 | Tom Brecker (IT) | OPEN | Update sshd banner |

## INSTRUCTIONS FOR YOUR EXERCISE:
1. Work through each POA&M item in the lab
2. Change Status from OPEN to IN-PROGRESS as you work on it
3. Add "Actual Completion" date and notes when done
4. Update "Evidence" column with screenshots/commands used
5. Present completed POA&M to your "CISO" (yourself) at the end
MDEOF

systemctl restart wazuh-manager 2>/dev/null || true

echo -e "\n${CYAN}============================================${NC}"
echo -e "${CYAN} WAZUH CONFIGURED - SUMMARY${NC}"
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}Custom rules:${NC} /var/ossec/etc/rules/csfc_custom_rules.xml"
echo -e "${GREEN}GRC documents:${NC} /opt/csfc-grc/"
echo -e "${GREEN}Gap analysis:${NC} /opt/csfc-grc/gap-analysis/PCI-DSS-Gap-Analysis-CSFC.md"
echo -e "${GREEN}POA&M:${NC} /opt/csfc-grc/poam/CSFC-POAM-2024.md"
echo ""
echo "Wazuh Dashboard: https://192.168.56.20"
echo "Check: Security → Regulatory Compliance → PCI DSS"
echo ""
