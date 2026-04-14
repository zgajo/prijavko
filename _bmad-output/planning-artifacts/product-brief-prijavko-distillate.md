---
title: "Product Brief Distillate: Prijavko"
type: llm-distillate
source: "product-brief-prijavko.md"
created: "2026-04-13T00:00:00Z"
purpose: "Token-efficient context for downstream PRD creation"
---

# Product Brief Distillate — Prijavko

## Locked product decisions (v1)

- **Beachhead ICP:** Multi-facility hosts **on one OIB** — lead pain = wrong-object / context errors; **session-scoped facility before scan** is the core perceived value vs manual web.
- **North star:** **First-time submission success rate** — first successful eVisitor accept **without** manual field correction after MRZ/validation step **and** without repeating full capture/send cycle for that guest.
- **Monetization:** **Ads-only v1** — grow base, test stability, avoid payment-gateway friction.
- **Capture:** **No gallery import** — live camera only; security + on-site speed focus.
- **New vs 2026-04-13 brainstorm:** **Basic background retry** on **send path** is **IN** for v1 (brainstorm SCAMPER had eliminated “offline auto-retry” / host-only manual send). Rationale: batch send + local queue must deliver “fire and forget” when API/network blips.

## Technical context

- **Stack:** Android-only **Flutter**; eVisitor via **Forms auth + persistent cookies** (e.g. Dio + cookie jar); **ImportTourists**-style XML payloads; local **queue/session** persistence (SQLite/drift-class); **MRZ** TD1/TD3 + checksums; **Keystore**-backed credential encryption.
- **Risk:** Flutter integration parity with cookie/session + camera/MRZ stack — **Week 1–2 spike** validates transport; Kotlin is lower-risk alternative for integration only.
- **Ads:** AdMob-class + **UMP/CMP** for EEA personalization/measurement.

## Scope fence (from brainstorm; still valid except retry)

- **Out v1:** Guest self-check-in, cross-OIB, ML auto-routing guest→unit, invoicing/fiscal, web dashboard, general OCR (MRZ-first only), live camera OCR stream (static capture), doc-type auto-detect, multi-device cloud sync, **gallery import**.
- **In v1:** MRZ-only path with edit-on-fail; neutral app → **Start Scanning** picks facility; **Finish session** → session list → **Send All**; deferred login; sound/haptic feedback; Croatian error mapping; **30-day** local history; duplicate scan soft warning (24h).

## Market / competitive (condensed)

- **Substitutes:** Official **eVisitor** app (free), **mVisitor** (TZ-subsidized in places; guest link/QR flows), **PrijaviTuriste** (OCR, packs, invoicing), **PMS** bundles (Chekin/Rentlio class).
- **Wedge:** “Compliance throughput” — **queue + session facility + host-only MRZ**, not feature parity; differentiation must be **measured** (time, errors, first-time success).
- **Macro:** Large short-stay nights in HR (DZS); enforcement/fine framing in industry content — **verify legal copy** with primary sources.

## Rejected / deferred ideas

- **Per brainstorm:** No background auto-retry — **superseded** by explicit v1 decision to add **basic background retry on send** only.
- **Monetization:** Paid subscription / per-registration — **deferred**; ads-first for v1.

## Requirements hints (for PRD)

- **Background retry:** Define bounded behavior — max attempts, backoff, visibility in UI (failed/sending), **no silent infinite loops**; user must still see terminal failure states.
- **Analytics:** Instrument **first-time submission success** funnel precisely (including “edit after MRZ fail” branch).
- **Legal UX:** Persistent disclaimer: host remains responsible for **registration deadlines**; tool is **operational aid**.

## Open questions

- Exact **analytics** definition of “manual correction” (field-level vs screen-level).
- **Retry policy** when credentials expire mid-session vs 503 from eVisitor.
- **Play Store** positioning keywords (Croatian) and review-mining plan for PrijaviTuriste/mVisitor.

## GTM signals (hypothesis)

- Channels: Play ASO, host FB groups, word of mouth; **TZ partnership** only after metrics — incumbents push mVisitor.
