# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial version of python API for interacting with Strato domain registrar, supporting:
    - Authentication via Strato customer portal with 2FA TOTP support
    - read current TXT/CNAME records for a domain owned in strato
    - add (with optional overwrite) CNAME/TXT records
    - delete TXT/CNAME records
    - CLI interface

### Changed


### Removed

