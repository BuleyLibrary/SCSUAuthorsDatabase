# SCSU CSC400 Capstone: Biblography Site Upgrade

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


[Kerko]: https://github.com/whiskyechobravo/kerko
[Kerko_documentation]: https://whiskyechobravo.github.io/kerko/
[KerkoApp]: https://github.com/whiskyechobravo/kerkoapp
[KerkoApp_demo]: https://demo.kerko.whiskyechobravo.com
[Flask]: https://pypi.org/project/Flask/
[Python]: https://www.python.org/
[TOML]: https://toml.io/
[Zotero]: https://www.zotero.org/
[Zotero_demo]: https://www.zotero.org/groups/2348869/kerko_demo/items
