FROM python:3-bookworm

ENV STRATO_ACME_DIR=/strato-acme
ENV STRATO_ACME_HOOKS_DIR=${STRATO_ACME_DIR}/hooks
ENV STRATO_ACME_SCRIPTS_DIR=${STRATO_ACME_DIR}/scripts
ENV STRATO_ACME_WORK_DIR=${STRATO_ACME_DIR}/work
ENV STRATO_ACME_VENV_DIR=${STRATO_ACME_WORK_DIR}/.venv
ENV STRATO_ACME_LOGS_DIR=${STRATO_ACME_DIR}/logs
ENV STRATO_ACME_LOG_FILE=${STRATO_ACME_LOGS_DIR}/strato-acme.log
ENV STRATO_CONFIG_DIR=${STRATO_ACME_DIR}/config

# Install dependencies needed for the acme client and scripts
RUN apt update && apt install -y curl cron nano bind9-dnsutils socat openssl

RUN curl https://get.acme.sh | sh -s -- home /opt/acme.sh \
    && ln -s /opt/acme.sh/acme.sh /usr/local/bin/acme.sh

COPY requirements*.txt /tmp
RUN cd /tmp && pip3 install -r /tmp/requirements-dev.txt