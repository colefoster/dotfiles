# Word list

Substitution lookup from the Google developer documentation style guide. Left column is what to replace; right column is what to write.

## Never use

| Instead of | Write |
|---|---|
| whitelist, blacklist, graylist | allowlist, denylist, provisional list |
| master/slave | primary/replica, primary/secondary, controller/worker, parent/child |
| man-in-the-middle | on-path attacker, person-in-the-middle (PITM) |
| dummy value | placeholder value, sample value |
| sanity check | quick check, confidence check, coherence check |
| crazy, insane, bonkers, nuts | complex, baffling, unexpected, surprising |
| blind to, blind spot | unaware of, ignores, gap |
| cripple, crippled | degrade, limited, broken (name the specific effect) |
| grandfathered | legacy, exempted |
| native (of people) | name the specific group; for software use built-in |
| guys | everyone, folks, people, you all |
| abort | stop, cancel, end, exit |
| kill | stop, cancel, remove, force quit |
| hang | stop responding, freeze |
| segregate | separate, isolate |
| tribal knowledge | institutional knowledge, unwritten knowledge |

## Cut entirely

| Word | Why |
|---|---|
| just | filler; delete it |
| simply, easy, easily, simple | dismisses the reader's difficulty |
| obviously, of course, clearly | same |
| please | slows instructions down |
| note that | delete; the sentence carries itself |
| basically, actually, really | filler |
| currently, at present, at the time of writing | dates the doc |
| new, newest, latest | dates the doc; name a version |
| soon, shortly, in the future, eventually | pre-announces; omit or give a date |

## Replace for clarity

| Instead of | Write |
|---|---|
| e.g. | for example |
| i.e. | that is |
| etc. | finish the list, or start it with "including" |
| aka | also known as |
| via | with, through, by, using |
| and/or | pick one, or write "A, B, or both" |
| utilize | use |
| commence | start |
| in order to | to |
| leverage (verb) | use |
| a number of | some, several, or a count |
| at this point in time | now |
| allows you to, enables you to | lets you |
| access (verb) | see, view, edit, find, use, open |
| execute (a program) | run |
| desire, wish | want |
| terminate | end, stop |
| utilization | use |
| functionality | features, capabilities, or the specific thing |
| leverage, robust, seamless, powerful | describe the actual behaviour |
| regarding, with regard to | about |
| prior to | before |
| subsequent to | after |
| in the event that | if |
| is able to | can |
| there is, there are | rewrite with a real subject |
| we recommend that you should | we recommend that you |
| deprecated | say what it means here: still works but discouraged, or scheduled for removal on a date |

## Define on first use

These read as jargon to most readers. Expand or define them, or pick a plainer term.

| Term | Note |
|---|---|
| canary | define, or write "gradual rollout" |
| nonce | always define; carries unrelated slang meanings |
| hotspot | define the specific performance meaning |
| legacy | say what makes it legacy |
| idempotent | define on first use |
| flag (verb) | prefer "mark" or "report" |
| SLO, SLA, SLI | expand on first use |

## Formatting and capitalization

| Rule | Detail |
|---|---|
| app vs application | app for end-user software; application in formal or enterprise contexts |
| frontend, backend | one word, not hyphenated |
| alpha, beta | lowercase unless part of a product name |
| open source | two words as a noun; hyphenate as a modifier: open-source library |
| email | no hyphen |
| internet | lowercase |
| website, webpage | one word |
| command line | two words as a noun; hyphenate as a modifier: command-line flag |
| set up vs setup | verb is two words; noun and adjective are one |
| log in vs login | same pattern |
| ID | capitalized, not Id or id, outside code |
| CPU, API, URL | no periods |
