# Autobiography App & Template

Create and share a beautiful digital autobiography: write chapters, add photos, and export your story as PDF or DOCX. This repository contains a Rails 8 application plus a ready-to-use template in `autobiography_template/` for fast onboarding.

## Overview
- **Chapters**: Write rich-text chapters, organize intro and numbered chapters, and browse with a reader-friendly UI.
- **Photos**: Manage a gallery and view photos inline with chapters.
- **Authentication**: Simple email + password sign-in. Public can read; editing/export requires sign-in.
- **Exports**: Generate a complete book or single chapters as PDF; export DOCX for word processors.
- **Styling**: Tailwind CSS for modern, responsive design.

## Requirements
- Ruby 3.4+ and Bundler
- PostgreSQL (default; see `config/database.yml`)
- wkhtmltopdf is bundled via `wkhtmltopdf-binary` gem; no extra install typically required

## Quick Start (Windows, macOS, Linux)
1. Install gems
	```bash
	bundle install
	```
2. Set up database (creates, migrates, and seeds sample content)
	```bash
	rails db:setup
	# or
	rails db:create db:migrate db:seed
	```
3. Run the app (Foreman via `bin/dev` for Rails + Tailwind)
	```bash
	bin/dev
	# then visit http://localhost:3000
	```

### Windows Shortcut
If `bin/dev` is awkward in PowerShell, use:

```bat
start-dev.bat
```

This script removes a stale Rails PID lock (if present) and starts Foreman with `Procfile.dev`.

## First Login & Accounts
- After seeding, an admin user is created:
  - Email: `admin@autobio.com`
  - Password: `password123`
- Or create your own account at `/users/new`, then sign in at `/session/new`.

## Writing & Reading
- **Create/Edit Chapters**: Requires authentication. Find actions in the Chapters pages.
- **Public Reading**: Home, list, and show are readable without signing in.
- **Chapter Order**: Chapters are ordered with the introduction first, then numbered chapters.

## Photos
- Add and manage photos in the Photos section. Photos can be viewed standalone or from related chapters.

## Exporting Your Story
- **Complete Book (PDF)**: From home or Chapters list, export the entire autobiography.
- **Single Chapter (PDF)**: From a chapter page, export the current chapter.
- **DOCX Export**: Available for complete book and single chapters for editing in Word/Pages.
- More details: see [docs/PDF_EXPORT.md](docs/PDF_EXPORT.md).

## Configuration & Customization
- **Styling**: Tailwind classes in views; builds at [app/assets/builds](app/assets/builds). Tailwind config via `tailwindcss-rails`.
- **PDF Layout**: Customize PDF header/footer and layout in `app/views/shared/` and `app/views/layouts/pdf.html.erb`.
- **User Info in Exports**: Adjust `get_user_info_for_pdf` in [app/controllers/chapters_controller.rb](app/controllers/chapters_controller.rb) for author/title metadata.
- **Authentication Helpers**: Provided by `Authentication` concern in [app/controllers/concerns/authentication.rb](app/controllers/concerns/authentication.rb).

## Storage Options
- Default: local Active Storage (ignored in VCS via `.gitignore`).
- Optional: Cloudinary integration (see `CLOUDINARY_SETUP.md` and `add_cloudinary_credentials.rb`).

## Testing
- System tests use Selenium + Capybara.
  ```bash
  bundle exec rails test:system
  ```
- Added coverage for auth-gated visibility in [test/system/auth_visibility_test.rb](test/system/auth_visibility_test.rb).

## Deployment
- **Kamal**: Container-based deployments (see `config/deploy.yml` and `bin/kamal`).
- **Docker**: A `Dockerfile` is included for container builds.
- **Render/Railway/Heroku**: Standard Rails deploys work; ensure PostgreSQL and environment variables are set.

### Deploy to Render
- Use the provided Blueprint at [render.yaml](render.yaml) for one-click provisioning.
- Set env vars: `RAILS_ENV=production`, `RAILS_LOG_TO_STDOUT=true`, `RAILS_SERVE_STATIC_FILES=true`, and `RAILS_MASTER_KEY` if using credentials.
- Post-deploy migration runs automatically; see the full steps in [DEPLOY_RENDER.md](DEPLOY_RENDER.md).

### Environment & Secrets
- Credentials are managed via Rails credentials; the master key should never be committed.
- `.gitignore` already excludes logs, temp files, storage, and assets builds.

## Project Structure
- App code in `app/` with MVC structure for `chapters` and `photos`.
- Template and docs in `autobiography_template/` (useful for onboarding or separate distribution).
- Static assets in `public/`.
- Database schema and seeds in `db/`.

## Tips
- Keep private content behind authentication; public visitors can read but cannot export or edit.
- Regularly export PDFs/DOCX as backups.
- If using Cloud storage, confirm credentials and policies before uploading family photos.

## License
See the repository’s license file if provided.

## Support
- Rails Guides and Tailwind CSS docs are great references.
- Issues and enhancements can be tracked in this repo.
