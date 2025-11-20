# strato-acme

This repository contains
1. Python API for acccess to DNS system for a domain hosted at strato.de.

## Setup

Create `strato-auth.json`:

```json
{
  "location": "de", // Supports de and nl
  "credentials": {
    "username": "<username>",
    "password": "<password>"
  }
}
```

Make sure to make this file only readable for root:

`sudo chmod 0400 strato-auth.json`

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
python3 -m strato_dns_api --config myconfig.json get-records --domain example.com
```

This will return the current CNAME/TXT records available on this domain.
For more commands, see the CLI help.


