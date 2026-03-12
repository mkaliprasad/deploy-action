# deploy-action

Reusable GitHub Actions workflow that deploys apps to your servers when you comment on a PR.

## How it works

```
You comment on a PR:   @deployment-skill deploy staging
         │
         ▼
App repo workflow parses the comment, gets the PR branch
         │
         ▼
Calls xola/deploy-action (this repo) reusable workflow
         │
         ▼
SSHs into the staging server, pipes deploy.sh remotely:
  1. git fetch + checkout the PR branch
  2. nvm install + nvm use (reads .nvmrc)
  3. npm ci
  4. npm run build  (auto-detected from package.json)
  5. pm2 restart <app>
         │
         ▼
Posts result back as a PR comment ✅ / ❌
```

## Setup

### 1. Configure GitHub Environments in THIS repo (`xola/deploy-action`)

Create three environments: `staging`, `sandbox`, `preprod`

For each environment, add these secrets:

| Secret | Value |
|--------|-------|
| `SSH_HOST` | Server hostname (e.g. `staging-microservices-01.xola.com`) |
| `SSH_USER` | SSH login user (e.g. `ubuntu`) |
| `SSH_KEY` | Contents of the private key `.pem` file |

Optionally, add a repository variable `DEPLOY_BASE` if your apps aren't under `/var/www`.

### 2. Add the trigger workflow to each app repo

Copy `examples/deploy-on-comment.yml` into the app repo at:
```
.github/workflows/deploy-on-comment.yml
```

That's it — no secrets or environments needed in the app repos.

### 3. Usage

Comment on any PR in an app repo:

```
@deployment-skill deploy staging
@deployment-skill deploy sandbox
@deployment-skill deploy preprod
```

The PR branch is automatically used — no need to specify it.

## Supported environments

`staging` · `sandbox` · `preprod`

## Repo structure

```
.github/
  workflows/
    deploy.yml                  ← reusable workflow (called by app repos)
scripts/
  deploy.sh                     ← shell script piped to the server via SSH
examples/
  deploy-on-comment.yml         ← copy this into each app repo
README.md
```
