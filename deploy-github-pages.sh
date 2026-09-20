#!/bin/bash
# Publică paginile publice cerute de TikTok (site, termeni, confidențialitate) pe GitHub Pages.
# Se rulează o singură dată, din folderul proiectului:
#     bash tiktok-site/deploy-github-pages.sh
# Opțional, alt nume de repository:
#     bash tiktok-site/deploy-github-pages.sh numele-dorit
set -euo pipefail

REPO="${1:-peak-clip-studio}"
cd "$(dirname "$0")"

if ! command -v gh >/dev/null 2>&1; then
  echo "Lipsește GitHub CLI. Instalează-l cu:  brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Nu ești logat în GitHub. Rulează întâi:  gh auth login"
  exit 1
fi

OWNER="$(gh api user --jq .login)"

printf '.DS_Store\n' > .gitignore

if [ ! -d .git ]; then
  git init -q -b main
fi

# Identitate doar pentru acest repository: adresa noreply de la GitHub, ca să nu
# ajungă adresa ta reală de e-mail în istoricul unui repository public.
OWNER_ID="$(gh api user --jq .id)"
git config user.name "$OWNER"
git config user.email "${OWNER_ID}+${OWNER}@users.noreply.github.com"

git add -A
git commit -qm "Peak Clip Studio public pages" || true

if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$REPO.git"
  git push -u origin main
else
  gh repo create "$REPO" --public --source=. --push
fi

gh api -X POST "repos/$OWNER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || gh api -X PUT "repos/$OWNER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || true

echo
echo "Gata. GitHub are nevoie de un minut, două, până publică paginile."
echo "Lipește aceste trei adrese în formularul aplicației TikTok:"
echo
echo "  Web/Desktop URL:      https://$OWNER.github.io/$REPO/"
echo "  Terms of Service URL: https://$OWNER.github.io/$REPO/terms.html"
echo "  Privacy Policy URL:   https://$OWNER.github.io/$REPO/privacy.html"
echo
echo "App icon: tiktok-site/icon.png (1024x1024, exact cât cere TikTok)."
