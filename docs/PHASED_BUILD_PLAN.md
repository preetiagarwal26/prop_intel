# Prop Intel — Phased Build Plan

North-star UI: [`docs/vision.html`](vision.html) (PropVault mockup)

This plan maps the vision to what exists today and defines phased delivery. Each phase is shippable on its own.

---

## Vision recap

**Problem:** Individual investors own properties across multiple PM companies, each with its own tenant portal. Owners track everything in Excel and email — no unified view.

**Product:** Upload documents → AI classifies, links to property, summarizes, and surfaces todos. Over time, aggregate portfolio metrics and rent/lease status without replacing PM software.

**Target user:** Individual investors with 5–50 doors, multi-market, mixed PM/self-managed.

---

## Current state (Phase 0 — Done)

| Capability | Status |
|------------|--------|
| Auth (signup, login, email confirm) | Done |
| PDF upload | Done |
| Document classification (8 types) | Done |
| Manual classification fallback | Done |
| Property address extraction + fuzzy match | Done |
| Human review before save | Done |
| Create property or link to existing | Done |
| Portfolio list (properties + leases + doc counts) | Done |
| Property detail (documents + leases vault) | Done |
| Lease-specific structured extraction | Done (leases only) |

**Not yet built:** AI summaries, todos/action items, portfolio metrics, rent schedule, notifications feed, DOCX, email ingestion, PMS integrations, investment advisor.

---

## Mockup screen → phase map

| PropVault screen | Phase | Notes |
|------------------|-------|-------|
| **Legal Docs AI** (upload + summary + Q&A) | Phase 1–2 | Core wedge; partially started |
| **Properties** (grid + status pills) | Phase 1, 3 | Detail exists; grid + status comes later |
| **Dashboard** (metrics + property list + notifications) | Phase 3–4 | Metrics need data; notifications = Phase 2 |
| **Rent Schedule** | Phase 4 | Needs rent/lease dates + optional PMS |
| **Investment Advisor** | Phase 6+ | Defer — different product surface |
| Mutual Funds / Stocks | Out of scope | Not RE-focused |

---

## Phase 1 — Document intelligence (4–6 weeks)

**Goal:** Every uploaded doc gets a human-readable summary and type-specific extracted fields. This is the primary value prop from the mockup’s “Legal Docs AI” panel.

### Features

1. **AI document summary**
   - New Edge Function: `summarize-document` (or extend `classify-document`)
   - Store `summary` + `key_points[]` + `flags[]` on `documents` table
   - Show summary on property detail + new **Document detail** screen

2. **Type-specific extraction (beyond leases)**
   - Insurance: carrier, policy #, expiry date
   - Utility: provider, amount due, due date
   - Deed: grantor/grantee, recording date
   - Extend review screen fields per type (not lease-only)

3. **Document detail UI**
   - Route: `/property/:id/document/:docId`
   - Summary, extracted metadata, download link
   - “Ask a question about this document” (optional stretch — RAG over doc text)

4. **UX polish**
   - Adopt vision typography/colors incrementally (gold/dark sidebar)
   - Property cards with doc type icons (already partial)

### Schema changes

```sql
alter table documents
  add column summary text,
  add column key_points jsonb default '[]',
  add column flags jsonb default '[]';
```

### Success criteria

- Upload insurance PDF → see expiry date + summary + flag if expiring within 30 days
- Upload lease → summary includes rent, term, notable clauses (mockup-style bullet points)

---

## Phase 2 — Action items / Needs Attention (2–3 weeks)

**Status:** Code complete — deploy migration with `supabase db push`.

**Goal:** Turn extracted dates and flags into a unified todo feed — the mockup’s **Notifications** panel.

### Features

1. **`action_items` table**
   - `property_id`, `document_id`, `type`, `title`, `description`, `due_date`, `severity`, `status` (open/done/dismissed)
   - Auto-created from rules when docs are saved

2. **Rule engine (v1 — deterministic, no ML)**
   | Trigger | Action item |
   |---------|-------------|
   | Lease end date within 30/60/90 days | “Lease expiring — {property}” |
   | Insurance expiry within 30 days | “Insurance expiring” |
   | Utility due date passed | “Utility bill due” |
   | AI flag in document | Surface as warning todo |
   | Manual | User can add/edit/dismiss |

3. **Needs Attention feed**
   - Dashboard widget or dedicated `/attention` route
   - Sort by severity + due date
   - Badge count in nav (mockup: red “3” on Rent Schedule)

4. **Email digest (optional stretch)**
   - Weekly “3 items need your attention” via Supabase Edge + Resend

### Success criteria

- Save lease ending in 14 days → action item appears without manual entry
- Dismiss todo → stays dismissed
- Property detail shows open todos for that property

---

## Phase 3 — Portfolio dashboard (3–4 weeks)

**Status:** In progress — dashboard, metrics, status pills, properties grid.

**Goal:** Mockup **Dashboard** — investor-level overview, not just a property list.

### Features

1. **Portfolio metrics (computed from existing data)**
   - Property count
   - Document count
   - Leases expiring (next 30/60 days)
   - Open action items count
   - *Deferred until Phase 4:* total monthly rent, occupancy, yield (need valuation + rent roll)

