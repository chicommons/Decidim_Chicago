# Railway deployment

## What this fixes

The former Dockerfile only inherited `decidim/decidim:0.31.4`; it did not copy
this repository into the image. Compose's `/code` bind mount masked the issue.
The build now installs this app's locked gems/npm dependencies and precompiles
its assets in `/app`, isolated from the inherited example app in `/code`.
It validates migration names before compiling assets. The stale Gemfile.lock
entries for disabled modules are removed.

Production now supports hosted DATABASE_URLs, configurable hosts, TLS reverse
proxies, and a `/up` route placed before the Decidim engine. Static Rails error
pages prevent an exception before Warden from generating a misleading secondary
`Devise::MissingWarden` failsafe error. Authentication is not bypassed.

## Required Railway variables

| Variable | Value / purpose |
| --- | --- |
| RAILS_ENV | `production` |
| NODE_ENV | `production` |
| DATABASE_URL | PostgreSQL URL; include `sslmode=require` for Supabase |
| DATABASE_SCHEMA | `decidim` for a new Supabase installation; do not change this to abandon an existing installation's schema |
| REDIS_URL | Standard Redis URL; Upstash requires `rediss://`, not its HTTPS REST endpoint |
| SECRET_KEY_BASE | A stable random secret; generate with `openssl rand -hex 64` |
| APP_HOST | Exact public hostname, without scheme/path/port |
| RAILS_LOG_TO_STDOUT | `true` |
| RAILS_SERVE_STATIC_FILES | `true` |
| RAILS_MAX_THREADS | `3` initially |
| QUEUE_ADAPTER | `delayed_job` |
| RUN_EMBEDDED_WORKER | `true` to run one worker in this web container |
| RAILS_CREDENTIALS_PATH | `config/credentials/container.yml.enc` for this environment-only installation; this absent file intentionally selects no encrypted credentials |

The repository's `railway.json` describes the settings, but Railway now
deprecates Config as Code and may ignore this file for new configurations.
Set these values explicitly in the service settings and inspect the deployment
manifest to confirm they took effect:

- Dockerfile path: `Dockerfile`.
- Pre-deploy command: `bundle exec rails runner bin/railway-release.rb` (timeout 600 seconds).
- Start command: `bash bin/railway-start`.
- Health check: `/up` (timeout 180 seconds).
- One replica; restart on failure, maximum five retries.

Let Railway supply PORT and target that port in the
public domain settings. Enable IPv6 egress for Supabase's direct IPv6 endpoint.
If it is unreachable, use Supabase's **session pooler** on port 5432, not its
transaction pooler on port 6543.

The release script creates the selected schema if necessary, checks for
unrelated tables, tests Redis, and migrates. It never drops a database or calls
`db:seed`, `db:setup`, or `db:prepare` (the seeds create demo organizations).
Back up an existing installation before migrations. Supabase must allow
`pg_trgm`; include its `extensions` schema in the search path.

Keep the `decidim` schema out of Supabase's exposed Data API schemas. Decidim
manages its own users/authentication and should not expose those tables through
the public REST API. If you already have Decidim data in `public`, keep using
that schema and separately review Data API grants/RLS instead of silently
switching to an empty schema.

The embedded worker is a small-installation compromise, not an independent
service. It consumes resources in the existing container. Both processes are
terminated together; if either exits unexpectedly, Railway restarts the service.
For larger deployments use a separate worker with `bundle exec rake jobs:work`
and `RUN_EMBEDDED_WORKER=false` on the web service. Do not run Sidekiq to process
jobs configured for delayed_job: delayed_job stores its queue in PostgreSQL.
The Redis connection remains needed for Action Cable/spam detection. Use an
Upstash database dedicated to this application and monitor the free-plan quota.
Both classifiers use database 0 with separate `decidim:ai:resource:` and
`decidim:ai:user:` key prefixes. Reset deletes only that classifier's keys,
not the other model or unrelated Redis keys. Avoid concurrent training/reset.

This installation supplies secrets through environment variables instead of
the repository's encrypted credentials. If encrypted credentials are required,
remove RAILS_CREDENTIALS_PATH (or select your real encrypted file) and supply
its matching RAILS_MASTER_KEY securely; never commit the key.

## First-time onboarding (no demo seeds)

1. Once `/up` is healthy, open a Railway service shell.
2. Run `bundle exec rails decidim_system:create_admin` and enter the requested
   email/password interactively. Do not commit credentials or paste them into logs.
3. Visit `https://<APP_HOST>/system` and sign in.
4. Create an organization. Its host must exactly match APP_HOST, including any
   subdomain, but without `https://`. Configure locales, sender email and its
   organization administrator. A missing organization may make `/` show an
   error even while `/up` and `/system` are working.
5. Check the organization administrator's invitation email and sign in at
   `/admin`. This requires working SMTP and the running delayed_job worker.

## SMTP (required for invitations, confirmation and password resets)

Set `SMTP_ADDRESS`, `SMTP_PORT` (usually 587), `SMTP_USERNAME`, `SMTP_PASSWORD`,
`SMTP_DOMAIN`, `SMTP_AUTHENTICATION=plain`, and `SMTP_STARTTLS_AUTO=true` for a
STARTTLS provider. Select a verified organization sender address. The app
verifies SMTP TLS certificates; do not disable verification to mask a bad
configuration. Confirm the Railway account/provider permits SMTP egress.
APP_HOST also controls the default HTTPS mail links.

## Persistent uploads (required before public use)

Without persistent storage, uploads in `storage/` disappear on redeploy.
The default `STORAGE_PROVIDER=local` is only suitable for initial testing.
Choose either a Railway volume mounted at `/app/storage` (billable), or a
supported object store configured in `config/storage.yml`.

For S3-compatible storage, this app must also bundle `aws-sdk-s3` before using
`STORAGE_PROVIDER=s3`; then set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
AWS_BUCKET, AWS_REGION and optionally AWS_ENDPOINT. Supabase object storage
is separate from the PostgreSQL connection and requires its own S3-compatible
endpoint/credentials and an appropriate public/private access policy.

## Verification

These are acceptance checks, not a claim that onboarding, SMTP or storage has
been completed. Local production asset compilation and static error handling
have been tested. The disposable Redis isolation check passed against Upstash:
`bundle exec rails runner bin/check-classifier-isolation.rb`.

- `/up`: HTTP 200, even before an organization exists.
- `/system`: sign-in page loads over HTTPS with CSS/JS assets.
- `/`: works after creating an organization with the matching host.
- Send a test invitation and verify it leaves delayed_jobs and arrives.
- Test upload persistence across a restart/redeploy once storage is configured.
- Confirm arbitrary Host headers are rejected and no debug error pages are public.

## Rollback

Switch the Railway source back to the previous repo/branch and redeploy a known
good image. Database migrations are not undone by an image rollback; restore
the database backup if needed. Do not rotate SECRET_KEY_BASE on every deployment.
