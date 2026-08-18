---
name: portfolio-fit
description: Judge whether the current project belongs on Cole's portfolio — how finished it is, whether it adds anything the site doesn't already have, and exactly what to fix to make it worth showing. Use when asked if a project is portfolio-worthy, good enough to show, ready to feature, worth adding to the site, or what it would take to get it there.
argument-hint: "[path — optional, defaults to the current project]"
---

# Portfolio fit

$ARGUMENTS

Decide whether this project earns a place on colefoster.ca, and say what would change the answer.

The portfolio is a claim about what Cole chooses to stand behind. Every entry that does not earn its place makes the entries around it read as padding, so the useful output of this skill is often **no** plus a short list of what would turn it into a yes.

Judge from measurements, never from the README's self-description. A README describes intent; the repo is what exists.

## 1. Measure

Run these in the project. Report the raw numbers — they feed every axis below.

```bash
git rev-list --count HEAD                      # commits
git log -1 --format=%cI                        # last activity
tokei . --exclude vendor --exclude third_party --exclude node_modules \
        --exclude dist --exclude build --output json
```

**Two corrections make the difference between a real number and a flattering one**, and both were found by trusting the raw count first:

- **Vendored trees.** `tokei` honours `.gitignore`, which is a different question from "did you write this". A directory that does not match a generic vendor name still holds somebody else's code — check what the biggest language actually is before believing it. One project here vendored an upstream C++ codebase whole and read as 600k lines until someone looked.
- **Data and prose.** Exclude JSON, XML, SVG, YAML, TOML, Markdown and plain text from both the line count and the language split. Counted raw, a project that ships a dataset reads as 98% JSON, which describes a download rather than the work.

Then establish, by looking rather than by asking:

- Does it run for someone who is not Cole? Find the entry point and the setup path.
- Is there a README that says what it is in the first two sentences?
- Are there tests, and do they pass?
- Is it deployed anywhere reachable?
- `git remote -v` and `gh repo view --json visibility` — is the source public, private, or never pushed?

## 2. Read the current bar

The portfolio owns what is currently on it; this skill owns only the axes. Read, in `~/Dev/portfolio`:

- `data/featured.yaml` — the header states the inclusion test and the claim rules; the entries are the competition.
- `data/taxonomy.yaml` — the closed tag vocabulary, and which domains are already covered.

If that repo is not on this machine, say so and judge the axes anyway — everything except **range** works without it.

## 3. Judge the five axes

**Intent is a gate.** Fail it and the other four do not matter, however good the work inside is.

1. **Intent — was this made to be shown?** Not "is it good", not "is it big". A small thing built deliberately and finished passes. A repo that exists because some other activity needed a home — a workshop, a talk, a place to park configs, a scratchpad for skills — does not, and no amount of polish converts it. Say so plainly and stop.
2. **Claim — is there one declarative sentence, under 70 characters, ending in a period, that carries the whole project to someone who has never heard of it?** Write the sentence. If the best available is a noun phrase ("Rust battle simulator") rather than an assertion ("Every generation of Pokémon, simulated in Rust."), the project is a category, and a page of categories is a card grid with bigger type. A project that resists a claim usually has no single idea yet — that is a finding about the project, not about the writing.
3. **Range — does it add a world the site does not already have?** Cross its subject against the domains in `taxonomy.yaml`. The seventh AI-agent tool earns its place on merit alone; the first aviation project earns it twice. A new domain is the strongest possible argument for a marginal project.
4. **Standing — can a reader inspect it?** Public source is worth more than a private repo, which is worth more than something never pushed. This is not a veto: closed work with a strong claim stays. But if the only thing between this project and public source is an afternoon of removing secrets, that afternoon is the highest-leverage work available.
5. **Substance — do the corrected numbers describe real work?** Two commits and 400 lines is a weekend sketch; report it as one. Commit count and line count are evidence, not a score, and they are only evidence after the corrections in step 1.

## 4. Deliver

Lead with the verdict, in one of three words:

- **Add** — it earns a place now.
- **Nearly** — it will, after a specific list. Order the list by leverage: what single change moves it most.
- **No** — it fails the intent gate, or it is too early to be anything but padding. Say which, in one sentence, and do not soften it into a nearly.

Then, always:

- The corrected numbers, with any vendored or data-heavy tree named.
- The claim sentence you wrote, or why the project resists one.
- What to polish or add, concrete and ordered. "A README whose first sentence says what this is" beats "improve documentation".

On **Add** or **Nearly**, finish with a paste-ready `featured.yaml` entry — slug, tier, status, callsign, stack, tags drawn only from the declared vocabulary, claim, detail, blurb. Match the shape of the entries already in that file.

Every number in it must be one measured here. Never estimate a line count, never guess a repo URL from a slug, and never invent a metric, a user count, or an impact claim — the site's whole credibility is that its numbers are real.
