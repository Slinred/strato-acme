#! /bin/bash
set -euo pipefail

# cron jobs run with a minimal environment, so PUID/PGID (persisted by the
# entrypoint) must be loaded before defaulting them, or this always resolves to root
source /etc/environment

# Default to root if PUID and PGID are not set
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

echo "CRON: Scheduled renewal of certificates as user=$USER_ID and group=$GROUP_ID..."
set -x
# crond already runs this job as the crontab's owning user (certuser/root, matched
# to USER_ID:GROUP_ID via the crontab file used), so su-exec is only needed when
# that's not already the case (e.g. run manually as root)
if [ "$(id -u)" = "$USER_ID" ] && [ "$(id -g)" = "$GROUP_ID" ]; then
  acme.sh --cron \
    --home "${STRATO_ACME_INSTALL_DIR}" \
    --cert-home "${STRATO_ACME_CERTS_DIR}" \
    --config-home "${STRATO_ACME_CONFIG_DIR}" \
    --log "${STRATO_ACME_LOG_FILE}"
else
  su-exec "$USER_ID:$GROUP_ID" sh -c "acme.sh --cron \
    --home ${STRATO_ACME_INSTALL_DIR} \
    --cert-home ${STRATO_ACME_CERTS_DIR} \
    --config-home ${STRATO_ACME_CONFIG_DIR} \
    --log ${STRATO_ACME_LOG_FILE}"
fi
Result=$?
{ set +x; } &> /dev/null

if [ $Result -ne 0 ]; then
  echo "acme.sh failed with exit code $Result"
  echo "Check the log file at ${STRATO_ACME_LOG_FILE} for more details."
  exit $Result
fi
