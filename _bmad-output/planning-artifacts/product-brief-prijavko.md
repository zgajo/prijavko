---
title: "Product Brief: Prijavko"
status: complete
created: "2026-04-13T00:00:00Z"
updated: "2026-04-13T00:00:00Z"
inputs:
  - "_bmad-output/brainstorming/brainstorming-session-2026-04-13-212114.md"
  - "_bmad-output/planning-artifacts/research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md"
  - "_bmad-output/planning-artifacts/research/technical-android-evisitor-mrz-queue-evisitor-api-research-2026-04-13.md"
  - "Product brief discovery conversation (2026-04-13)"
---

# Product Brief: Prijavko

## Executive Summary

**Prijavko** is an **Android** app (built with **Flutter**) for **Croatian tourism hosts** who must register guests in the national **eVisitor** system. It targets hosts who operate **multiple accommodation objects under one OIB**—the group that suffers the most from **wrong-object submissions** and context-switching under stress.

The product is a **host-operated compliance tool**: **scan travel documents (MRZ-first)**, **validate data**, **buffer guests in a local queue**, and **submit to eVisitor** in batches. Facility context is chosen **before** scanning (**session-scoped facility**), so the app does not rely on a persistent “which object am I in?” toggle that fails at the door.

**Monetization for v1** is **ads only**—maximize reach and learn stability without payment friction. **First-time submission success rate** is the north-star: proof that capture, validation, and integration work without hosts fixing fields or repeating flows.

Competition includes the **free official eVisitor app**, **mVisitor** (often TZ-subsidized), and **PrijaviTuriste** (feature-rich, metered pricing). Differentiation is **architectural and workflow-shaped**—multi-facility safety, queue + batch send, host-only on-device capture—not a longer feature checklist.

---

## The Problem

Croatian hosts are **legally required** to register guests in eVisitor. The work is **bursty** (peak arrivals), **error-prone** when typing foreign names and document numbers from memory, and **stressful** when system errors are opaque.

For hosts with **several objects on one OIB**, the acute pain is **cognitive and operational**: selecting or remembering the **correct facility** while guests are waiting, then submitting—**wrong-object registration** creates painful corrections and erodes trust in “I already did eVisitor.” Manual web entry offers **no structural guardrail** tying capture to the right object **before** data entry begins.

---

## The Solution

A **mobile-only** app where the host:

1. **Starts a scan session** and **selects the facility** (object) up front—eliminating ambiguous default context.
2. **Chooses document type** (passport vs ID card), **captures a still photo**, and runs an **MRZ-first** pipeline with checksum validation.
3. **Reviews** a card that is read-only when MRZ passes and **editable** when validation fails—blocking send until fields are acceptable.
4. **Accumulates guests** in a **session list**, optionally **re-assigning** facility per guest before send.
5. **Sends in batch** to eVisitor (login deferred until send), with **human-readable Croatian** error mapping and **local history** as proof of attempt/outcome.

**v1 override (product):** **Basic background retry** for send operations so queued work can complete when the eVisitor API or network is temporarily unavailable—supporting “**batch send + local queue**” without requiring the host to babysit every transient failure. **Live capture only**—**no gallery import** remains a deliberate security and scope decision.

---

## What Makes This Different

| Theme | Rationale |
|--------|-----------|
| **Session-scoped facility** | Facility is chosen **before** scanning, reducing wrong-object submits vs “always-on” profile context. |
| **Multi-facility under one OIB** | Primary beachhead: highest **perceived** value where web flows are weakest. |
| **MRZ-first discipline** | Structured data and checksums before fantasy “generic OCR.” |
| **Queue + batch send** | Separates door-side capture from admin send; fits peak arrivals. |
| **Host-only capture** | Clearer GDPR posture than guest-link flows; different trade-off vs mVisitor-style self-entry. |
| **Reliability narrative** | **First-time submission success** as the measurable proof of engineering and UX quality. |

Moat is **honest execution** (speed, errors, stability)—not proprietary API access.

---

## Who This Serves

**Primary (beachhead):** Hosts with **multiple eVisitor objects under one OIB**—apartments, rooms, or mixed units—who need **confident facility selection** and **repeatable batch workflows**.

**Secondary (still served, not the lead story):** High-volume single-object hosts (time savings) and low-volume hosts (deferred login and simplicity)—messaging and acquisition may follow after beachhead proof.

**Non-target for v1:** Guest self-check-in flows, cross-OIB operations, PMS replacement, invoicing/fiscal features.

---

## Success Criteria

**North-star metric: First-time submission success rate**

**Definition (v1):** Share of guest submissions where the **first end-to-end attempt** from completed capture through **successful eVisitor accept** succeeds **without** (a) **manual correction of extracted fields** after the MRZ/validation step, and (b) **abandoning and repeating** the full capture/send cycle for that guest.

*Operational note:* Product and analytics must agree on edge cases (e.g. MRZ fail → host edits → success: counts as **not** first-time per this definition—by design, it signals capture/validation failure modes to improve).

**Supporting signals:** Submit success rate after intentional edits (secondary), Play Store rating/review themes, crash-free sessions, time-to-ready-to-send (diagnostic).

**Business (v1):** Growth of install base, ad inventory and stability, low support burden—**not** revenue maximization.

---

## Scope

**In v1**

- Android, Flutter; MRZ-first static capture; session + facility picker; queue/session list; batch send; encrypted multi-facility credentials; deferred auth; Croatian error mapping; duplicate-scan warning; 30-day local history; **basic background retry on send path**; ads + consent/CMP where required.

**Explicitly out (locked)**

- **Gallery import** (live camera only).
- Guest self-check-in, cross-OIB, web dashboard, rich analytics, iOS.

**Compliance positioning (product copy):** The host remains responsible for meeting legal registration deadlines; the tool **reduces operational error** and **does not replace** statutory obligations.

---

## Vision (2–3 years)

If v1 proves **first-time success** and **multi-facility fit**, the product can deepen **reliability features** (clearer checkout/deregistration support, stronger offline semantics), consider **iOS** from a validated Flutter base, and only then evaluate **paid tiers** or adjacent revenue—**after** ads and scale teach what hosts will pay for.

---

## Risks (executive)

- **€0 competitors** (official app, mVisitor via TZ)—win on **workflow fit** and **measurable** reliability, not price alone.
- **Flutter + eVisitor** (cookies, XML, TLS): mitigate with early integration hardening; Kotlin remains the benchmark for “lowest integration risk.”
- **Regulatory / API churn**: same for all helpers—queue, retry, and transparent errors reduce blast radius.
- **Background retry**: must be bounded (policy on backoff, user-visible state, battery) so it does not become undebuggable “ghost sends.”
