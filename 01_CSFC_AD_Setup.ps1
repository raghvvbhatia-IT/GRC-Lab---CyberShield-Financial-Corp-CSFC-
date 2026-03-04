# ==============================================================================
# CYBERSHIELD FINANCIAL CORP - Active Directory Population Script
# Run as: Administrator on Windows Server 2022 (CSFC-DC01)
# Purpose: Creates realistic company structure with intentional GRC findings
# ==============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CSFC Active Directory Population" -ForegroundColor Cyan
Write-Host " CyberShield Financial Corp Lab Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- STEP 1: Organizational Units ---
Write-Host "[+] Creating Organizational Units..." -ForegroundColor Yellow
$OUs = @("IT-Security","Finance","Engineering","HR","Operations","Executive","ServiceAccounts","Contractors")
foreach ($ou in $OUs) {
    try {
        New-ADOrganizationalUnit -Name $ou -Path "DC=csfc,DC=local" -ProtectedFromAccidentalDeletion $false -ErrorAction Stop
        Write-Host "    Created OU: $ou" -ForegroundColor Green
    } catch { Write-Host "    OU $ou already exists or error: $_" -ForegroundColor DarkYellow }
}

# --- STEP 2: Security Groups ---
Write-Host "`n[+] Creating Security Groups..." -ForegroundColor Yellow
$groups = @(
    @{Name="GRP_Executives";       Desc="C-Suite and VP level staff"},
    @{Name="GRP_Finance";          Desc="Finance and accounting team"},
    @{Name="GRP_Engineering";      Desc="Software engineers and developers"},
    @{Name="GRP_IT_Admins";        Desc="IT administrators - elevated privileges"},
    @{Name="GRP_HR";               Desc="Human Resources staff"},
    @{Name="GRP_Operations";       Desc="Operations and support staff"},
    @{Name="GRP_VPN_Users";        Desc="Authorised VPN remote access"},
    @{Name="GRP_CardholderData";   Desc="PCI-DSS - access to cardholder data environment"},
    @{Name="GRP_Contractors";      Desc="External contractors - limited access"},
    @{Name="GRP_ServiceAccounts";  Desc="Application service accounts"}
)
foreach ($g in $groups) {
    try {
        New-ADGroup -Name $g.Name -GroupScope Global -GroupCategory Security `
            -Description $g.Desc -Path "DC=csfc,DC=local" -ErrorAction Stop
        Write-Host "    Created: $($g.Name)" -ForegroundColor Green
    } catch { Write-Host "    Group $($g.Name): $_" -ForegroundColor DarkYellow }
}

# --- STEP 3: User Accounts (50 realistic employees) ---
Write-Host "`n[+] Creating 50 CSFC employee accounts..." -ForegroundColor Yellow

$defaultPass = ConvertTo-SecureString "Password1" -AsPlainText -Force   # WEAK - intentional finding
$strongPass  = ConvertTo-SecureString "C$FC@dm1n2024!" -AsPlainText -Force

$users = @(
    # EXECUTIVE TEAM
    @{Name="James Whitfield";  Sam="j.whitfield";  Title="Chief Executive Officer";          Dept="Executive";     OU="Executive";       Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Executives","GRP_VPN_Users","GRP_CardholderData")},
    @{Name="Priya Sharma";     Sam="p.sharma";     Title="Chief Financial Officer";           Dept="Finance";       OU="Executive";       Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Executives","GRP_Finance","GRP_CardholderData")},
    @{Name="Jane Lee";         Sam="j.lee";        Title="Chief Information Security Officer";Dept="IT Security";   OU="IT-Security";     Pass=$strongPass;  Enabled=$true;  Groups=@("GRP_Executives","GRP_IT_Admins","GRP_VPN_Users")},
    @{Name="Marcus Reed";      Sam="m.reed";       Title="Chief Technology Officer";          Dept="Engineering";   OU="Executive";       Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Executives","GRP_Engineering","GRP_VPN_Users")},
    @{Name="Diane Holloway";   Sam="d.holloway";   Title="Chief Operating Officer";           Dept="Operations";    OU="Executive";       Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Executives","GRP_Operations")},

    # IT SECURITY
    @{Name="Alice Nguyen";     Sam="a.nguyen";     Title="Senior Systems Administrator";      Dept="IT Security";   OU="IT-Security";     Pass=$strongPass;  Enabled=$true;  Groups=@("GRP_IT_Admins","GRP_VPN_Users")},
    @{Name="Tom Brecker";      Sam="t.brecker";    Title="Network Engineer";                  Dept="IT Security";   OU="IT-Security";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_IT_Admins","GRP_VPN_Users")},
    @{Name="Keisha Okafor";    Sam="k.okafor";     Title="Security Analyst";                  Dept="IT Security";   OU="IT-Security";     Pass=$strongPass;  Enabled=$true;  Groups=@("GRP_IT_Admins")},
    @{Name="Raj Patel";        Sam="r.patel";      Title="Cloud Infrastructure Engineer";     Dept="IT Security";   OU="IT-Security";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_IT_Admins","GRP_VPN_Users")},
    @{Name="Sam Ortega";       Sam="s.ortega";     Title="Help Desk Lead";                    Dept="IT Security";   OU="IT-Security";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_IT_Admins")},

    # FINANCE
    @{Name="Linda Chen";       Sam="l.chen";       Title="Controller";                        Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance","GRP_CardholderData")},
    @{Name="Derek Moss";       Sam="d.moss";       Title="Senior Accountant";                 Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance","GRP_CardholderData")},
    @{Name="Fatima Al-Hassan"; Sam="f.alhassan";   Title="Accounts Payable Specialist";       Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance")},
    @{Name="Carlos Vega";      Sam="c.vega";       Title="Financial Analyst";                 Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance","GRP_CardholderData")},
    @{Name="Sophie Turner";    Sam="s.turner";     Title="Payroll Manager";                   Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance")},

    # ENGINEERING
    @{Name="Liam O'Brien";     Sam="l.obrien";     Title="Lead Software Engineer";            Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering","GRP_VPN_Users")},
    @{Name="Nina Kowalski";    Sam="n.kowalski";   Title="Backend Developer";                 Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering","GRP_VPN_Users")},
    @{Name="Aaron Kim";        Sam="a.kim";        Title="Frontend Developer";                Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering")},
    @{Name="Zoe Blackwood";    Sam="z.blackwood";  Title="DevOps Engineer";                   Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering","GRP_IT_Admins","GRP_VPN_Users")},
    @{Name="Ethan Park";       Sam="e.park";       Title="QA Engineer";                       Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering")},
    @{Name="Mia Rodriguez";    Sam="m.rodriguez";  Title="Data Engineer";                     Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering","GRP_VPN_Users")},
    @{Name="Hassan Ibrahim";   Sam="h.ibrahim";    Title="Mobile Developer";                  Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering")},

    # HR
    @{Name="Rachel Thompson";  Sam="r.thompson";   Title="HR Director";                       Dept="HR";            OU="HR";              Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_HR")},
    @{Name="Ben Nakamura";     Sam="b.nakamura";   Title="HR Business Partner";               Dept="HR";            OU="HR";              Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_HR")},
    @{Name="Grace Williams";   Sam="g.williams";   Title="Recruitment Specialist";            Dept="HR";            OU="HR";              Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_HR")},
    @{Name="Leo Martinez";     Sam="l.martinez";   Title="Training & Development";            Dept="HR";            OU="HR";              Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_HR")},

    # OPERATIONS
    @{Name="Sarah Fitzpatrick";Sam="s.fitzpatrick";Title="Operations Manager";                Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="Mike Dunbar";      Sam="m.dunbar";     Title="Customer Support Lead";             Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="Anna Petrov";      Sam="a.petrov";     Title="Business Analyst";                  Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="James Cooper";     Sam="j.cooper";     Title="Compliance Coordinator";            Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="Chloe Davis";      Sam="c.davis";      Title="Project Manager";                   Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},

    # CONTRACTORS (known GRC risk - excessive access)
    @{Name="Vendor Admin";     Sam="vendor.admin"; Title="External IT Contractor";            Dept="Contractors";   OU="Contractors";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Contractors","GRP_IT_Admins")},  # FINDING: contractor in IT Admins!
    @{Name="Dev Contractor1";  Sam="dev.c1";       Title="Contract Developer";                Dept="Contractors";   OU="Contractors";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Contractors","GRP_Engineering")},
    @{Name="Dev Contractor2";  Sam="dev.c2";       Title="Contract Developer";                Dept="Contractors";   OU="Contractors";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Contractors","GRP_Engineering","GRP_CardholderData")},  # FINDING: contractor with CDE access!

    # SERVICE ACCOUNTS (weak passwords - intentional findings)
    @{Name="SVC AppServer";    Sam="svc.appserver";Title="Application Server Service";        Dept="Service";       OU="ServiceAccounts"; Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_ServiceAccounts","GRP_IT_Admins")},  # FINDING: svc acct in admins!
    @{Name="SVC Database";     Sam="svc.db";       Title="Database Service Account";          Dept="Service";       OU="ServiceAccounts"; Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_ServiceAccounts")},
    @{Name="SVC Backup";       Sam="svc.backup";   Title="Backup Service Account";            Dept="Service";       OU="ServiceAccounts"; Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_ServiceAccounts","GRP_IT_Admins")},

    # STALE/DORMANT ACCOUNTS (intentional findings)
    @{Name="Old Employee";     Sam="o.employee";   Title="Former Finance Analyst";            Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance","GRP_CardholderData")},  # FINDING: terminated employee still active!
    @{Name="Test User";        Sam="test.user";    Title="Test Account";                      Dept="IT Security";   OU="IT-Security";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_IT_Admins")},  # FINDING: test account with admin rights!
    @{Name="Admin Local";      Sam="local.admin";  Title="Local Admin Account";               Dept="IT Security";   OU="IT-Security";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_IT_Admins","Domain Admins")},  # CRITICAL FINDING: shared admin!

    # REGULAR STAFF (fill out to ~50)
    @{Name="Omar Hussain";     Sam="o.hussain";    Title="Payment Processor";                 Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance","GRP_CardholderData")},
    @{Name="Tanya Green";      Sam="t.green";      Title="Customer Relations";                Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="Paul Simmons";     Sam="p.simmons";    Title="Risk Analyst";                      Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="Irene Volkov";     Sam="i.volkov";     Title="Data Scientist";                    Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering")},
    @{Name="Noel Baptiste";    Sam="n.baptiste";   Title="Integration Engineer";              Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering","GRP_VPN_Users")},
    @{Name="Wendy Frost";      Sam="w.frost";      Title="Payroll Analyst";                   Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance")},
    @{Name="George Banks";     Sam="g.banks";      Title="IT Support Analyst";                Dept="IT Security";   OU="IT-Security";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_IT_Admins")},
    @{Name="Mei Lin";          Sam="m.lin";        Title="Compliance Analyst";                Dept="Operations";    OU="Operations";      Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Operations")},
    @{Name="Darius Stone";     Sam="d.stone";      Title="Platform Engineer";                 Dept="Engineering";   OU="Engineering";     Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Engineering","GRP_IT_Admins")},
    @{Name="Fiona Walsh";      Sam="f.walsh";      Title="Accounts Receivable";               Dept="Finance";       OU="Finance";         Pass=$defaultPass; Enabled=$true;  Groups=@("GRP_Finance")}
)

$createdCount = 0
foreach ($u in $users) {
    try {
        New-ADUser `
            -Name $u.Name `
            -SamAccountName $u.Sam `
            -UserPrincipalName "$($u.Sam)@csfc.local" `
            -GivenName ($u.Name.Split(' ')[0]) `
            -Surname ($u.Name.Split(' ')[-1]) `
            -Title $u.Title `
            -Department $u.Dept `
            -Company "CyberShield Financial Corp" `
            -OfficePhone "555-$(Get-Random -Min 1000 -Max 9999)" `
            -EmailAddress "$($u.Sam)@cybershieldfinancial.com" `
            -Path "OU=$($u.OU),DC=csfc,DC=local" `
            -AccountPassword $u.Pass `
            -Enabled $u.Enabled `
            -PasswordNeverExpires $true `
            -ChangePasswordAtLogon $false `
            -ErrorAction Stop
        
        # Add to groups
        foreach ($grp in $u.Groups) {
            try { Add-ADGroupMember -Identity $grp -Members $u.Sam -ErrorAction SilentlyContinue } catch {}
        }
        $createdCount++
        Write-Host "    [+] $($u.Name) ($($u.Sam)) - $($u.Title)" -ForegroundColor Green
    } catch {
        Write-Host "    [!] $($u.Name): $_" -ForegroundColor DarkYellow
    }
}
Write-Host "`n    Total users created: $createdCount" -ForegroundColor Cyan

# --- STEP 4: Intentional Policy Misconfigurations (GRC Findings) ---
Write-Host "`n[+] Applying intentionally WEAK security policies (GRC exercise findings)..." -ForegroundColor Red
Write-Host "    These are the problems YOU will find and fix!" -ForegroundColor Yellow

# Weak Domain Password Policy - violates PCI-DSS Req 8, CIS Control 5
Set-ADDefaultDomainPasswordPolicy -Identity csfc.local `
    -MinPasswordLength 6 `
    -PasswordHistoryCount 3 `
    -MaxPasswordAge 180.00:00:00 `
    -MinPasswordAge 0 `
    -ComplexityEnabled $false `
    -LockoutThreshold 0 `
    -LockoutObservationWindow 00:00:30 `
    -LockoutDuration 00:00:30

Write-Host "    [FINDING-001] Weak password policy applied (min 6 chars, no complexity, no lockout)" -ForegroundColor Red
Write-Host "    [FINDING-002] Password history only 3 (PCI requires 4+)" -ForegroundColor Red
Write-Host "    [FINDING-003] Max password age 180 days (PCI requires 90 days)" -ForegroundColor Red
Write-Host "    [FINDING-004] No account lockout configured (brute force possible)" -ForegroundColor Red

# --- STEP 5: Create Audit Trail (Windows Event Log settings - too small) ---
Write-Host "`n[+] Misconfiguring audit logging (intentional finding)..." -ForegroundColor Red
# Set Security log to tiny size - violates PCI-DSS Req 10
$auditPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security",
    "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application"
)
foreach ($path in $auditPaths) {
    try { Set-ItemProperty -Path $path -Name MaxSize -Value 1024 -ErrorAction SilentlyContinue } catch {}
}
Write-Host "    [FINDING-005] Security event log size set to 1MB (should be 1GB+ for PCI)" -ForegroundColor Red

# --- STEP 6: Create Shared Folders with Sensitive Data ---
Write-Host "`n[+] Creating file shares with sensitive data (for DLP exercise)..." -ForegroundColor Yellow

$shareDirs = @(
    "C:\CSFC_Data\Finance",
    "C:\CSFC_Data\HR",
    "C:\CSFC_Data\Engineering",
    "C:\CSFC_Data\Shared"
)
foreach ($dir in $shareDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Finance sensitive files
@"
CYBERSHIELD FINANCIAL CORP - CUSTOMER PAYMENT DATA
=======================================================
RECORD TYPE: TRANSACTION LOG - Q3 2024
CLASSIFICATION: CONFIDENTIAL - PCI DSS SCOPE

Customer_ID, Name, Card_Number, Card_Type, Expiry, CVV, Amount, Date
CUST-00142, James Abernathy, 4532-7891-2345-6789, VISA, 09/26, 847, 1250.00, 2024-09-15
CUST-00143, Maria Santos, 5425-2334-5678-9012, MASTERCARD, 12/25, 392, 890.50, 2024-09-15
CUST-00144, Robert Chen, 3714-496353-98431, AMEX, 03/27, 2847, 3400.00, 2024-09-16
CUST-00145, Emma Wilson, 6011-1234-5678-9012, DISCOVER, 06/26, 591, 425.75, 2024-09-16
CUST-00146, David Okafor, 4916-2345-6789-0123, VISA, 11/25, 273, 675.25, 2024-09-17

*** WARNING: THIS FILE CONTAINS LIVE CARDHOLDER DATA ***
*** PCI-DSS REQUIRES ENCRYPTION AT REST - THIS IS A FINDING ***
"@ | Out-File "C:\CSFC_Data\Finance\Q3_transactions_UNENCRYPTED.csv" -Encoding UTF8

@"
CYBERSHIELD FINANCIAL - ANNUAL SALARY REGISTER 2024
Classification: RESTRICTED - HR USE ONLY

Employee_ID, Name, Department, Salary, BankAccount, SSN, DOB
EMP-001, James Whitfield, Executive, 385000, ACC-9823-7641, 847-23-9134, 1975-03-14
EMP-002, Priya Sharma, Finance, 295000, ACC-4512-8823, 392-67-4521, 1980-07-22
EMP-003, Jane Lee, IT Security, 245000, ACC-7741-2234, 561-89-2347, 1983-11-08
EMP-004, Marcus Reed, Engineering, 265000, ACC-3321-9914, 728-34-8821, 1978-05-30
EMP-005, Alice Nguyen, IT Security, 125000, ACC-6612-4478, 445-92-1183, 1990-02-19
EMP-006, Tom Brecker, IT Security, 115000, ACC-8823-5591, 332-17-8834, 1988-09-11

*** THIS FILE CONTAINS PII - GDPR ARTICLE 5 VIOLATION - NOT ENCRYPTED ***
"@ | Out-File "C:\CSFC_Data\HR\Salary_Register_2024.csv" -Encoding UTF8

@"
CSFC GitHub Repository Credentials - DO NOT COMMIT
====================================================
# Production Database
DB_HOST=prod-db.csfc.internal
DB_USER=csfc_admin
DB_PASS=Pr0dDB@2024!
DB_NAME=csfc_production

# AWS Production
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1

# Payment Gateway
PAYMENT_API_KEY=pk_live_51HnDEKJf9aA3rT8xV2mKpL
PAYMENT_SECRET=sk_live_51HnDEKJf9aA3rT8xV2mKpL9qWrXuYvZtAsBcDe

# JWT Secret (same as prod!)
JWT_SECRET=csfc_super_secret_jwt_key_2024

*** INCIDENT: This was pushed to public GitHub on 2024-09-01 for 6 hours ***
"@ | Out-File "C:\CSFC_Data\Engineering\.env.production" -Encoding UTF8

@"
CSFC NETWORK TOPOLOGY - INTERNAL USE ONLY
==========================================
Production Servers:
- prod-web-01: 10.0.1.10  (IIS, no WAF, exposed to internet)
- prod-web-02: 10.0.1.11  (IIS, no WAF, exposed to internet)  
- prod-db-01:  10.0.1.20  (SQL Server 2019 - unpatched CVE-2023-21704)
- prod-db-02:  10.0.1.21  (SQL Server 2019 - unpatched CVE-2023-21704)
- admin-panel: 10.0.1.50  (No MFA, accessible from internet - FINDING!)

VPN Gateway: vpn.cybershieldfinancial.com (FortiGate - no MFA)
Admin Portal: admin.cybershieldfinancial.com (HTTP not HTTPS - FINDING!)
"@ | Out-File "C:\CSFC_Data\Shared\Network_Topology.txt" -Encoding UTF8

# Create SMB Shares
try { New-SmbShare -Name "CSFC_Finance$" -Path "C:\CSFC_Data\Finance" -FullAccess "CSFC\GRP_Finance","CSFC\GRP_IT_Admins" -ErrorAction Stop } catch {}
try { New-SmbShare -Name "CSFC_HR$"      -Path "C:\CSFC_Data\HR"      -FullAccess "CSFC\GRP_HR","CSFC\GRP_IT_Admins" -ErrorAction Stop } catch {}
try { New-SmbShare -Name "CSFC_Shared"   -Path "C:\CSFC_Data\Shared"  -FullAccess "Everyone" -ErrorAction Stop } catch {} # FINDING: Everyone access!

Write-Host "    [FINDING-006] Unencrypted cardholder data found in Finance share" -ForegroundColor Red
Write-Host "    [FINDING-007] PII (SSN, salary) stored unencrypted in HR share" -ForegroundColor Red
Write-Host "    [FINDING-008] Production credentials found in Engineering share" -ForegroundColor Red
Write-Host "    [FINDING-009] CSFC_Shared mapped to 'Everyone' - no access control" -ForegroundColor Red

# --- SUMMARY ---
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " AD SETUP COMPLETE - FINDINGS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "CRITICAL FINDINGS (Fix immediately):" -ForegroundColor Red
Write-Host "  [C-001] local.admin in Domain Admins (shared admin account)"
Write-Host "  [C-002] svc.appserver service account has Domain Admin rights"
Write-Host "  [C-003] Contractor (dev.c2) has CDE (cardholder data) access"
Write-Host "  [C-004] Production credentials in file share (GitHub incident)"
Write-Host ""
Write-Host "HIGH FINDINGS:" -ForegroundColor Yellow
Write-Host "  [H-001] 45 of 50 accounts use Password1 (weak default)"
Write-Host "  [H-002] No account lockout policy (brute force risk)"
Write-Host "  [H-003] Terminated employee (o.employee) account still active"
Write-Host "  [H-004] test.user account has IT Admin rights"
Write-Host "  [H-005] Unencrypted PAN data in Finance file share"
Write-Host "  [H-006] PII (SSN, DOB, salary) unencrypted in HR share"
Write-Host ""
Write-Host "MEDIUM FINDINGS:" -ForegroundColor Yellow
Write-Host "  [M-001] Password history only 3 (PCI requires 4+)"
Write-Host "  [M-002] Max password age 180 days (PCI requires 90)"
Write-Host "  [M-003] Security event log too small (1MB)"
Write-Host "  [M-004] CSFC_Shared mapped to Everyone"
Write-Host ""
Write-Host "YOUR TASK: Find all of these using GRC tools, document" -ForegroundColor Cyan
Write-Host "them in the risk register, and remediate!" -ForegroundColor Cyan
Write-Host ""
