<<<<<<< HEAD
# This Makefile contains targets for building and running the KerkoApp Docker image.
# modified to change to podman commands
# Change IMAGE_NAME if you wish to build your own image.
IMAGE_NAME := scsu_authors/kerkoapp
=======
# This Makefile aims to facilitate common development tasks (POSIX-only).

.DEFAULT_GOAL := help
>>>>>>> b4acff38892567f3c617745f99058d31ba5cf0b6

MAKEFILE_DIR := $(dir $(CURDIR)/$(lastword $(MAKEFILE_LIST)))
<<<<<<< HEAD
HOST_PORT := 8080
HOST_INSTANCE_PATH := $(MAKEFILE_DIR)instance
HOST_DEV_LOG := /tmp/kerkoapp-dev-log

SECRETS := $(HOST_INSTANCE_PATH)/.secrets.toml
CONFIG := $(HOST_INSTANCE_PATH)/config.toml
DATA := $(HOST_INSTANCE_PATH)/kerko/index

#
# Running targets.
#
# These work if the image exists, either pulled or built locally.
#

.PHONY: help
help:
	@echo "Commands for using KerkoApp with Docker:"
	@echo "    make build"
	@echo "        Build a KerkoApp Docker image locally."
	@echo "    make clean_image"
	@echo "        Remove the KerkoApp Docker image."
	@echo "    make clean_kerko"
	@echo "        Run the 'kerko clean' command from within the KerkoApp Docker container."
	@echo "    make publish"
	@echo "        Publish the KerkoApp Docker image on DockerHub."
	@echo "    make run"
	@echo "        Run KerkoApp with Docker."
	@echo "    make shell"
	@echo "        Start an interactive shell within the KerkoApp Docker container."
	@echo "    make show_version"
	@echo "        Print the version that would be used if the KerkoApp Docker image was to be built."
	@echo "\nCommands related to KerkoApp development:"
	@echo "    make requirements"
	@echo "        Pin the versions of Python dependencies in requirements files."
	@echo "    make requirements-upgrade"
	@echo "        Pin the latest versions of Python dependencies in requirements files."
	@echo "    make upgrade"
	@echo "        Update Python dependencies and install the upgraded versions."

# On some systems, extended privileges are required for Gunicorn to launch within the container,
# hence the use of the --privileged option below. For production use, you may want to verify whether
# this option is really required for your system, or grant finer grained privileges. See
# https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
.PHONY: run
run: | $(DATA) $(SECRETS) $(CONFIG)
	podman run --name $(CONTAINER_NAME) --rm -p $(HOST_PORT):8000 -v $(HOST_INSTANCE_PATH):/kerkoapp/instance:Z --log-driver json-file --log-opt max-size=10m --log-opt max-file=10 $(IMAGE_NAME)

.PHONY: shell
shell:
	podman run --name $(CONTAINER_NAME) -it --rm -p $(HOST_PORT):8000 -v $(HOST_INSTANCE_PATH):/kerkoapp/instance:Z $(IMAGE_NAME) bash
.PHONY: clean_kerko
clean_kerko: | $(SECRETS) $(CONFIG)
	podman run --name $(CONTAINER_NAME) --rm -p $(HOST_PORT):8000 -v $(HOST_INSTANCE_PATH):/kerkoapp/instance:Z $(IMAGE_NAME) flask kerko clean everything
$(DATA): | $(SECRETS) $(CONFIG)
	@echo "[INFO] It looks like you have not run the 'flask kerko sync' command. Running it for you now!"
	podman run --name $(CONTAINER_NAME) --rm -p $(HOST_PORT):8000 -v $(HOST_INSTANCE_PATH):/kerkoapp/instance:Z $(IMAGE_NAME) flask kerko sync

$(SECRETS):
	@echo "[ERROR] You must create '$(SECRETS)'."
	@exit 1

$(CONFIG):
	@echo "[ERROR] You must create '$(CONFIG)'."
	@exit 1

#
# Building and publishing targets.
#
# These work from a clone of the KerkoApp Git repository.
#
=======
>>>>>>> b4acff38892567f3c617745f99058d31ba5cf0b6

HASH = $(shell git rev-parse HEAD 2>/dev/null)
VERSION = $(shell git describe --exact-match --tags HEAD 2>/dev/null)

<<<<<<< HEAD
.PHONY: publish
publish: | .git build
ifneq ($(shell git status --porcelain 2> /dev/null),)
	@echo "[ERROR] The Git working directory has uncommitted changes."
	@exit 1
endif
ifeq ($(findstring .,$(VERSION)),.)
	podman tag $(IMAGE_NAME) $(IMAGE_NAME):$(VERSION)
	podman push $(IMAGE_NAME):$(VERSION)
	podman tag $(IMAGE_NAME) $(IMAGE_NAME):latest
	podman push $(IMAGE_NAME):latest
else
	@echo "[ERROR] A proper version tag on the Git HEAD is required to publish."
	@exit 1
endif

.PHONY: build
build: | .git
ifeq ($(findstring .,$(VERSION)),.)
	podman build -t $(IMAGE_NAME) --no-cache --label "org.opencontainers.image.version=$(VERSION)" --label "org.opencontainers.image.created=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" $(MAKEFILE_DIR)
