# security-audit

A Claude Code skill that performs a thorough, parallelized security audit of any codebase and produces a severity-tagged punch list of findings.

## What it does

- **Scope discovery** — detects stack, app type, and deployment surface
- **6 parallel audit agents** covering injection, auth, crypto, dependencies, deployment, and DoS
- **CWE / OWASP-tagged findings** with concrete fixes (not "add validation")
- **Severity model** based on exploitability × impact
- **Static analyzer integration** — runs `semgrep`, `bandit`, `brakeman`, `gosec`, `gitleaks`, `npm audit`, etc. when available
- **Skim-optimized output** — action header first, findings grouped by severity
- **Fix loop** — offers to fix findings CRITICAL → HIGH → MEDIUM → LOW
- **Safe verification** — non-destructive probes against dev/staging only

Works on web apps, APIs, CLI tools, libraries, and mobile codebases.

## Install

Clone into your Claude Code skills directory:

```bash
git clone https://github.com/<your-user>/security-audit ~/.claude/skills/security-audit
```

Or symlink from a dotfiles repo:

```bash
ln -s /path/to/your/dotfiles/security-audit ~/.claude/skills/security-audit
```

Then in any Claude Code session:

```
/security-audit
```

…or just ask: *"audit this codebase for security issues"*.

## Example output

```
## What you need to do

- Fix 2 CRITICAL before next deploy
- Review 5 HIGH in this session
- Triage 11 MEDIUM/LOW later
- Skipped: mobile (no mobile code), XXE (no XML parsing)

## Findings

### [CRITICAL] — SQL injection in user search endpoint
**Location:** `src/api/users.ts:47`
**CWE / OWASP:** CWE-89 / OWASP A03:2021 — Injection
**Attack:** `GET /api/users?q='; DROP TABLE users; --`
**Impact:** Full database compromise, RCE via UDF on some configs
**Fix:** Replace string interpolation with parameterized query — use `db.query('SELECT * FROM users WHERE name = $1', [q])` instead of `db.query(`SELECT * FROM users WHERE name = '${q}'`)`
```

## Coverage

| Category | Examples |
|----------|----------|
| **Injection** | SQL, XSS, command, path traversal, XXE, SSRF, template, deserialization, mass assignment, open redirect, log injection, ReDoS |
| **Auth & secrets** | Auth bypass, CSRF, IDOR, JWT issues, hardcoded secrets, secrets in git history, session management, CORS, TOCTOU |
| **Crypto & data** | Weak hashing, insecure randomness, PII leaks, error message disclosure |
| **Dependencies** | Known CVEs, unpinned versions, abandoned packages, missing SRI |
| **Deployment** | Container runs as root, missing security headers, weak TLS, exposed debug endpoints |
| **DoS** | Body size limits, unbounded uploads, expensive operations, unbounded queries, cache poisoning |

Each category maps findings to **CWE IDs** and **OWASP Top 10** entries.

## Configuration

The skill is read-only by default. Its frontmatter restricts it to:

```
allowed-tools: Read, Grep, Glob, Bash, Agent, WebFetch
```

Bash access is needed to run static analyzers. If your environment forbids that, remove `Bash` from `allowed-tools` — the skill will still work but skip the tooling layer.

## What it does NOT do

- Modify code without your explicit approval (it asks before fixing)
- Auto-commit (it offers; you decide)
- Run destructive payloads against your app
- Audit `node_modules/`, `vendor/`, generated code, or other dependencies' source

## License

MIT
