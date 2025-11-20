#! /bin/sh

# Default to root if PUID and PGID are not set
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

if [ "$#" -ne 2 ]; then
    echo "Usage: $(basename $0) ROOT_DOMAIN EMAIL"
    exit 1
fi

domain=$1
email=$2

echo "Creating certificates as user=$USER_ID and group=$GROUP_ID..." &&
source /etc/environment
source ${STRATO_ACME_VENV_DIR}/bin/activate
set -x
su-exec $USER_ID:$GROUP_ID sh -c "acme.sh --issue --staging \
  -d '$domain' -d '*.$domain' \
  --no-cron \
  --dns dns_strato \
  --cert-home ${STRATO_ACME_CERTS_DIR} \
  --config-home ${STRATO_ACME_CONFIG_DIR} \
  --log ${STRATO_ACME_LOG_FILE}"

Result=$?
{ set +x; } &> /dev/null

if [ $Result -ne 0 ]; then
  echo "acme.sh failed with exit code $Result"
  exit $Result
fi

echo "Certificates created!"

deactivate