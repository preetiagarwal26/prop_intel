#!/usr/bin/env bash
set -euo pipefail

# Builds Flutter web for Vercel/CI.
# Required env vars: SUPABASE_URL, SUPABASE_ANON_KEY, AUTH_REDIRECT_URL

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ] || [ -z "${AUTH_REDIRECT_URL:-}" ]; then
  echo "ERROR: Set SUPABASE_URL, SUPABASE_ANON_KEY, and AUTH_REDIRECT_URL before building."
  exit 1
fi

cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
AUTH_REDIRECT_URL=${AUTH_REDIRECT_URL}
EOF

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter config --enable-web
  flutter precache --web
fi

flutter pub get
flutter build web --release
cp web/confirm.html build/web/confirm.html

echo "Web build ready in build/web"
