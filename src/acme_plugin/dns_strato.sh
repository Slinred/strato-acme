#!/usr/bin/env sh
# shellcheck disable=SC2034
dns_cf_info='Strato
Site: strato.de
Options:
  STRATO_API_CONFIG_FILE  Strato API configuration file path
Requires:
  - python > 3.10
  - python package strato-dns-api
'

PYTHON_STRATO_DNS_API_MODULE="strato-dns-api"

########  Public functions #####################

#Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_strato_add() {
  fulldomain=$1
  txtvalue=$2

  if ! _load_env; then
    _err "failed to load environment"
    return 1
  fi

  _saveaccountconf_mutable STRATO_API_CONFIG_FILE "$STRATO_API_CONFIG_FILE"

  python3 -m strato_dns_api --config "$STRATO_API_CONFIG_FILE" add-record --record-type TXT --domain "$fulldomain" --value "$txtvalue"

  return $?
}

dns_strato_rm() {
  fulldomain=$1
  txtvalue=$2

  if ! _load_env; then
    _err "failed to load environment"
    return 1
  fi

  python3 -m strato_dns_api --config "$STRATO_API_CONFIG_FILE" del-record --record-type TXT --domain "$fulldomain"

  return $?
}

_load_env() {
  STRATO_API_CONFIG_FILE="${STRATO_API_CONFIG_FILE:-$(_readaccountconf_mutable STRATO_API_CONFIG_FILE)}"

  if [ -z "$STRATO_API_CONFIG_FILE" ]; then
    _err "You must specify 'STRATO_API_CONFIG_FILE' in your account conf file."
    return 1
  fi
  _debug "Using Strato API config file: $STRATO_API_CONFIG_FILE"

  return 0
}
