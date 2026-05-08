# Security Review Checklist

Apply these checks to **all** files in every diff, regardless of file type. Security findings are always 🔴 Critical or 🟠 Major — never downgrade to Minor.

---

## Injection

### SQL Injection — 🔴 Critical
Any string interpolation or concatenation inside DB query functions is an automatic finding:
- `frappe.db.sql(f"...")`
- `frappe.db.sql("..." % var)`
- `frappe.db.sql("..." + var)`
- `.format()` inside SQL strings

Also flag:
- User input flowing into `ORDER BY`, `GROUP BY`, or `LIMIT` without an allowlist
- Dynamic table names constructed from user input
- Raw SQL in patches/migrations using unsanitized variables

```python
# BAD
frappe.db.sql(f"SELECT * FROM `tabStudent` WHERE name = '{student_id}'")
frappe.db.sql("SELECT * FROM `tabStudent` WHERE name = '%s'" % student_id)

# GOOD
frappe.db.sql("SELECT * FROM `tabStudent` WHERE name = %s", (student_id,))
frappe.db.sql("SELECT * FROM `tabStudent` WHERE name = %(student)s", {"student": student_id})

# BETTER (use the ORM)
frappe.get_all("Student", filters={"name": student_id})
```

### XSS — 🔴 Critical

**Python / Jinja:**
- `{{ variable }}` in Jinja without `| e` or `| sanitize_html` for user-controlled content
- `frappe.respond_as_web_page()` with unsanitized HTML
- `frappe.msgprint()` with HTML built from user input

**JavaScript / Frontend:**
- `innerHTML`, `outerHTML`, `document.write()` with user-controlled data
- `dangerouslySetInnerHTML` in React without sanitization
- `v-html` in Vue with user-controlled data
- jQuery `.html()` with user data

**Remediation:** sanitize with `frappe.utils.sanitize_html()` (Python) or DOMPurify (JS).

### Command Injection — 🔴 Critical
- `os.system()`, `subprocess.call()` with user-controlled arguments
- `eval()`, `exec()` in Python
- `eval()`, `new Function()` in JavaScript
- Shell commands constructed from user input

---

## Authentication & Authorization

### Permission Bypass — 🔴 Critical
- `@frappe.whitelist()` methods that read or write data without `frappe.has_permission()`
- `frappe.get_doc()` returning data to a user without first checking permission
- `ignore_permissions=True` applied globally instead of scoped to one operation
- Missing `frappe.only_for("System Manager")` or role check on admin-only functions

### Session & Auth — 🔴 Critical
- Hardcoded API keys, tokens, passwords, secrets in source
- Credentials in committed config (`.env`, `site_config.json`, `common_site_config.json`)
- Auth tokens logged or printed
- Session tokens exposed in URL parameters
- Missing CSRF token on state-changing requests

### Access Control — 🟠 Major
- Cross-tenant data leak (missing company filter on multi-tenant DocTypes)
- Records accessible/modifiable via crafted API calls the user shouldn't reach
- Missing `user_permission` checks on multi-tenant sensitive data
- Whitelisted method that doesn't verify the caller owns the resource

---

## Data Exposure

### 🔴 Critical
- Sensitive fields (password, salary, SSN, Aadhaar, bank acct) returned without masking
- Stack traces or debug info exposed in production error responses
- Database credentials or connection strings in code or logs

### 🟠 Major
- Verbose error messages revealing internal implementation
- Logging PII / financial data / passwords
- API responses returning more fields than the consumer asked for
- User emails / phone numbers exposed in client-side bundle
- File upload paths predictable or enumerable

---

## File Handling

### 🔴 Critical
- File uploads without type validation (accepting `.py`, `.sh`, `.exe`)
- Path traversal: user-controlled filename in `os.path.join()` without sanitization
- Uploaded files executed or interpreted on the server

### 🟠 Major
- No file size limits on uploads
- Files served without proper Content-Type headers
- Private files accessible without authentication
- No virus/malware-scan consideration on uploads

---

## Cryptography & Secrets

### 🔴 Critical
- Passwords stored in plaintext
- MD5 / SHA1 used for password hashing
- Hardcoded encryption keys or salts
- Custom crypto instead of established libraries

### 🟠 Major
- Secrets in code instead of environment variables or `site_config.json`
- Missing HTTPS enforcement on sensitive endpoints
- Insecure RNG (`random` instead of `secrets`) for security-sensitive purposes

---

## Frappe-specific security

### 🔴 Critical
- `allow_guest=True` on methods that modify data without rate limiting
- Guest-accessible DocType APIs exposing sensitive data
- Custom endpoints bypassing Frappe's CSRF protection

### 🟠 Major
- Missing rate limiting on login / OTP / password-reset endpoints
- `frappe.sendmail` with user-controlled `recipients` (email injection)
- Webhook URLs configurable by non-admin users
- Background jobs running with elevated permissions unnecessarily
- `frappe.get_all` returning data without checking the user's read permission

---

## Dependency & supply chain

### 🟠 Major
- New npm/pip packages added without justification
- Packages with known vulnerabilities (when version-detectable)
- Pinning to `latest` or `*` instead of a specific version
- Packages imported but missing from `requirements.txt` / `package.json`

---

## Quick scan red flags

When skimming a diff, these tokens almost always warrant a closer look:

```
# Python
eval(           exec(           os.system(           subprocess
ignore_permissions    allow_guest       frappe.db.sql(f"     frappe.db.sql("...%
password              secret            token                api_key
.format(              innerHTML

# JavaScript
eval(           innerHTML       dangerouslySetInnerHTML      v-html
document.write  localStorage.getItem("token")
password        secret          api_key                      fetch("http://

# Files
.env            site_config     credentials                  id_rsa
```
