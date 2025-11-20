#!/bin/sh

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

env | grep STRATO_ | sed 's/^/export /' > /etc/environment &&
chmod +x /etc/environment

# Start cron and keep container running
echo "Starting crond..."
crond -f &
echo "Crond started"
touch /var/log/crond.log &&
echo "Tailing '/var/log/crond.log'..." &&
tail -f /var/log/crond.log
