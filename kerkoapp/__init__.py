"""
A sample Flask application using the Kerko blueprint.
"""

import os
import sys
from pathlib import Path
from logging.handlers import RotatingFileHandler
import logging as py_logging

import kerko
from flask import Flask, render_template
from kerko.storage import get_doc_count, open_index
from kerko.searcher import Searcher
from kerko.specs import SortSpec
from flask_babel import get_locale
from kerko.config_helpers import config_update, parse_config

from . import logging
from .dashboard import dashboard_bp
from .config_helpers import KerkoAppModel, load_config_files
from .extensions import babel, bootstrap



def create_app() -> Flask:
    """
    Application factory.

    Explained here: http://flask.pocoo.org/docs/patterns/appfactories/
    """
    try:
        app = Flask(__name__, template_folder="templates", instance_path=os.environ.get("KERKOAPP_INSTANCE_PATH"))
    except ValueError as e:
        msg = f"Unable to initialize the application. {e}"
        raise RuntimeError(msg) from e

    # Initialize app configuration with Kerko's defaults.
    config_update(app.config, kerko.DEFAULTS)

    # Update app configuration from TOML configuration file(s).
    load_config_files(app, os.environ.get("KERKOAPP_CONFIG_FILES"))

    # Update app configuration from environment variables.
    app.config.from_prefixed_env(prefix="KERKOAPP")

    # Validate configuration and save its parsed version.
    parse_config(app.config)

    # Validate extra configuration model and save its parsed version.
    if app.config.get("kerkoapp"):
        parse_config(app.config, "kerkoapp", KerkoAppModel)

    # Initialize the Composer object.
    app.config["kerko_composer"] = kerko.composer.Composer(app.config)

    # ----
    # If you are deriving your own custom application from KerkoApp, here is a
    # good place to alter the Composer object, perhaps adding facets.
    # ----

    # Configure file logging
    configure_file_logging(app)

    #Helper functions for KerkoApp
    register_extensions(app)
    register_blueprints(app)
    register_errorhandlers(app)
    register_routes(app)
    return app


def configure_file_logging(app: Flask) -> None:
    """
    Configure logging to write console output to a file.
    Logs go to instance/logs/app.log with rotation.
    """
    log_dir = Path(app.instance_path) / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "app.log"
    
    # Create rotating file handler
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=10_485_760,  # 10MB
        backupCount=10
    )
    file_handler.setFormatter(py_logging.Formatter(
        '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
    ))
    file_handler.setLevel(py_logging.INFO)
    app.logger.addHandler(file_handler)
    
    # Also add console output
    console_handler = py_logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(py_logging.Formatter(
        '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
    ))
    console_handler.setLevel(py_logging.INFO)
    app.logger.addHandler(console_handler)
    
    app.logger.setLevel(py_logging.INFO)
    app.logger.info('KerkoApp startup - logging configured')


def register_extensions(app: Flask) -> None:
    # Initialize Babel to use translations from both Kerko and the app. Config
    # parameters BABEL_DOMAIN and BABEL_TRANSLATION_DIRECTORIES may override
    # these defaults. When multiple translation directories are used, a domain
    # MUST be specified for each directory. Thus, both lists must have the same
    # number of items (separated by semi-colons).
    domain = f"{kerko.TRANSLATION_DOMAIN};messages"
    directories = f"{kerko.TRANSLATION_DIRECTORY};translations"
    babel.init_app(
        app,
        default_domain=domain,
        default_translation_directories=directories,
    )

    logging.init_app(app)
    bootstrap.init_app(app)

def register_blueprints(app: Flask) -> None:
    # Setting `url_prefix` is required to distinguish the blueprint's static
    # folder route URL from the app's.
    app.register_blueprint(kerko.make_blueprint(), url_prefix="/bibliography")
    #DASHBOOARD BLUEPRINT (ROOT/SPLASHPAGE URL '/dashboard') WITH REDIRECT TO MAIN BIB
    app.register_blueprint(dashboard_bp, url_prefix="/bibliography")


def register_routes(app: Flask) -> None:
    """Register app-level routes outside of blueprints."""

    @app.route("/")
    def landing_page():
        """
        Render the site's landing page.

        Provides `total_count` and `newest_items` to the template based on Kerko's index.
        """
        total_count = 0
        newest_items = []
        
        try:
            total_count = get_doc_count("index")
        except Exception as e:  # pragma: no cover - non-fatal display fallback
            app.logger.warning(f"Unable to retrieve index document count: {e}")
        
        # Fetch the 5 newest items from the index
        try:
            index = open_index("index")
            with Searcher(index) as searcher:
                # Get the sort field for date added
                sort_field = app.config["kerko_composer"].fields.get("sort_date_added")
                if sort_field:
                    sort_spec = SortSpec(
                        key="date_added_desc",
                        label="",
                        fields=[sort_field],
                        reverse=True,
                    )
                    results = searcher.search(
                        keywords=None,
                        sort_spec=sort_spec,
                        limit=5
                    )
                    # Get the field specs we need for display
                    field_specs = {
                        "id": app.config["kerko_composer"].fields.get("id"),
                        "data": app.config["kerko_composer"].fields.get("data"),
                    }
                    newest_items = results.items(field_specs)
        except Exception as e:  # pragma: no cover - non-fatal display fallback
            app.logger.warning(f"Unable to retrieve newest items: {e}")
        
        return render_template(
            "landing.html.jinja2",
            total_count=total_count,
            newest_items=newest_items,
            title="SCSU Authors"
        )


def register_errorhandlers(app: Flask) -> None:
    def render_error(error):
        # If a HTTPException, pull the `code` attribute; default to 500.
        error_code = getattr(error, "code", 500)
        context = {
            "locale": get_locale(),
        }
        return render_template(f"kerkoapp/{error_code}.html.jinja2", **context), error_code

    for errcode in [400, 403, 404, 500, 503]:
        app.errorhandler(errcode)(render_error)