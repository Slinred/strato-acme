# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Removed

## [0.2.3]

### Added

- information about requirements in acme plugin script

### Changed

- cleanup of python dependencies

### Removed

## [0.2.2]

### Added

### Changed

- fixed CI workflow no triggering release flow on tag creation
- fixed CI not building docker image and added pushing to registry on commits to main

### Removed

## [0.2.1]

### Added

### Changed

- fixed automated tagging on new version
- corrected changelog

### Removed

## [0.2.0]

### Added

- acme.sh dnsapi script that uses the python strato DNS api
- docker container that bundles acme.sh and strato-dns-api to support certificate generation and renewals

### Changed

- reworked CI pipelines to split normal CI and release and avoid duplicate builds
- added deployment to DockerHub on releases for docker container
- added automatic release creation in GitHub to release pipeline

### Removed

## [0.1.1] - 2025-11-20

### Added

- Status badge for pipeline to README.md

### Changed

- Fixed incorrect reference in main script from pyproject.toml, leading to failure in script execution after package installation

### Removed

- Removed unused dependencies


## [0.1.0] - 2025-11-20

### Added

- Initial version of python API for interacting with Strato domain registrar, supporting:
    - Authentication via Strato customer portal with 2FA TOTP support
    - read current TXT/CNAME records for a domain owned in strato
    - add (with optional overwrite) CNAME/TXT records
    - delete TXT/CNAME records
    - CLI interface

### Changed


### Removed

