# SCSU CSC400 Capstone: Bibliography Site Upgrade

You can follow the standard installation provided in the docs below, with one change:

git clone --branch https://github.com/robertorozco1/CSC400_SCSU_Authors.git
- No version number needed
- config.toml is already made. Use that version and update with your own Zotero API Key and UserID (needed to maintain navbar with dashboard link, as well as collections facete.)
cd CSC400_SCSU_Authors
python -m venv venv
venv\Scripts\activate.bat
pip install -r requirements\run.txt

then follow as directed! 

Brought to you by too much caffeine and too little sleep
(and also myself and Malik Williams https://github.com/MalikWilliamsSCSU)


# KerkoApp

[KerkoApp] is a web application that uses [Kerko] to provide a user-friendly
search and browsing interface for sharing a bibliography managed with the
[Zotero] reference manager.

KerkoApp is built in [Python] with the [Flask] framework. It is just a thin
container around Kerko and, as such, inherits most of its features directly from
Kerko. However, it adds support for [TOML] configuration files, allowing a good
separation of configuration from code.

Although KerkoApp offers many configuration options, more advanced
customizations might require building a custom application, possibly using
KerkoApp as a starting point, where various aspects of Kerko could be extended
or adapted through its Python API.


## Demo site

A [KerkoApp demo site][KerkoApp_demo] is available for you to try. You may also
view the [Zotero library][Zotero_demo] that contains the source data for the
demo site.


## Learn more

Please refer to the [documentation][Kerko_documentation] for more details.


## Landing page

This app now serves a simple landing page at the site root (`/`) using the template at `kerkoapp/templates/landing.html.jinja2`.

- It extends Kerko's base page (`extends config.kerko.templates.page`).
- The route is defined in `kerkoapp/__init__.py` and passes a `total_count` value (number of indexed items) to the template via Kerko's index.
- Links to the bibliography use `url_for('kerko.search', ...)` so they honor the configured blueprint prefix (`/bibliography`).

If you want to customize the landing content or styling, edit `kerkoapp/templates/landing.html.jinja2`.

## Dashboard

The dashboard at `/bibliography/dashboard` shows:

- A bar chart of publications per year plus one pie chart (item types) in `kerkoapp/templates/dashboard.html.jinja2`.
- Charts use Whoosh index data; ensure you have synced the index (`flask kerko sync`) before viewing.

To adjust analytics or navbar styling across the app, see the template overrides under `kerkoapp/templates/kerko/`.


## Logging

Application logs are automatically written to `instance/logs/app.log` with the following features:

- **Log rotation**: Files rotate at 10MB, keeping 10 backup files (~100MB total history)
- **Console + file output**: Logs appear in both terminal and file for easy debugging
- **Format**: `[timestamp] LEVEL in module: message`

### Viewing logs

```bash
# Tail the log file
tail -f instance/logs/app.log

# For Docker runs, also check container logs
docker logs -f kerkoapp
```

The log directory is automatically created on first run and excluded from version control.


[Kerko]: https://github.com/whiskyechobravo/kerko
[Kerko_documentation]: https://whiskyechobravo.github.io/kerko/
[KerkoApp]: https://github.com/whiskyechobravo/kerkoapp
[KerkoApp_demo]: https://demo.kerko.whiskyechobravo.com
[Flask]: https://pypi.org/project/Flask/
[Python]: https://www.python.org/
[TOML]: https://toml.io/
[Zotero]: https://www.zotero.org/
[Zotero_demo]: https://www.zotero.org/groups/2348869/kerko_demo/items
