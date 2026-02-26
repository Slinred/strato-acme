#! /bin/bash
set -euo pipefail

# Default to root if PUID and PGID are not set
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

trap "deactivate || exit" EXIT

echo "CRON: Scheduled renewal of certificates as user=$USER_ID and group=$GROUP_ID..."
source /etc/environment
source ${STRATO_ACME_VENV_DIR}/bin/activate
set -x
su-exec $USER_ID:$GROUP_ID sh -c "acme.sh --cron \
  --home ${STRATO_ACME_INSTALL_DIR} \
  --cert-home ${STRATO_ACME_CERTS_DIR} \
  --config-home ${STRATO_ACME_CONFIG_DIR} \
  --log ${STRATO_ACME_LOG_FILE}"
Result=$?
{ set +x; } &> /dev/null

if [ $Result -ne 0 ]; then
  echo "acme.sh failed with exit code $Result"
  echo "Check the log file at ${STRATO_ACME_LOG_FILE} for more details."
  exit $Result
fi
