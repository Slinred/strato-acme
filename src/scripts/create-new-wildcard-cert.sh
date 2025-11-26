#! /bin/sh

# Default to root if PUID and PGID are not set
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

# Parse options
extra_opts=""
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
    --*)
      extra_opts="$extra_opts $1"
      shift
      ;;
    *)
      # Stop parsing options at first non-option argument
      break
      ;;
  esac
done

if [ -z "$domain" ] || [ -z "$email" ]; then
  echo "Usage: $(basename $0) --domain DOMAIN --email EMAIL [extra acme.sh options]"
  exit 1
fi

echo "Creating certificates as user=$USER_ID and group=$GROUP_ID..." &&
source /etc/environment
source ${STRATO_ACME_VENV_DIR}/bin/activate
set -x
su-exec $USER_ID:$GROUP_ID sh -c "acme.sh --issue \
  -d '$domain' -d '*.$domain' \
  --no-cron \
  --dns dns_strato \
  --cert-home ${STRATO_ACME_CERTS_DIR} \
  --config-home ${STRATO_ACME_CONFIG_DIR} \
  --log ${STRATO_ACME_LOG_FILE}" $extra_opts

Result=$?
{ set +x; } &> /dev/null

if [ $Result -ne 0 ]; then
  echo "acme.sh failed with exit code $Result"
  exit $Result
fi

echo "Certificates created!"

deactivate