# Copilot Instructions for SCSUAuthorsDatabase

These notes teach AI coding agents how to be productive in this Flask + Kerko bibliography app. Prefer concrete patterns from this repo over generic advice.

## Architecture at a glance
- Flask app with an app factory in `kerkoapp/__init__.py`.
  - Kerko blueprint registered at `/bibliography` via `kerko.make_blueprint()`.
  - Custom app routes live in `register_routes()`; the landing page is served at `/`.
  - Extensions: Babel + Bootstrap initialized in `kerkoapp/extensions.py`.
- Kerko (external package) provides:
  - Faceted bibliography search, Whoosh index, Jinja templates, and CLI commands.
  - Jinja base templates are referenced by path names in config (e.g., `config.kerko.templates.page`).
- Data/index storage: under Flask instance path at `instance/kerko/{index,cache}/whoosh`. See `kerko.shortcuts.data_path()`.
- Logging: Configured in `configure_file_logging()` to write to `instance/logs/app.log` with 10MB rotation (10 backups).

## Key entry points
- `wsgi.py`: creates `app = create_app()`. Used by gunicorn and Flask CLI.
- `kerkoapp/__init__.py`:
  - Reads Kerko defaults, then loads TOML config via `load_config_files(app, env KERKOAPP_CONFIG_FILES)` and env prefix `KERKOAPP_...`.
  - Builds `app.config["kerko_composer"]` (Kerko's central registry).
  - Configures file + console logging before registering extensions.
  - Registers blueprints and error handlers.
  - Landing page route `/` renders `kerkoapp/templates/landing.html.jinja2` and passes:
    - `total_count` via `kerko.storage.get_doc_count("index")`.
    - `title="SCSU Authors"` for breadcrumb/header.
- `kerkoapp/dashboard.py`: blueprint (currently also mounted under `/bibliography`) producing analytics from the Whoosh index.

## Jinja patterns that matter
- Extend Kerko templates by name from config, not file paths:
  - Example: `{% extends config.kerko.templates.page %}` gives you Kerko's layout and blocks (`breadcrumb`, `content_inner`, etc.).
- Always provide a `title` variable when rendering pages that extend Kerko layouts; it's used in breadcrumbs and headers.
- Generate URLs with blueprint-qualified endpoints so prefixes are respected:
  - `url_for('kerko.search')`, `url_for('kerko.item_view', item_id=item.id)`.
- Global head/analytics override: `kerkoapp/templates/kerko/layout.html.jinja2` extends Kerko's base and includes `kerko/_analytics.html.jinja2` inside the `<head>`. Paste any analytics snippet (Matomo, GA4, etc.) into `kerkoapp/templates/kerko/_analytics.html.jinja2`.
- Navbar styling override: same layout override uses `navbar-light bg-light`; adjust there if branding changes.

## Working with Kerko's index
- Get counts: `from kerko.storage import get_doc_count` → `get_doc_count("index")`.
- Query items: Use `from kerko.storage import open_index` / `from kerko.searcher import Searcher`.
  - Build `SortSpec` over fields from `app.config["kerko_composer"].fields`.
  - Example: `results = searcher.search(limit=10, sort_spec=sort_spec)` → `results.items(field_specs)`.
- Field specs include `id` and `data` (Zotero item data dict).

## Configuration
- App config sources, in order:
  1) Kerko defaults (from the Kerko package)
  2) TOML files via `load_config_files(app, env KERKOAPP_CONFIG_FILES)` (defaults to `config.toml;instance.toml;.secrets.toml` search)
  3) Environment variables with `KERKOAPP_` prefix
- Example settings in top-level `config.toml`:
  - Navbar links (Home, Bibliography, Dashboard), breadcrumb base label, facets toggles, Zotero library config.
- Instance path is `KERKOAPP_INSTANCE_PATH` (env var) or Flask's default instance folder; Kerko resolves data paths under it.

## Logging
- Configured in `configure_file_logging()` called during app creation.
- Logs written to `instance/logs/app.log` with:
  - 10MB rotation, 10 backup files
  - Format: `[timestamp] LEVEL in module: message`
  - Both console and file handlers active
- View logs: `tail -f instance/logs/app.log`
- Log directory auto-created, excluded from git via `.gitignore` (`/instance`).

## Developer workflows
- Local run (Flask): set `FLASK_APP=wsgi:app`, `FLASK_ENV=development`, then `flask run`.
- Index build/sync: Kerko supplies Flask CLI commands.
  - First run often requires `flask kerko sync` to populate the index.
  - Clean index: `flask kerko clean everything`.
- Docker workflows via Makefile:
  - `make run` runs the container mapping `instance/` and logs; first run auto-triggers `flask kerko sync`.
  - `make clean_kerko` calls `flask kerko clean` in a container.
- Linting: Ruff config is in `pyproject.toml` (`[tool.ruff]`). If using `requirements/dev.txt`, you can run ruff, but no dedicated make target is provided here.

## Conventions and gotchas
- Blueprint URL prefix is `/bibliography` for Kerko; always qualify endpoints with `kerko.`.
- Kerko templates expect variables like `title` to exist; missing it breaks breadcrumbs.
- Use `url_for(...)` instead of hard-coded URLs to keep links correct when prefixes or hosts change.
- Treat index access as optional on UX (landing page logs warnings but renders even if index is empty).

## Examples in this repo
- Landing page: `kerkoapp/__init__.py` + `kerkoapp/templates/landing.html.jinja2` show:
  - How to pass `total_count` from Kerko's index.
  - How to link into Kerko search with `url_for('kerko.search', ...)`.
  - Simple custom landing page without carousel (resource count + type links).
- Analytics dashboard: `kerkoapp/dashboard.py` shows direct Whoosh reads (outside Kerko's Searcher) to compute stats. `kerkoapp/templates/dashboard.html.jinja2` renders a bar chart (per-year publications) plus two pie charts (item types and departments).

If anything above is unclear (e.g., how you want index sync documented for non-Docker local dev, or preferred lint/test commands), tell me and I'll refine these notes.
