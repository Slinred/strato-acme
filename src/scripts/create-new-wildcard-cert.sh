#! /bin/bash
set -euo pipefail

# Default to root if PUID and PGID are not set
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}
domain=""
email=""

# Parse options
extra_opts=()
while [ $# -gt 0 ]; do
  case "$1" in
    --domain)
      domain="$2"
      shift 2
      ;;
    --email)
      email="$2"
      shift 2
      ;;
    --)
      shift
      extra_opts+=("$@")
      break
      ;;
    *)
      extra_opts+=("$1")
      shift
      ;;
  esac
done

if [ -z "$domain" ] || [ -z "$email" ]; then
  echo "Usage: $(basename $0) --domain DOMAIN --email EMAIL [extra acme.sh options]"
  exit 1
fi

# Accept either DOMAIN or *.DOMAIN and normalize to base domain.
if [[ "$domain" == \*.* ]]; then
  domain="${domain#*.}"
fi

echo "Creating certificates as user=$USER_ID and group=$GROUP_ID..." &&
source /etc/environment
set -x
su-exec $USER_ID:$GROUP_ID acme.sh --register-account \
  -m "$email" \
  --home ${STRATO_ACME_INSTALL_DIR} \
  --cert-home ${STRATO_ACME_CERTS_DIR} \
  --config-home ${STRATO_ACME_CONFIG_DIR} \
  --log ${STRATO_ACME_LOG_FILE}

su-exec $USER_ID:$GROUP_ID acme.sh --issue \
  -d "$domain" -d "*.$domain" \
  --no-cron \
  --accountemail "$email" \
  --dns dns_strato \
  --home ${STRATO_ACME_INSTALL_DIR} \
  --cert-home ${STRATO_ACME_CERTS_DIR} \
  --config-home ${STRATO_ACME_CONFIG_DIR} \
  --log ${STRATO_ACME_LOG_FILE} \
  "${extra_opts[@]}"

Result=$?
{ set +x; } &> /dev/null

if [ $Result -ne 0 ]; then
  echo "acme.sh failed with exit code $Result"
  exit $Result
fi

echo "Certificates created!"
