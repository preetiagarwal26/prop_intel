# User Story 2 — Document vault, classification & AI intelligence

**Epic:** Unified property document management for individual investors  
**Status:** Implemented (pending Supabase migration + Edge Function deploy)  
**Vision reference:** [`docs/vision.html`](../vision.html) (PropVault mockup)  
**Roadmap:** [`docs/PHASED_BUILD_PLAN.md`](../PHASED_BUILD_PLAN.md)

---

## User story

**As an** individual real estate investor with properties managed across different PM companies,  
**I want to** upload any property document (lease, deed, insurance, utility bill, etc.), have the app classify it, summarize it, link it to the correct property, and show everything in a property dashboard,  
**So that** I no longer track documents in Excel or log into multiple PM portals to understand what I have and what needs attention.

---

## Problem context

Investors receive leases, insurance renewals, utility bills, and compliance docs from many sources. Each property may use a different property management company with its own tenant portal. Owners lack a single place to:

- Store documents by property
- Know what type of document they uploaded
- See an AI-generated summary and warnings
- Link new docs to an existing property or create a new one

User Story 1 covered lease-only upload. User Story 2 generalizes the platform toward the PropVault vision.

---

## Acceptance criteria

### Document upload & classification

- [x] User can upload a **PDF** from the **Upload Document** screen (not lease-only).
- [x] App calls `classify-document` Edge Function to detect type: lease, deed, insurance, utility, tax, HOA, permit, or other.
- [x] If automatic classification **fails**, user can **manually select document type** and continue to review.
- [x] User can **override document type** on the review screen.
- [x] Low-confidence classifications show a warning to verify type.

### AI document intelligence (Phase 1)

- [x] Classification response includes **summary** (2–3 sentences), **key points** (bullets), and **flags** (info / warning / critical).
- [x] Summary, key points, and flags are **saved** on the document record after review.
- [x] Review screen shows AI summary panel before save (when not manual classification).

### Property linking

- [x] App **fuzzy-matches** extracted address to existing properties.
- [x] Review screen lets user **link to matched property** or **create a new property**.
- [x] **Leases** still create a lease record; other types link document only.
- [x] After save, user lands on **document detail** for the saved doc.

### Property dashboard & document vault

- [x] **Portfolio** lists properties with document counts; cards are tappable.
- [x] **Property detail** shows all uploaded documents and leases for that property.
- [x] Document tiles show type, date, summary snippet, and flag count.
- [x] Tap document → **document detail** with full summary, key points, flags, and extracted metadata.
- [x] User can copy a signed download link for the PDF.

### Type-specific extraction (review)

- [x] Review screen shows **editable fields per document type** (lease dates/rent, insurance expiry, utility due date, deed parties, etc.).

### Auth (supporting)

- [x] Email confirmation uses Flutter route `/auth/confirm` (works with Vercel SPA deploy).

---

## User flows

### Happy path — automatic classification

```
Portfolio → Upload Document → select PDF
  → upload to storage
  → extract PDF text
  → classify-document (type + address + summary + key points + flags)
  → match property
  → Review & Confirm (edit type, property, metadata)
  → Save
  → Document detail page
```

### Fallback — manual classification

```
Upload → classify fails (after retry)
  → "Automatic classification unavailable"
  → user picks document type from dropdown
  → Continue to review (no AI summary)
  → Save → property + document linked
```

### Browse documents

```
Portfolio → tap property
  → Property detail (documents + leases)
  → tap document
  → Document detail (summary, key points, flags, metadata)
```

---

## Features delivered

| Feature | Description |
|---------|-------------|
| Multi-type classification | 8 document types via Gemini |
| Manual classification | Fallback when AI unavailable |
| Property matching | Exact + fuzzy address match |
| Property detail | Document vault per property |
| Document detail | Full AI intelligence view |
| AI summary | Paragraph overview |
| Key points | Bullet list of important facts |
| Flags | Actionable warnings (expiring lease, clauses, etc.) |
| Metadata fields | Type-specific editable fields on review |
| Auth confirm route | `/auth/confirm` for email verification |

---

## Technical implementation

### Database migrations

| Migration | Purpose |
|-----------|---------|
| `20250615000000_document_classification.sql` | `document_type`, `classification_confidence`, `extracted_metadata` |
| `20250622000000_document_intelligence.sql` | `summary`, `key_points`, `flags` |

