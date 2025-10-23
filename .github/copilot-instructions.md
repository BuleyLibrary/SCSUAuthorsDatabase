# Copilot Instructions for SCSUAuthorsDatabase

These notes teach AI coding agents how to be productive in this Flask + Kerko app quickly. Prefer concrete patterns from this repo over generic advice.

## Architecture at a glance
- Flask app with an app factory in `kerkoapp/__init__.py`.
  - Kerko blueprint registered at `/bibliography` via `kerko.make_blueprint()`.
  - Custom app routes live in `register_routes()`; the landing page is served at `/`.
  - Extensions: Babel + Bootstrap initialized in `kerkoapp/extensions.py`.
- Kerko (external package) provides:
  - Faceted bibliography search, Whoosh index, Jinja templates, and CLI commands.
  - Jinja base templates are referenced by path names in config (e.g., `config.kerko.templates.page`).
- Data/index storage: under Flask instance path at `instance/kerko/{index,cache}/whoosh`. See `kerko.shortcuts.data_path()`.

## Key entry points
- `wsgi.py`: creates `app = create_app()`. Used by gunicorn and Flask CLI.
- `kerkoapp/__init__.py`:
  - Reads Kerko defaults, then loads TOML config via `load_config_files(app, env KERKOAPP_CONFIG_FILES)` and env prefix `KERKOAPP_...`.
  - Builds `app.config["kerko_composer"]` (Kerko’s central registry).
  - Registers blueprints and error handlers.
  - Landing page route `/` renders `kerkoapp/templates/landing.html.jinja2` and passes:
    - `total_count` via `kerko.storage.get_doc_count("index")`.
    - `newest_items`: 5 newest items via Kerko `Searcher` sorted by `sort_date_added`.
- `kerkoapp/dashboard.py`: blueprint (currently also mounted under `/bibliography`) producing analytics from the Whoosh index.

## Jinja patterns that matter
- Extend Kerko templates by name from config, not file paths:
  - Example: `{% extends config.kerko.templates.page %}` gives you Kerko’s layout and blocks (`breadcrumb`, `content_inner`, etc.).
- Always provide a `title` variable when rendering pages that extend Kerko layouts; it’s used in breadcrumbs and headers.
- Generate URLs with blueprint-qualified endpoints so prefixes are respected:
  - `url_for('kerko.search')`, `url_for('kerko.item_view', item_id=item.id)`.

## Working with Kerko’s index
- Get counts: `from kerko.storage import get_doc_count` → `get_doc_count("index")`.
- Query newest items (example used on landing page):
  - `from kerko.storage import open_index` / `from kerko.searcher import Searcher` / `from kerko.specs import SortSpec`.
  - Build `SortSpec` over `app.config["kerko_composer"].fields['sort_date_added']` with `reverse=True`.
  - `results = searcher.search(limit=5, sort_spec=sort_spec)` → `results.items(field_specs)` where `field_specs` includes `id` and `data`.

## Configuration
- App config sources, in order:
  1) Kerko defaults (from the Kerko package)
  2) TOML files via `load_config_files(app, env KERKOAPP_CONFIG_FILES)` (defaults to `config.toml;instance.toml;.secrets.toml` search)
  3) Environment variables with `KERKOAPP_` prefix
- Example settings in top-level `config.toml`:
  - Navbar links (Home, Bibliography, Dashboard), breadcrumb base label, facets toggles, Zotero library config.
- Instance path is `KERKOAPP_INSTANCE_PATH` (env var) or Flask’s default instance folder; Kerko resolves data paths under it.

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
  - How to pass `total_count` and `newest_items`.
  - How to link into Kerko search and item views.
- Analytics dashboard: `kerkoapp/dashboard.py` shows direct Whoosh reads (outside Kerko’s Searcher) to compute stats.

If anything above is unclear (e.g., how you want index sync documented for non-Docker local dev, or preferred lint/test commands), tell me and I’ll refine these notes. 