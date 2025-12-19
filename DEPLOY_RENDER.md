# Deploy to Render (Rails App)

This guide walks you through replacing your old Python/Django app with this Rails app on Render, using a new Web Service and a managed PostgreSQL database.

## Prerequisites
- GitHub repository connected to this Rails app
- Render account and GitHub integration enabled
- Optional: Rails master key (only if you use Rails credentials)

## Repo Readiness
- Render Blueprint: see `render.yaml` for build/start/post-deploy commands and default environment variables.
- Production DB: `config/database.yml` is configured to use `DATABASE_URL`.
- Optional Heroku support: `Procfile` included.

## Create the Service (Recommended: Blueprint)
1. In Render, choose "New +" → Blueprint → select your GitHub repo.
2. Review the resources:
   - A PostgreSQL database named `autobio-db` (plan: starter)
   - A Web Service named `autobio-app`
3. Click "Deploy" to provision resources and start the service.

## Environment Variables
Set on the Web Service (and database, as needed):
- `RAILS_ENV=production`
- `RAILS_LOG_TO_STDOUT=true`
- `RAILS_SERVE_STATIC_FILES=true`
- `RAILS_MASTER_KEY=...` (only if you use Rails credentials)

`DATABASE_URL` is provided automatically when you attach the Render PostgreSQL database.

## Build / Start / Post-Deploy
These are defined in `render.yaml` and run automatically:
- Build: `bundle install && bundle exec rails assets:precompile`
- Start: `bundle exec puma -C config/puma.rb`
- Post-deploy: `bundle exec rails db:migrate`

## Seed Initial Data (Optional)
If you want an admin user and sample chapters:

```bash
bundle exec rails db:seed
```

Run this from the Render shell for your Web Service.

## Verify the App
- Visit the Web Service URL (e.g., `https://autobio-app.onrender.com`).
- Check:
  - Home and chapter pages load
  - Photo gallery loads and images open in lightbox
  - PDF and DOCX export endpoints respond (PDF opens/downloads)

## Import Your Chapters

If you authored chapters locally (development) and want them on Render (production), use these rake tasks.

### Export from your local machine

```bash
# From your dev machine
bundle exec rails chapters:export
# Output: tmp/chapters_export.json
```

### Import into Render via URL (recommended)

1. Host `tmp/chapters_export.json` at a public URL (e.g., a GitHub Gist raw link).
2. In Render’s Shell for the web service:

```bash
RAILS_ENV=production bundle exec rails chapters:import_url[https://your-raw-url/chapters_export.json]
```

### Import into Render from a file path (alternative)

If you can place the JSON on the server (e.g., paste into `/tmp/chapters_export.json`):

```bash
# In Render’s Shell, create the file (paste contents, then Ctrl+D):
cat > /tmp/chapters_export.json
RAILS_ENV=production bundle exec rails chapters:import[/tmp/chapters_export.json]
```

Notes:
- These tasks import `title`, `subtitle`, and rich text `content` (HTML).
- Images (e.g., `image_header`) are not exported; re-attach them in production if needed.
- Imports append chapters; delete duplicates in the UI if you re-run imports.

## Custom Domain Cutover
If your Django app currently holds the domain:
1. Remove your custom domain from the old Django service in Render.
2. Add the domain to the new Rails service → Render will issue SSL automatically.
3. Verify the domain resolves to the Rails app and pages/assets work.

## Decommission the Old App
- After successful cutover, scale the Django service to zero or delete it.

## Troubleshooting
- **Assets not serving**: Ensure `RAILS_SERVE_STATIC_FILES=true` and that build completes.
- **Missing master key**: If using Rails credentials, set `RAILS_MASTER_KEY` to your local `config/master.key` value.
- **PDF export issues**: The repo includes `wicked_pdf` and `wkhtmltopdf-binary`. If PDFs fail, check Render logs and confirm no external calls are blocked.
- **Database errors**: Confirm `DATABASE_URL` is present on the service; re-run `db:migrate` in the Render shell.

## Alternative: Heroku
If you prefer Heroku:
- Buildpacks: `heroku/ruby`
- Add Heroku Postgres
- Env vars: same as above (`RAILS_ENV`, `RAILS_LOG_TO_STDOUT`, `RAILS_SERVE_STATIC_FILES`, optional `RAILS_MASTER_KEY`)
- Start via `Procfile`: `web: bundle exec puma -C config/puma.rb`
- Deploy:

```bash
heroku create
heroku buildpacks:add heroku/ruby
heroku addons:create heroku-postgresql
heroku config:set RAILS_ENV=production RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1
# If using credentials:
heroku config:set RAILS_MASTER_KEY=...

git push heroku master
heroku run rails db:migrate
```

---

That’s it. Deploy the Rails app side-by-side, verify it, then move your domain for a clean replacement.