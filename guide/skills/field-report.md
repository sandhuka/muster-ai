# Field Report — Sending Framework Friction Upstream

When the user hits framework friction worth reporting (a confusing halt, a script failure, a
missing knob, a doc gap), you already hold the full report — don't interview them for what you
know. This skill is the drafting shape and the consent gate.

## 1. Draft (framework-level shape ONLY)

Gather without asking: muster version (`cat muster/VERSION`), operating mode, queue step label
(if a run was involved), what failed and what was expected. Then **scrub project-confidential
detail by default**:

- No product names beyond what the user explicitly approves.
- No code, no file contents, no business specifics.
- Project particulars become generic shapes: "a build step in an iOS project" — not the step's
  actual prompt text.

Report shape (the issue body):

```
**Muster version**: <VERSION>
**Operating mode**: manual | assisted | autonomous
**Where**: <generic step/flow shape, e.g. "autonomous run, developer step, post-halt resume">
**What happened**: <2-4 sentences, framework-level>
**Expected**: <1-2 sentences>
```

## 2. Consent Gate — Showing the Exact Payload IS the Consent

Present the **verbatim scrubbed report** via AskUserQuestion — the full report text in the
option's preview/description, options **Send** / **Don't send**. Never send anything the user
hasn't seen character-for-character; "I'll send a summary of what we discussed" is a consent
violation even with a yes.

One framing line sits ABOVE the payload (it never obscures or summarizes what's being sent):

> *Sending this helps every Muster user — it gets triaged against the roadmap, and you'll get a
> GitHub notification when a release resolves it.*

Honesty bound: promise only what the loop actually delivers — triage plus notification of the
outcome via the issue. Never promise the fix will ship or name a version; triage may park or
reject.

## 3. Send

```bash
gh issue create --repo thinkArhant/muster-ai --label field-report \
  --title "<one-line friction summary>" --body "<the approved payload, verbatim>"
```

Confirm with the issue URL — that's their notification subscription.

## 4. Fallback (no `gh`, or unauthenticated)

Print the report for manual filing at `github.com/thinkArhant/muster-ai/issues/new` (label:
`field-report`) and offer a `mailto:` draft as a second option. Never embed or request
credentials — the framework ships without any (public repo; shipped credentials are stolen
credentials).