else
	podman build -t $(IMAGE_NAME) --no-cache --label "org.opencontainers.image.revision=$(HASH)" --label "org.opencontainers.image.created=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" $(MAKEFILE_DIR)
endif
=======
# Change DOCKER_IMAGE_NAME if you wish to build your own image.
DOCKER_IMAGE_NAME := whiskyechobravo/kerkoapp
DOCKER_CONTAINER_NAME := kerkoapp

DOCKER_HOST_PORT := 8080
DOCKER_HOST_DEV_LOG := /dev/log
DOCKER_HOST_KERKOAPP_INSTANCE_PATH := $(MAKEFILE_DIR)instance
DOCKER_HOST_KERKOAPP_SECRETS_PATH := $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH)/.secrets.toml
DOCKER_HOST_KERKOAPP_CONFIG_PATH := $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH)/config.toml
DOCKER_HOST_KERKOAPP_DATA_PATH := $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH)/kerko
DOCKER_HOST_KERKOAPP_INDEX_PATH := $(DOCKER_HOST_KERKOAPP_DATA_PATH)/index
>>>>>>> b4acff38892567f3c617745f99058d31ba5cf0b6

.PHONY: help
help:
	@echo "Welcome to KerkoApp!"
	@echo "Managing the KerkoApp Docker image:\n"
	@echo "    docker-image-build"
	@echo "        Build a KerkoApp Docker image locally."
	@echo "    docker-image-clean"
	@echo "        Remove the KerkoApp Docker image."
	@echo "    docker-image-publish"
	@echo "        Publish the KerkoApp Docker image on DockerHub."
	@echo "    show-version"
	@echo "        Print the version that will be used when labelling the KerkoApp Docker image."
	@echo ""
	@echo "    Notes:"
	@echo "        These targets require Docker Engine."
	@echo ""
	@echo "Running the KerkoApp Docker container:\n"
	@echo "    docker-kerko-clean"
	@echo "        Run the 'kerko clean' command in the container."
	@echo "    docker-kerko-sync"
	@echo "        Run the 'kerko sync' command in the container."
	@echo "    docker-kerko-run"
	@echo "        Serve KerkoApp with the container."
	@echo "    docker-shell"
	@echo "        Start an interactive shell in the container."
	@echo ""
	@echo "    Notes:"
	@echo "        These targets require Docker Engine."
	@echo "        Host secrets path: $(DOCKER_HOST_KERKOAPP_SECRETS_PATH)"
	@echo "        Host config path: $(DOCKER_HOST_KERKOAPP_CONFIG_PATH)"
	@echo "        Host data path: $(DOCKER_HOST_KERKOAPP_DATA_PATH)"
	@echo ""
	@echo "Development:\n"
	@echo "    requirements"
	@echo "        Pin the versions of Python dependencies in requirements files."
	@echo "    requirements-upgrade"
	@echo "        Pin the latest versions of Python dependencies in requirements files."
	@echo "    upgrade"
	@echo "        Update Python dependencies and install the upgraded versions."
	@echo ""
	@echo "    Notes:"
	@echo "        The Python virtual environment must be activated before running these targets."

.git:
	@echo "[ERROR] This target must run from a clone of the KerkoApp Git repository."
	@exit 1

.PHONY: show-version
show-version: | .git
ifeq ($(findstring .,$(VERSION)),.)
	@echo "$(VERSION)"
else
	@echo "$(HASH)"
endif

.PHONY: docker-image-build
docker-image-build: | .git
ifeq ($(findstring .,$(VERSION)),.)
<<<<<<< HEAD
	podman rmi $(IMAGE_NAME):$(VERSION)
else
	podman rmi $(IMAGE_NAME)
=======
	docker build -t $(DOCKER_IMAGE_NAME) --no-cache --label "org.opencontainers.image.version=$(VERSION)" --label "org.opencontainers.image.created=$(shell date --rfc-3339=seconds)" $(MAKEFILE_DIR)
else
	docker build -t $(DOCKER_IMAGE_NAME) --no-cache --label "org.opencontainers.image.revision=$(HASH)" --label "org.opencontainers.image.created=$(shell date --rfc-3339=seconds)" $(MAKEFILE_DIR)
>>>>>>> b4acff38892567f3c617745f99058d31ba5cf0b6
endif

.PHONY: docker-image-clean
docker-image-clean: | .git
ifeq ($(findstring .,$(VERSION)),.)
	docker rmi $(DOCKER_IMAGE_NAME):$(VERSION)
else
	docker rmi $(DOCKER_IMAGE_NAME)
endif

.PHONY: docker-image-publish
docker-image-publish: | .git docker-image-build
ifneq ($(shell git status --porcelain 2> /dev/null),)
	@echo "[ERROR] The Git working directory has uncommitted changes."
	@exit 1
endif
ifeq ($(findstring .,$(VERSION)),.)
	docker tag $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME):$(VERSION)
	docker push $(DOCKER_IMAGE_NAME):$(VERSION)
	docker tag $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME):latest
	docker push $(DOCKER_IMAGE_NAME):latest
