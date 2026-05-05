---
name: security-audit
description: Run a security audit / vulnerability scan on a codebase. Use when asked to audit, pentest, check security, harden, scan for CVEs, review for vulnerabilities, or check OWASP / CWE compliance. Works on any repo — web apps, APIs, CLI tools, libraries.
allowed-tools: Read, Grep, Glob, Bash, Agent, WebFetch
---

# Security Audit

Perform a thorough security audit of the current project (or a specified path). Output a severity-tagged punch list of findings, then offer to fix them in priority order.

## Process

### 1. Scope discovery

Determine what you're auditing:
- Read `package.json`, `composer.json`, `Cargo.toml`, `go.mod`, etc. to understand the stack
- Identify the app type: web app, API, CLI tool, library, mobile app
- Check for deployment configs: `Dockerfile`, `docker-compose.yml`, nginx configs, CI/CD
- Check for `.env.example` or config files to understand what secrets/services are involved
- If the user provided a specific focus area, prioritize that

Do this silently — don't narrate the discovery.

**Exclusions — do NOT audit:**
- `node_modules/`, `vendor/`, `target/`, `dist/`, `build/`, `.next/`, generated code
- `.git/` directory contents (but DO scan git history for secrets — see Agent 2)
- Third-party code under `lib/vendor/` or similar
- Lockfiles (audit them via tooling, don't read line-by-line)

### 2. Code audit

Launch **parallel** Agent subagents — use `Explore` (read-only, fast) with security-focused prompts, or `code-reviewer` if you need it to also flag adjacent code-quality issues. Tell each agent explicitly: "Focus only on the listed CWE classes — do not comment on style, performance, or general quality."

**Skip categories that obviously don't apply.** A pure CLI tool with no network → skip CORS/CSRF/headers. A static site with no backend → skip SQL injection focus. Skip *consciously* and note what you skipped, don't just forget.

Each agent should read ALL relevant source files in scope, not just sample them, and run the relevant static analyzers below when available on the system.

#### Agent 1: Input validation & injection
- **SQL injection** (CWE-89) — raw queries, string interpolation in queries
- **XSS** (CWE-79) — user input rendered in HTML/SVG/templates without escaping
- **Command injection** (CWE-78) — user input in shell commands, `exec`, `Process::run`
- **Path traversal** (CWE-22) — user input in file paths, `readFile`, `join`
- **XXE** (CWE-611) — XML parsing with external entities enabled
- **SSRF** (CWE-918) — user input in URLs fetched server-side
- **Template injection** (CWE-1336) — user input in template strings evaluated server-side
- **Prototype pollution** (CWE-1321) — object merging with user-controlled keys
- **ReDoS** (CWE-1333) — regex with user-controlled input, catastrophic backtracking
- **Insecure deserialization** (CWE-502) — `pickle.loads`, PHP `unserialize`, Java `ObjectInputStream`, `eval`, YAML loaders, `JSON.parse` of attacker-controlled config
- **Mass assignment** (CWE-915) — frameworks that bind request bodies to models without allowlist (Rails `permit`, Laravel `$fillable`, Express bulk assign)
- **Open redirects** (CWE-601) — `?redirect=` / `?next=` params not validated against allowlist
- **Log injection** (CWE-117) — newlines/control chars in logged user input

**Static analyzers (run if installed):** `semgrep --config=auto`, `bandit` (Python), `eslint-plugin-security` (JS/TS), `brakeman` (Rails), `gosec` (Go), `psalm --taint-analysis` (PHP).

#### Agent 2: Authentication, authorization & secrets
- Auth bypass (CWE-287) — missing middleware, broken access control
- **CSRF** (CWE-352) — missing tokens / SameSite on state-changing endpoints
- Hardcoded secrets, API keys, credentials in source (CWE-798)
- **Secrets in git history** — run `gitleaks detect --no-git=false` or `trufflehog git file://.`; also `git log -p -S 'password' -S 'api_key' -S 'BEGIN PRIVATE KEY' --all`
- `.env` files committed or `.gitignore` gaps
- Session management (fixation, token strength, expiry)
- CORS misconfiguration (CWE-942) — wildcard with credentials, reflected origin
- JWT issues (CWE-347) — `none` algorithm, weak secret, no expiry, alg confusion
- Insecure direct object references / IDOR (CWE-639)
- TOCTOU / race conditions (CWE-367) — auth check then use, double-spend, coupon reuse, parallel request bypasses

#### Agent 3: Data handling & cryptography
- Sensitive data exposure (CWE-200) — PII in logs, error messages, responses
- Weak cryptography (CWE-327) — MD5/SHA1 for passwords, ECB mode, small key sizes
- Missing encryption at rest or in transit (CWE-311)
- Insecure randomness (CWE-338) — `Math.random`, `rand()` for security values
- Error messages leaking internals (CWE-209) — stack traces, file paths, SQL errors

#### Agent 4: Dependencies & supply chain
- Run `npm audit`, `pnpm audit`, `composer audit`, `cargo audit`, `pip-audit`, `bundle audit`, `govulncheck`, or equivalent
- Check for unpinned dependencies (wildcard versions)
- Look for abandoned or unmaintained packages
- Check lock file freshness vs declared versions
- Subresource Integrity (SRI) on `<script src="cdn...">` tags

#### Agent 5: Deployment & infrastructure
- Container running as root (CWE-250)
- No resource limits (memory, CPU, PID)
- Exposed ports or debug endpoints in production
- Missing security headers (CWE-693) — HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- TLS configuration (CWE-326) — old protocols, weak ciphers
- File permissions (CWE-732) — world-writable configs, socket permissions
- Network exposure — unnecessary network access between services

#### Agent 6: Resource exhaustion & DoS
- No request body size limits (CWE-770)
- Unbounded file uploads (CWE-434)
- Expensive operations without rate limiting (image processing, PDF generation, zip creation)
- Unbounded queries (no pagination, no limits)
- Regex DoS (CWE-1333)
- Concurrent request amplification (one request triggers many parallel operations)
- Cache poisoning vectors (CWE-444)

### 3. Compile findings

Merge all agent results into a single punch list. For each finding:

```
## [CRITICAL/HIGH/MEDIUM/LOW] — Title

**Location:** `file:line` (or "deployment config" / "nginx" / etc.)
**CWE / OWASP:** CWE-89 / OWASP A03:2021 — Injection
**Attack:** How an attacker exploits this
**Impact:** What they gain (RCE, data leak, DoS, etc.)
**Fix:** Concrete fix (not "add validation" — specify what validation)
```

If exploitability is uncertain, tag the title `[NEEDS REVIEW]` rather than guessing severity. Better to flag for human judgment than to demote a real issue or inflate a non-issue.

#### Severity model

`severity = f(exploitability, impact)` — both axes matter.

| | **Low impact** | **High impact** |
|---|---|---|
| **Easy to exploit** | MEDIUM | CRITICAL |
| **Hard to exploit** | LOW | HIGH |

- **CRITICAL** — Easy + high impact: unauthenticated RCE, public secret leak, trivial auth bypass to admin
- **HIGH** — Hard but high impact, OR easy but moderate impact: authenticated injection, IDOR exposing user data, JWT alg confusion
- **MEDIUM** — Limited impact or requires specific conditions: DoS, info disclosure, missing headers, CSRF on low-value endpoint
- **LOW** — Defense-in-depth, best practice violation, theoretical risk

### 4. Report output

**Lead with an action header**, then the findings.

```
## What you need to do

- **Fix N CRITICAL** before next deploy
- **Review M HIGH** in this session
- **Triage K MEDIUM/LOW** later
- **Skipped categories:** <list, with one-line reason each>

## Findings
<grouped by severity, CRITICAL first>
```

**If findings exceed ~10**, write the full report to `./security-audit-YYYY-MM-DD.md` and post only the action header + summary inline.

After presenting findings, ask: **"Want me to fix these? I'll go CRITICAL → HIGH → MEDIUM → LOW."**

### 5. Fix loop

When fixing:
- Fix one severity level at a time
- Run tests after each fix
- For deployment fixes (nginx, Docker, etc.), explain what needs to change on the server
- **Offer to commit** after each severity level — don't auto-commit (user reviews commits)

### 6. Verification

After fixes are applied:
- Re-run relevant tests
- Verify build still passes
- For web apps: test attack vectors with `curl`/`fetch` to confirm they're blocked — **dev/staging environments only, never production**, and **never with destructive payloads** (don't actually drop a table to confirm SQLi; use a benign probe like `'||1=1--` returning the same response shape)
- Summarize what was fixed and what remains (deferred / `[NEEDS REVIEW]`)

