# User Story 1 — Property onboarding from closing documents

**Epic:** Post-closing property setup  
**Status:** Implemented (pending `supabase db push` + redeploy `classify-document`)  
**Builds on:** [User Story 2](UserStory2.md), [User Story 3](UserStory3.md)

---

## User story

**As an** investor who just closed on a property,  
**I want to** upload closing documents (settlement, mortgage, HOA, lease, insurance) and have the app build a property profile and todo list,  
**So that** onboarding is complete without manual Excel tracking.

---

## Acceptance criteria

- [x] Document types: **settlement**, **mortgage** (+ existing lease, insurance, hoa)
- [x] Settlement extracts property profile (type, beds/baths) and flags (mortgage, HOA, renters, insurance)
- [x] Settlement creates **onboarding checklist** of expected closing docs (no todos from settlement)
- [x] Uploading expected doc types marks checklist items **received**
- [x] Property detail shows **Closing onboarding** panel with progress + “Upload next”
- [x] **Mortgage** doc → monthly mortgage payment action items (12-month horizon)
- [x] **Lease** doc → monthly rent due action items + existing lease expiry rules
- [x] **Insurance** doc → expiry reminder at **15 days** before (US1)
- [x] User can **Mark onboarding complete** manually

---

## Technical notes

### Migration

`supabase/migrations/20250625000000_property_onboarding.sql`

Adds to `properties`: `property_type`, `bedrooms`, `bathrooms`, `onboarding_status`, `onboarding_checklist`

### Key files

```
lib/data/models/onboarding_checklist.dart
lib/services/property_onboarding_service.dart
lib/services/action_item_generator_service.dart  # rent_due, mortgage_due
lib/features/shared/onboarding_checklist_panel.dart
supabase/functions/classify-document/index.ts    # settlement + mortgage extraction
```

---

## Deploy

```powershell
npx supabase db push
npx supabase functions deploy classify-document
flutter run -d chrome --web-port=3000
```

---

## Test checklist

- [ ] Upload settlement with has_mortgage=true → checklist shows mortgage expected
- [ ] Upload mortgage → checklist marks received + mortgage due todos appear
- [ ] Upload lease with monthly_rent → rent due todos appear
- [ ] Upload insurance expiring in 15 days → insurance expiring todo
- [ ] Mark onboarding complete on property detail
