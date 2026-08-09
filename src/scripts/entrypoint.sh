#!/bin/bash
set -euo pipefail

# Default to root if PUID and PGID are not set
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

echo "Starting strato-acme container..."
echo "Running as user=$USER_ID and group=$GROUP_ID"

# If PUID and PGID are specified, create a user and group with those IDs
if [ "$USER_ID" -ne 0 ] || [ "$GROUP_ID" -ne 0 ]; then
    CERTUSER="certuser"

    # Create group if it doesn't exist
    if ! getent group certgroup >/dev/null 2>&1; then
        addgroup -g "$GROUP_ID" certgroup
    fi

    # Create user if it doesn't exist
    if ! getent passwd certuser >/dev/null 2>&1; then
        adduser -D -u "$USER_ID" -h /home/${CERTUSER} -G certgroup $CERTUSER
    fi
    # Recursively own the certificate directory to certgroup and give rwxrwx--x permissions
    chown -R $USER_ID:$GROUP_ID ${STRATO_ACME_DIR} &&
    chmod -R 771 ${STRATO_ACME_CERTS_DIR} &&
    chown -R $USER_ID:$GROUP_ID $STRATO_ACME_LOGS_DIR &&
    chmod -R 771 $STRATO_ACME_LOGS_DIR
else
    CERTUSER="root"
fi

# setup cronjob wrapper
# Overwrite (not append) so restarting the container doesn't duplicate the entry
echo "0 0 * * * ${STRATO_ACME_SCRIPTS_DIR}/acme_cron.sh >>/var/log/crond.log 2>&1" > /etc/crontabs/$CERTUSER
chmod 600 /etc/crontabs/$CERTUSER
echo "Cron job added for user $CERTUSER:"
cat /etc/crontabs/$CERTUSER

{
    env | grep STRATO_ | sed 's/^/export /'
    # cron jobs don't inherit the container's original environment, so PUID/PGID
    # must be persisted here too, otherwise scripts run via cron default to root
    echo "export PUID=$USER_ID"
    echo "export PGID=$GROUP_ID"
} > /etc/environment
chmod +x /etc/environment

# crond runs the cron job as $CERTUSER, so the log file it appends to must be
# writable by that user, not just root (who creates it here)
touch /var/log/crond.log &&
chown $USER_ID:$GROUP_ID /var/log/crond.log

# Start cron and keep container running
# -P: inherit PATH from this environment instead of cronie's restrictive default
# (/bin:/usr/bin:/sbin:/usr/sbin), which is missing /usr/local/bin where acme.sh
# and uv live
echo "Starting crond..."
crond -f -P &
echo "Crond started"
echo "Tailing '/var/log/crond.log'..." &&
tail -f /var/log/crond.log
