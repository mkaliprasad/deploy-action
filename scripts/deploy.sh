#!/usr/bin/env bash
# Runs on the target server, piped via SSH from GitHub Actions.
# Required env vars: APP_NAME, DEPLOY_BASE
# Optional env vars: PR_NUMBER, BRANCH (omit for master deploy)
set -euo pipefail

# Source NVM so nvm/node/npm are available
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
else
  echo "❌ NVM not found at $NVM_DIR"
  exit 1
fi

APP_DIR="${DEPLOY_BASE}/${APP_NAME}"

if [ ! -d "$APP_DIR" ]; then
  echo "❌ App directory not found: $APP_DIR"
  exit 1
fi

echo "🚀 Deploying **${APP_NAME}** from \`${APP_DIR}\`"
cd "$APP_DIR"

# ── Step 1: Git ────────────────────────────────────────────────────────────────
if [ -n "${BRANCH:-}" ] && [ "${BRANCH}" != "master" ]; then
  echo "🔀 Fetching branch \`${BRANCH}\`..."
  git fetch origin "${BRANCH}"
  git checkout "${BRANCH}"
  git reset --hard "origin/${BRANCH}"
else
  echo "📡 Pulling latest \`master\`..."
  git checkout master
  git pull origin master
fi

# ── Step 2: Node version ───────────────────────────────────────────────────────
NODE_VERSION=$([ -f .nvmrc ] && cat .nvmrc | tr -d '[:space:]' || echo "lts/*")
echo "🔍 Node version: \`${NODE_VERSION}\`"
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"

# ── Step 3: Install dependencies ──────────────────────────────────────────────
echo "📥 Running \`npm ci\`..."
npm ci

# ── Step 4: Build (only if package.json has a build script) ───────────────────
if node -e "const p=require('./package.json'); process.exit(p.scripts&&p.scripts.build?0:1)" 2>/dev/null; then
  echo "🔨 Running \`npm run build\`..."
  npm run build
fi

# ── Step 5: Restart via pm2 ───────────────────────────────────────────────────
echo "🔄 Running \`pm2 restart ${APP_NAME}\`..."
pm2 restart "$APP_NAME"

echo "✅ **${APP_NAME}** deployed successfully!"