### Edge Functions

| Function | Purpose |
|----------|---------|
| `classify-document` | Classify type, extract address + metadata, summary, key points, flags |
| `extract-lease` | Legacy lease extraction (still present; upload flow uses `classify-document`) |

### Key app files

```
lib/features/upload/upload_document_screen.dart   # Upload + classify + manual fallback
lib/features/review/review_screen.dart            # Review, metadata, save
lib/features/property/property_detail_screen.dart # Property document vault
lib/features/property/document_detail_screen.dart # Full doc intelligence view
lib/features/shared/document_intelligence_panel.dart
lib/features/shared/document_metadata_fields.dart
lib/features/shared/document_type_field.dart
lib/features/auth/auth_confirm_screen.dart
lib/services/document_classification_service.dart
supabase/functions/classify-document/index.ts
```

### Routes

| Route | Screen |
|-------|--------|
| `/portfolio` | Portfolio list |
| `/upload` | Upload document |
| `/review` | Review & confirm |
| `/property/:id` | Property detail |
| `/property/:id/document/:docId` | Document detail |
| `/auth/confirm` | Email confirmation landing |

### Data model — `documents` table

| Column | Type | Description |
|--------|------|-------------|
| `document_type` | text | lease, deed, insurance, utility, tax, hoa, permit, other |
| `classification_confidence` | numeric | 0–1 AI confidence (1.0 if manual) |
| `extracted_metadata` | jsonb | Type-specific extracted fields |
| `summary` | text | AI overview |
| `key_points` | jsonb | Array of strings |
| `flags` | jsonb | Array of `{ severity, title, description }` |

---

## Deploy checklist

Run after pulling User Story 2 code:

```powershell
# 1. Apply new migrations
supabase db push

# 2. Deploy Edge Function (uses existing GEMINI_API_KEY secret)
supabase functions deploy classify-document

# 3. Vercel — set env var (if not already)
# AUTH_REDIRECT_URL=https://your-app.vercel.app/auth/confirm

# 4. Supabase Auth → URL Configuration
# Redirect URLs: https://your-app.vercel.app/auth/confirm
#                 https://your-app.vercel.app/**

# 5. Push to GitHub → Vercel auto-deploy
```

**Note:** Documents uploaded before this story will not have summaries until re-uploaded.

---

## Test checklist

### Classification & upload

- [ ] Upload `samples/sample_lease.pdf` → classified as **Lease**
- [ ] Review shows summary, key points, and property fields
- [ ] Save → document detail shows AI summary
- [ ] Upload second doc for same address → matches existing property

### Manual classification

- [ ] Simulate classify failure (e.g. disconnect network mid-upload) OR use invalid doc
- [ ] Manual type picker appears
- [ ] Can continue to review and save without AI summary

### Property vault

- [ ] Portfolio shows document count per property
- [ ] Property detail lists all documents
- [ ] Tap document → full detail page
- [ ] Copy download link works

### Non-lease document (optional)

- [ ] Upload insurance or utility PDF
- [ ] Review shows type-specific metadata fields (expiry date, amount due, etc.)
- [ ] Save does **not** create a lease record

### Auth

- [ ] Sign up → email link opens `/auth/confirm` → success message
- [ ] Sign in works after confirmation

---

## Out of scope (User Story 2)

- DOCX upload
- Email ingestion
- Action items / Needs Attention feed (Phase 2)
- Portfolio metrics dashboard (Phase 3)
- Rent schedule (Phase 4)
- PMS integrations
- OCR for scanned PDFs
- “Ask a question about this document” chat

See [`docs/PHASED_BUILD_PLAN.md`](../PHASED_BUILD_PLAN.md) for next phases.

---

## Relationship to User Story 1

| User Story 1 | User Story 2 |
|--------------|--------------|
| Lease PDF only | Any property PDF type |
| `extract-lease` function | `classify-document` function |
| Upload Lease screen | Upload Document screen |
| Portfolio + leases only | Property detail + document vault |
| No AI summary | Summary, key points, flags |
| No manual classification | Manual type fallback |

---

## Related docs

- [Requirements](../requirements.md) — full product requirements
- [Deployment](../DEPLOYMENT.md) — Vercel + Supabase setup
- [Phased build plan](../PHASED_BUILD_PLAN.md) — roadmap Phases 0–6
- [Vision mockup](../vision.html) — PropVault UI reference
