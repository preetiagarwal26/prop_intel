# User Story 3 — Needs Attention & action items (Phase 2)

**Epic:** Proactive portfolio monitoring  
**Status:** Implemented (pending `supabase db push`)  
**Builds on:** [User Story 2](UserStory2.md)

---

## User story

**As an** investor managing multiple properties,  
**I want** the app to automatically create todos from uploaded documents (expiring leases, due bills, AI flags),  
**So that** I see what needs my attention in one place without tracking dates in Excel.

---

## Acceptance criteria

- [x] `action_items` table with RLS
- [x] Auto-generate items when a document is saved (lease expiry, insurance/permit expiry, utility/tax/HOA due dates, AI flags)
- [x] **Needs Attention** section on Portfolio (top 3 items + badge count)
- [x] Dedicated `/attention` screen with full list
- [x] Property detail shows open action items for that property
- [x] User can **Mark done** or **Dismiss** an item
- [x] Dismissed/done items stay closed (not regenerated unless document re-saved)

---

## Rule engine (v1)

| Trigger | Action item |
|---------|-------------|
| Lease end ≤ 14 days | Critical — lease expiring |
| Lease end ≤ 30 days | Warning — lease expiring |
| Lease end ≤ 90 days | Info — lease expiring |
| Insurance/permit expiry ≤ 30 days | Warning/critical |
| Utility/tax/HOA due date overdue | Critical |
| Utility/tax/HOA due within 7 days | Warning |
| Each AI `flag` on document | Matching severity todo |

---

## Technical notes

### Migration

`supabase/migrations/20250623000000_action_items.sql`

### Key files

```
lib/data/models/action_item.dart
lib/services/action_item_generator_service.dart
lib/features/attention/attention_screen.dart
lib/features/shared/action_item_tile.dart
test/action_item_generator_test.dart
```

### Routes

| Route | Screen |
|-------|--------|
| `/attention` | Full Needs Attention feed |
| `/portfolio` | Portfolio + attention preview + notification badge |

---

## Deploy

```powershell
supabase db push
# Redeploy app (Git push → Vercel)
```

Re-save an existing document (or upload new) to generate action items for documents saved before Phase 2.

---

## Test checklist

- [ ] Upload lease with end date within 14 days → action item on Portfolio
- [ ] Open **Needs Attention** → see full list
- [ ] **Dismiss** item → removed from list
- [ ] Property detail → shows same open items
- [ ] Document with AI flags → flag appears as action item

---

## Next: Phase 3

Portfolio dashboard with metrics cards and property grid — see [PHASED_BUILD_PLAN.md](../PHASED_BUILD_PLAN.md).