2. **Property status pills**
   - Derived: `Rented` / `Lease ending` / `No lease on file` / `Vacant` (manual flag initially)
   - Add optional `occupancy_status` on `properties`

3. **Dashboard layout**
   - Metrics row (4 cards)
   - Properties list with status + yield placeholder
   - Notifications / Needs Attention sidebar
   - Income trend chart → **placeholder or Phase 4** when rent data exists

4. **Properties grid view**
   - Mockup-style card grid at `/properties`
   - Tap → property detail

### Success criteria

- Login → dashboard shows portfolio snapshot + urgent todos
- Replaces bare portfolio list as home (or tabs: Dashboard | Properties)

---

## Phase 4 — Rent & lease operations (4–6 weeks)

**Goal:** Mockup **Rent Schedule** — track rent due, collected, overdue, lease renewals.

### Features

1. **Rent roll (manual + from leases)**
   - `rent_payments` table: property, tenant, amount, due_date, paid_date, status
   - Auto-generate monthly rows from active leases
   - Manual “mark paid” / “overdue”

2. **Rent schedule screen**
   - Calendar/month view of due dates
   - Overdue highlighting (mockup: Harbor Commerce 2d overdue)
   - Export CSV

3. **Lease expiration panel**
   - Dedicated section (mockup right column)
   - CTA: “Send renewal notice” → generates email template (copy/paste, not send)

4. **Portfolio metrics (complete)**
   - Monthly income, collected vs due, occupancy rate
   - Requires rent roll + optional `estimated_value` on properties

### Data entry without PMS

- Primary: extract from uploaded leases/statements
- Secondary: manual rent entry form
- Tertiary (Phase 5): CSV import

### Success criteria

- 5 properties with leases → April rent schedule auto-populated
- Mark payment → dashboard income updates

---

## Phase 5 — Ingestion expansion (4–6 weeks)

**Goal:** Reduce manual upload friction — docs arrive via email and spreadsheets today.

### Features

1. **DOCX support** — parse Word docs same as PDF flow
2. **CSV import** — properties, rent history (template + column mapping UI)
3. **Email ingestion** — dedicated inbox (e.g. `docs@yourdomain.com`) → attachments → classify pipeline
4. **Bulk upload** — multiple PDFs at once, queue processing
5. **OCR for scanned PDFs** — Google Document AI or similar (scoped subset)

### Success criteria

- Forward lease email with PDF attachment → appears in review queue
- Import 20 properties from Excel template

---

## Phase 6 — Integrations & advisor (future)

**Defer until Phases 1–4 prove retention.**

| Feature | Notes |
|---------|-------|
| PMS API connectors | AppFolio, Buildium, etc. — abstraction layer per `requirements.md` |
| Google Sheets sync | Scheduled pull for investors who live in Sheets |
| Investment Advisor | Scoring algorithm from mockup — acquisition tool, not ops |
| Multi-asset (stocks, MF) | Out of scope unless strategic pivot |

---

## Architecture principles (carry through all phases)

1. **Document-first** — PM portals won’t unify; documents will always arrive fragmented
2. **Human-in-the-loop** — AI proposes; user confirms property link and classification
3. **PM-agnostic** — Never require replacing tenant/PM software early
4. **Progressive enrichment** — Property record improves with each uploaded doc
5. **Deterministic todos** — Rules from extracted dates before ML-based “insights”

---

## Recommended build order (summary)

```
Phase 0  ✅  Upload → classify → link property → vault
Phase 1  →  Summaries + type-specific extraction + doc detail
Phase 2  →  Action items / Needs Attention feed
Phase 3  →  Dashboard + property grid + status pills
Phase 4  →  Rent schedule + lease ops + full metrics
Phase 5  →  DOCX, CSV, email ingestion, OCR
Phase 6  →  PMS APIs, investment advisor
```

---

## Phase 1 kickoff checklist (next sprint)

- [x] Migration: `summary`, `key_points`, `flags` on `documents`
- [x] Extend `classify-document` with summary, key points, flags
- [x] Document detail screen + route
- [x] Show summary on property detail document tiles
- [x] Type-specific metadata fields on review screen
- [ ] Deploy migration + redeploy `classify-document` to Supabase
- [ ] Re-upload a doc to populate summaries for existing records

---

## Competitive positioning

| Competitor | Their focus | Prop Intel wedge |
|------------|-------------|------------------|
| Stessa | Accounting, tax, some doc storage | Cross-PM doc intelligence + todos |
| Baselane | Banking + rent collection | PM-agnostic; no bank required |
| PM portals | Tenant/operator workflow | Owner/investor layer on top |

**Win message:** *“Forward your lease. We tell you which property it belongs to, what it means, and what you need to do.”*

---

## Open decisions (discuss before Phase 2)

1. **Property valuation** — manual entry, Zillow API, or skip yield until Phase 4?
2. **Vacancy tracking** — manual status vs inferred from missing rent?
3. **Pricing model** — free tier + Pro (per property or flat)?
4. **Brand** — Prop Intel vs PropVault for production?
