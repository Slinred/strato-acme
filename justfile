# This is a Justfile for the homelab project. It defines various tasks that can be run using the `just` command.
# The tasks are organized into sections, such as Python setup and verification. Each task can be executed by running `just <task-name>` in the terminal.
########################################################################################################################
# Variables
########################################################################################################################

shell := "/bin/bash"
this_path := absolute_path(justfile_directory())

########################################################################################################################
# Environment
########################################################################################################################

export WORKSPACE_ROOT := this_path
export BUILD_DATE := `date -u +"%y%m%dT%H%M%S"`

########################################################################################################################
# General
# ######################################################################################################################

default:
    @just -l

format-just:
    @just --unstable --fmt

build-version seperator="-":
    @echo $(just git-version){{ seperator }}$BUILD_DATE

build-version-short seperator="-":
    @echo $(just git-version-short){{ seperator }}$BUILD_DATE

########################################################################################################################
# Git
########################################################################################################################

git-version:
    @git describe --tags --always --long --dirty

git-version-short:
    @git describe --tags --always

install-git-hooks:
    git config --local core.hooksPath .githooks
    chmod +x .githooks/*

pre-commit:
    uv run pre-commit run --all-files

########################################################################################################################
# Python
########################################################################################################################

setup-python:
    uv sync --active --compile-bytecode

verify-python:
    uv lock --check

update-python: setup-python
    uv lock --upgrade

lint-python:
    uv run ruff check . --fix

format-python:
    uv run ruff format .

build-python release="false":
    #!/bin/bash
    if [ "{{ release }}" == "true" ]; then
        export UV_PUBLISH_VERSION=$(just git-version | awk -F'-' '{print $1".post"$2}')
    else
        export UV_PUBLISH_VERSION=$(just git-version | awk -F'-' '{print $1".dev"$2}')
    fi
    UV_PUBLISH_VERSION=$UV_PUBLISH_VERSION uv build
    uv run twine check dist/*

build-python-dev: (build-python "false")

build-python-release: (build-python "true")

########################################################################################################################
# Docker
########################################################################################################################

build-docker release="false" version=`just build-version` +ARGS="":
    RELEASE_BUILD={{ release }} ./docker/build.sh {{ version }} --progress plain {{ ARGS }}

build-docker-dev: (build-docker "false" ("dev-" + `just build-version`) "--load")

build-docker-release: (build-docker "true")

push-docker-release: (build-docker "true" `just git-version` "--push")

run-docker-dev:
    docker compose -f docker/docker-compose.yml up -d --force-recreate --pull always --remove-orphans strato_acme