else
	@echo "[ERROR] A proper version tag on the Git HEAD is required to publish."
	@exit 1
endif

.PHONY: docker-shell
docker-shell:
	docker run --name $(DOCKER_CONTAINER_NAME) -it --rm -p $(DOCKER_HOST_PORT):80 -v $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH):/kerko/instance -v $(DOCKER_HOST_DEV_LOG):/dev/log $(DOCKER_IMAGE_NAME) bash

$(DOCKER_HOST_KERKOAPP_SECRETS_PATH):
	@echo "[ERROR] You must create '$(DOCKER_HOST_KERKOAPP_SECRETS_PATH)'."
	@exit 1

$(DOCKER_HOST_KERKOAPP_CONFIG_PATH):
	@echo "[ERROR] You must create '$(DOCKER_HOST_KERKOAPP_CONFIG_PATH)'."
	@exit 1

$(DOCKER_HOST_KERKOAPP_INDEX_PATH): | $(DOCKER_HOST_KERKOAPP_SECRETS_PATH) $(DOCKER_HOST_KERKOAPP_CONFIG_PATH)
	@echo "[INFO] Looks like the 'kerko sync' command has not been run yet. Running it for you now!"
	docker run --name $(DOCKER_CONTAINER_NAME) --rm -p $(DOCKER_HOST_PORT):80 -v $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH):/kerko/instance -v $(DOCKER_HOST_DEV_LOG):/dev/log $(DOCKER_IMAGE_NAME) flask kerko sync

# On some systems, extended privileges are required for Gunicorn to launch within the container,
# hence the use of the --privileged option below. For production use, you may want to verify whether
# this option is really required for your system, or grant finer grained privileges. See
# https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
.PHONY: docker-kerko-run
docker-kerko-run: | $(DOCKER_HOST_KERKOAPP_INDEX_PATH) $(DOCKER_HOST_KERKOAPP_SECRETS_PATH) $(DOCKER_HOST_KERKOAPP_CONFIG_PATH)
	docker run --privileged --name $(DOCKER_CONTAINER_NAME) --rm -p $(DOCKER_HOST_PORT):80 -v $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH):/kerko/instance -v $(DOCKER_HOST_DEV_LOG):/dev/log $(DOCKER_IMAGE_NAME)

.PHONY: docker-kerko-clean
docker-kerko-clean: | $(DOCKER_HOST_KERKOAPP_SECRETS_PATH) $(DOCKER_HOST_KERKOAPP_CONFIG_PATH)
	docker run --name $(DOCKER_CONTAINER_NAME) --rm -p $(DOCKER_HOST_PORT):80 -v $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH):/kerko/instance -v $(DOCKER_HOST_DEV_LOG):/dev/log $(DOCKER_IMAGE_NAME) flask kerko clean everything --files

.PHONY: docker-kerko-sync
docker-kerko-sync: | $(DOCKER_HOST_KERKOAPP_SECRETS_PATH) $(DOCKER_HOST_KERKOAPP_CONFIG_PATH)
	docker run --name $(DOCKER_CONTAINER_NAME) --rm -p $(DOCKER_HOST_PORT):80 -v $(DOCKER_HOST_KERKOAPP_INSTANCE_PATH):/kerko/instance -v $(DOCKER_HOST_DEV_LOG):/dev/log $(DOCKER_IMAGE_NAME) flask kerko sync

requirements/run.txt: requirements/run.in
	pip-compile --resolver=backtracking requirements/run.in
	sed -i -E 's|(\s*#\s+(via\s+)?-r\s+).*/(requirements/.+\.txt)|\1\3|' requirements/run.txt

requirements/serve.txt: requirements/run.txt requirements/serve.in
	pip-compile --resolver=backtracking requirements/serve.in
	sed -i -E 's|(\s*#\s+(via\s+)?-r\s+).*/(requirements/.+\.txt)|\1\3|' requirements/serve.txt

requirements/dev.txt: requirements/run.txt requirements/dev.in
	pip-compile --allow-unsafe --resolver=backtracking requirements/dev.in
	sed -i -E 's|(\s*#\s+(via\s+)?-r\s+).*/(requirements/.+\.txt)|\1\3|' requirements/dev.txt

.PHONY: requirements
requirements: requirements/run.txt requirements/serve.txt requirements/dev.txt

# Note: The sed command works around issue https://github.com/jazzband/pip-tools/issues/2131
.PHONY: requirements-upgrade
requirements-upgrade:
	pre-commit autoupdate
	pip install --upgrade pip pip-tools
	pip-compile --upgrade --resolver=backtracking --rebuild requirements/run.in
	pip-compile --upgrade --resolver=backtracking --rebuild requirements/serve.in
	pip-compile --upgrade --allow-unsafe --resolver=backtracking --rebuild requirements/dev.in
	sed -i -E 's|(\s*#\s+(via\s+)?-r\s+).*/(requirements/.+\.txt)|\1\3|' requirements/*.txt

.PHONY: upgrade
upgrade: | requirements-upgrade
	pip-sync requirements/dev.txt
