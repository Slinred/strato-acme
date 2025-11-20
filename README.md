# strato-acme

[![Build python package](https://github.com/Slinred/strato-acme/actions/workflows/build-python-package.yml/badge.svg)](https://github.com/Slinred/strato-acme/actions/workflows/build-python-package.yml)

This repository contains
1. Python API for acccess to DNS system for a domain hosted at strato.de
1. Docker container for ready-to-go usage

## Setup

Create `strato-acme-config.json`:

```json
{
  "location": "de", // Supports de and nl
  "credentials": {
    "username": "<username>",
    "password": "<password>"
  }
}
```

Make sure to make this file only readable for the user in the container:

`sudo chmod 0400 strato-acme-config.json`

### Two-Factor Authentification

To be able to authenticate two-factor, device name and TOTP secret must be entered into the JSON. If it is not used, it can either be empty strings or the entries can be removed completely (see above).

```json
{
  "location": "de",
  "credentials": {
    "username": "<username>",
    "password": "<password>",
    "totp_secret": "<secret>",
    "totp_devicename": "<devicename>"
  }
}
```

## Usage

### Python API

When the package `strato-dns-api` is installed you can run it via
```
python3 -m strato_dns_api --config strato-acme-config.json get-records --domain example.com
```

This will return the current CNAME/TXT records available on this domain.
For more commands, see the CLI help.


### Docker

The repository also contains a ready-to-go docker container/image that wrpas the acme.sh script and the python API for access to strato DNS.
This allows for automatic certifacte generation/renewals and allows to create wildcard certificates.

To build the image locally, run `./docker/build.sh --load` to build the image for all supported platforms in the current version and load it into your local docker images

#### Requirements

1. You need to create directory `config` and place a file called `strato-acme-config.json` inside which is filled with your strato API config (see above)<br>
This config folder should be mapped into the container under `/strato-acme/config` and will also then contain the acme.sh settings
1. You need to create a directory or a docker volume which should be mounted under `/strato-acme/certs` to be able to persist and share certificates with other containers (e.g. traefik)
1. If you also want to persist logs, mount a folder under `/strato-acme/logs`

For a reference, see [docker-compose.yml](docker//docker-compose.yml)

#### Create certificates

When the container is running in the background (e.g. via `docker compose up -d ...`) use the following command to trigger certificate generation:
```
docker exec strato_acme create-new-wildcard-cert.sh <YOUR_DOMAIN> <YOUR_EMAIL>
```
This will then try to generate a wildcard certificate for `<YOUR_DOMAIN>` and `*.<YOUR_DOMAIN>`.
If generation was successfull, there will also be a cron job created to automatically renew the certificate before expiration (see official acme.sh docs).

