# Real Estate Portfolio - Lease Upload MVP

Flutter + Supabase application for uploading lease PDFs, extracting structured data with Gemini AI, matching properties, and saving portfolio records.

## Prerequisites

- Flutter SDK 3.x
- Supabase account and project
- [Supabase CLI](https://supabase.com/docs/guides/cli) (optional, for local dev and deployments)
- Google AI Studio API key ([get one here](https://aistudio.google.com/apikey))

## Project structure

```
lib/
  core/          # config, providers, utils, errors
  data/          # models and Supabase repository
  services/      # PDF, Gemini (via Edge Function), matching, storage
  features/      # auth, upload, review, portfolio screens
supabase/
  migrations/    # Postgres schema, RLS, storage policies
  functions/     # extract-lease Edge Function (Gemini proxy)
```

## Supabase setup

1. Create a Supabase project at [supabase.com](https://supabase.com).

2. Apply the database migration:
   - **CLI:** `supabase link --project-ref <your-ref>` then `supabase db push`
   - **Dashboard:** paste SQL from `supabase/migrations/20250614000000_initial_schema.sql` into the SQL editor and run it

3. Set Edge Function secrets:
   ```bash
   supabase secrets set GEMINI_API_KEY=your_gemini_api_key
   ```

4. Deploy the Edge Function:
   ```bash
   supabase functions deploy extract-lease
   ```

5. Confirm the `lease-documents` storage bucket exists (created by migration).

## Flutter setup

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```

2. Fill in `.env`:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. Install dependencies and run (PowerShell — use `;` not `&&`):
   ```powershell
   flutter pub get
   flutter run -d windows
   ```

## User flow

1. Sign up / sign in (Supabase Auth)
2. Open **Portfolio** and tap **Upload Lease**
3. Select a text-based PDF lease (scanned/image PDFs without selectable text are not supported in Sprint 1)
4. App uploads to Storage, extracts PDF text, calls Gemini via Edge Function, and matches properties
5. Review extracted property + lease fields, edit as needed, and save
6. Portfolio lists properties and linked leases

## Security notes

- `GEMINI_API_KEY` is stored only in Supabase Edge Function secrets
- Flutter uses the Supabase anon key only
- Row Level Security restricts properties, leases, documents, and storage to the authenticated user

## Smoke test checklist

- [ ] Sign up with email/password
- [ ] Upload `samples/sample_lease.pdf` (included in repo)
- [ ] Verify review screen shows extracted fields
- [ ] Save and confirm property + lease appear on portfolio
- [ ] Upload a second lease for the same address and confirm property match

## Auth setup (email confirmation + redirect)

### 1. Supabase dashboard (PropIntel)

1. Open [Authentication → URL Configuration](https://supabase.com/dashboard/project/qdkopdghhltkabhkqamn/auth/url-configuration)
2. Set **Site URL:** `http://localhost:3000`
3. Add **Redirect URLs:**
   - `http://localhost:3000/confirm.html`
   - `http://localhost:3000/**`
4. Open [Authentication → Providers → Email](https://supabase.com/dashboard/project/qdkopdghhltkabhkqamn/auth/providers)
5. Enable **Confirm email**

### 2. App `.env`

```
AUTH_REDIRECT_URL=http://localhost:3000/confirm.html
```

This must exactly match a URL in Supabase **Redirect URLs**.

### 3. Serve the confirmation landing page locally

In a **second terminal** (keep the Flutter app running in the first):

```powershell
cd c:\GitRepos\REAL-ESTATE-PORTFOLIO\web
python -m http.server 3000
```

This hosts `confirm.html` at `http://localhost:3000/confirm.html`.

### 4. Signup flow

1. Run the app: `flutter run -d windows`
2. **Create an account** → app shows “Check your inbox”
3. Open the confirmation email → click the link
4. Browser opens **Email confirmed** page
5. Return to the app → **Sign In**

### Production

See **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** for full Vercel deployment steps.

Quick summary:
1. Push repo to GitHub
2. Import in [Vercel](https://vercel.com/new)
3. Set env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AUTH_REDIRECT_URL=https://your-app.vercel.app/confirm.html`
4. Deploy
5. Add Vercel URLs to Supabase **Authentication → URL Configuration**

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Save to DB fails | Ensure migration ran; property insert requires `user_id` (fixed in latest code — hot restart app) |
| Email confirm link fails | Ensure redirect page is running (`python -m http.server 3000` in `web/`) and URL is whitelisted in Supabase |
| Extraction fails after upload | Set `GEMINI_API_KEY` in Edge Function secrets |

## Out of scope (Sprint 1)

Notifications, email ingestion, banking integrations, AI chat, predictive analytics, external PMS integrations, OCR for scanned PDFs.
