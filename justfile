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

########################################################################################################################
# Git
########################################################################################################################

git-version:
    @git describe --tags --always --long --dirty

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

build-python:
    uv build
    uv run twine check dist/*

########################################################################################################################
# Python
########################################################################################################################

build-docker-dev:
    RELEASE_BUILD=false ./docker/build.sh $(just build-version) --load --progress plain

build-docker-release:
    RELEASE_BUILD=true ./docker/build.sh $(just build-version)
