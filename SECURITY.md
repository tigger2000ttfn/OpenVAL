# PHAROLON Security Policy

## Supported Versions

Only the latest stable release receives security patches.

| Version | Supported |
|---|---|
| Latest stable | Yes |
| Previous minor | Security fixes only for 90 days after new release |
| Older versions | No |

## Reporting a Vulnerability

PHAROLON is used in regulated pharmaceutical environments. Security vulnerabilities,
particularly those affecting audit trail integrity, electronic signatures, access
controls, or GxP data, are treated as critical.

**Do not report security vulnerabilities via GitHub Issues.**

Report security vulnerabilities to: **security@pharolon.io**
(or via GitHub's private vulnerability reporting if enabled on the repository)

Include in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment (especially: does it affect audit trail, signatures, or access controls?)
- Suggested fix (if known)

**We will:**
- Acknowledge receipt within 48 hours
- Assess and classify severity within 5 business days
- Provide a timeline for patching
- Credit you in the security advisory (unless you prefer anonymity)
- Notify you before public disclosure

**Critical vulnerabilities** (affecting audit trail, signature bypass, privilege escalation,
or GxP data integrity) will be patched and released as hotfix versions within 7 days of
confirmation, with immediate notification to the community.

## Security Architecture Summary

Key security controls in PHAROLON, for reference by security researchers:

- Audit log: append-only via PostgreSQL Row Level Security. No application-layer bypass.
- Electronic signatures: re-authentication required at signing time. Tokens are one-use.
- Passwords: bcrypt, minimum cost factor 12, minimum 12 characters, 12-version history.
- JWT: 15-minute access tokens, 7-day rotating refresh tokens stored hashed.
- MFA: TOTP (RFC 6238). SMS and email OTP are not supported.
- File storage: files served via authenticated API endpoints, not direct URLs. SHA-256 verified.
- SQL: all queries parameterized via SQLAlchemy. No raw string concatenation.
- Secrets: AES-256 application-layer encryption for sensitive stored values.
