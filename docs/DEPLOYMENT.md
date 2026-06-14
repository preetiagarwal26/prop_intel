# Deploy to Vercel (free tier)

Host the **Flutter web app** + email confirmation page on Vercel. Supabase (database, auth, storage, Edge Functions) stays on Supabase — no change needed there.

## Architecture

| Component | Where it runs |
|-----------|----------------|
| Flutter web app | Vercel |
| `confirm.html` (email redirect) | Vercel (same deployment) |
| Postgres, Auth, Storage, Gemini | Supabase (PropIntel) |

## Prerequisites

1. Code pushed to **GitHub** (Vercel deploys from Git)
2. [Vercel account](https://vercel.com) (free Hobby tier)
3. PropIntel Supabase project already set up

---

## Step 1 — Push to GitHub

If not already on GitHub:

```powershell
cd c:\GitRepos\REAL-ESTATE-PORTFOLIO
git remote add origin https://github.com/YOUR_USER/REAL-ESTATE-PORTFOLIO.git
git push -u origin main
```

---

## Step 2 — Import project in Vercel

1. Go to [vercel.com/new](https://vercel.com/new)
2. **Import** your GitHub repo `REAL-ESTATE-PORTFOLIO`
3. Vercel reads `vercel.json` automatically — leave defaults
4. **Do not deploy yet** — add environment variables first (Step 3)

---

## Step 3 — Environment variables in Vercel

Project → **Settings** → **Environment Variables**. Add for **Production** (and Preview if you want):

| Name | Value |
|------|--------|
| `SUPABASE_URL` | `https://qdkopdghhltkabhkqamn.supabase.co` |
| `SUPABASE_ANON_KEY` | your publishable/anon key |
| `AUTH_REDIRECT_URL` | `https://YOUR-APP.vercel.app/confirm.html` |

**Note:** Replace `YOUR-APP` with your Vercel project name. If unsure, deploy once with a placeholder, copy the URL Vercel gives you, then update `AUTH_REDIRECT_URL` and redeploy.

Example after first deploy:
```
AUTH_REDIRECT_URL=https://real-estate-portfolio.vercel.app/confirm.html
```

---

## Step 4 — Deploy

Click **Deploy** (or push to `main` for auto-deploy).

First build takes ~3–5 minutes (installs Flutter). Later builds are cached and faster.

Your app will be live at:
```
https://your-project.vercel.app
```

---

## Step 5 — Update Supabase Auth URLs

In [PropIntel → Authentication → URL Configuration](https://supabase.com/dashboard/project/qdkopdghhltkabhkqamn/auth/url-configuration):

| Setting | Value |
|---------|--------|
| **Site URL** | `https://your-project.vercel.app` |
| **Redirect URLs** | `https://your-project.vercel.app/confirm.html` |
| | `https://your-project.vercel.app/**` |

Keep localhost URLs too if you still develop locally.

**Confirm email** must stay **enabled** under Providers → Email.

---

## Step 6 — Redeploy (if AUTH_REDIRECT_URL changed)

After setting the final `AUTH_REDIRECT_URL` in Vercel:

**Deployments** → latest deployment → **Redeploy**

Then test signup: confirm email link should open `https://your-project.vercel.app/confirm.html`.

---

## Custom domain (optional)

Vercel → **Settings** → **Domains** → add your domain (free on Hobby tier).

Then update:
- Vercel `AUTH_REDIRECT_URL` → `https://yourdomain.com/confirm.html`
- Supabase Site URL + Redirect URLs
- Redeploy

---

## Alternatives (also free)

| Platform | Notes |
|----------|--------|
| [Netlify](https://netlify.com) | Use same `scripts/build_web.sh`; set publish dir to `build/web` |
| [Cloudflare Pages](https://pages.cloudflare.com) | Connect GitHub; build command `bash scripts/build_web.sh`; output `build/web` |
| [Firebase Hosting](https://firebase.google.com/docs/hosting) | Requires GitHub Action to build Flutter first |

---

## Local web preview (before deploying)

```powershell
cd c:\GitRepos\REAL-ESTATE-PORTFOLIO
flutter build web --release
copy web\confirm.html build\web\confirm.html
cd build\web
python -m http.server 8080
```

Open `http://localhost:8080`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build fails on Vercel | Check env vars are set; view build logs |
| Blank page after deploy | Hard refresh; check browser console for missing `.env` values |
| Email confirm 404 | `confirm.html` not copied — `build_web.sh` handles this; redeploy |
| Auth redirect error | `AUTH_REDIRECT_URL` must exactly match Supabase Redirect URLs |
| PDF upload fails on web | Use Chrome/Edge; file picker requires HTTPS (Vercel provides this) |

---

## What stays local-only

The **Windows desktop** build (`flutter run -d windows`) still works for local dev. Production users access the **web app** on Vercel.