## Checklist reference

Minimum coverage. Skip what's irrelevant, but skip *consciously*.

```
INPUT VALIDATION
[ ] All user input validated/sanitized before use in queries, commands, file paths, HTML output
[ ] Content-Type checking on API endpoints
[ ] Request body size limits enforced
[ ] File upload validation (type, size, name sanitization)
[ ] No insecure deserialization of untrusted data
[ ] Mass assignment guarded by allowlist
[ ] Open redirects validated against allowlist

AUTHENTICATION & AUTHORIZATION
[ ] Auth required on all non-public endpoints
[ ] CSRF tokens on state-changing endpoints (or SameSite=Strict cookies)
[ ] No hardcoded credentials in source OR git history
[ ] Secrets in env vars, not config files committed to git
[ ] Session tokens cryptographically random, httpOnly, secure, SameSite
[ ] All cookies have appropriate Secure / HttpOnly / SameSite flags
[ ] Password hashing uses bcrypt/argon2/scrypt (not MD5/SHA)
[ ] Rate limiting on auth endpoints

DATA HANDLING
[ ] Error responses don't leak internals (stack traces, file paths, SQL)
[ ] Sensitive data not logged
[ ] PII encrypted at rest where required
[ ] HTTPS enforced (redirects, HSTS)

DEPENDENCIES
[ ] No known vulnerabilities in production deps
[ ] No wildcard version pins
[ ] Lock file committed and up to date
[ ] Subresource Integrity (SRI) on CDN-loaded scripts

DEPLOYMENT
[ ] Containers run as non-root
[ ] Resource limits set (memory, CPU, PIDs)
[ ] Security headers present (HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
[ ] TLS 1.2+ only (no TLS 1.0/1.1)
[ ] Debug mode / dev endpoints disabled in production
[ ] Minimal network exposure between services

RESILIENCE
[ ] Rate limiting on expensive endpoints
[ ] Timeouts on external calls
[ ] No unbounded queries or operations
```

## Output format

The audit should be **skimmable in 30 seconds**. Apply these rules to all output:

- **Lead with the action** — what the user must do goes first, under a bold heading. Never bury actions in prose.
- **Bullets over paragraphs** — default to lists. Use prose only when an idea genuinely doesn't decompose.
- **Bold the load-bearing words** — one or two phrases per sentence, not whole lines.
- **Short sentences** — if a sentence runs past ~20 words, split or cut it.
- **Result first, explanation second** — no preamble ("Great question!", "Let me explain...").
- **Group findings by severity** — CRITICAL first, then HIGH → MEDIUM → LOW.
- **No closing summary** unless explicitly asked — the punch list is the deliverable.
