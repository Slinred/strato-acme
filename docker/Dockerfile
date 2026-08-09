FROM alpine:3.24 AS base

ARG PYTHON_VERSION=3.14

ENV STRATO_ACME_DIR=/strato-acme
ENV STRATO_ACME_INSTALL_DIR=${STRATO_ACME_DIR}/acme.sh
ENV STRATO_ACME_SCRIPTS_DIR=${STRATO_ACME_DIR}/scripts
ENV STRATO_ACME_CONFIG_DIR=${STRATO_ACME_DIR}/config
ENV STRATO_ACME_VENV_DIR=${STRATO_ACME_DIR}/.venv
ENV STRATO_ACME_LOGS_DIR=${STRATO_ACME_DIR}/logs
ENV STRATO_ACME_LOG_FILE=${STRATO_ACME_LOGS_DIR}/strato-acme.log
ENV STRATO_ACME_CERTS_DIR=${STRATO_ACME_DIR}/certs

ENV STRATO_API_CONFIG_FILE=${STRATO_ACME_CONFIG_DIR}/strato-acme-config.json

# Install dependencies needed for the acme client and scripts
RUN apk add --no-cache bash busybox-suid \
    && apk add --no-cache openrc \
    && apk add --no-cache cronie \
    && apk add --no-cache su-exec \
    && apk add --no-cache python3 \
    && apk add --no-cache nano \
    && apk add --no-cache bash curl socat bind-tools openssl

# UV
COPY --from=ghcr.io/astral-sh/uv:alpine3.23 /usr/local/bin/uv /usr/local/bin/uv

# prepare directories
RUN mkdir -p ${STRATO_ACME_DIR} \
    && mkdir -p ${STRATO_ACME_LOGS_DIR} \
    && mkdir -p ${STRATO_ACME_SCRIPTS_DIR} \
    && mkdir -p ${STRATO_ACME_CONFIG_DIR} \
    && chmod -R 777 ${STRATO_ACME_LOGS_DIR} \
    && mkdir -p ${STRATO_ACME_CERTS_DIR}

# Install acme.sh
RUN curl https://get.acme.sh | sh -s -- home ${STRATO_ACME_INSTALL_DIR} --config-home ${STRATO_ACME_CONFIG_DIR} --cert-home ${STRATO_ACME_CERTS_DIR} --log ${STRATO_ACME_LOG_FILE} \
    && ln -s ${STRATO_ACME_INSTALL_DIR}/acme.sh /usr/local/bin/acme.sh \
    # Uninstall the default cron job created by acme.sh installation, as we will use a custom wrapper script to ensure correct environment and path handling
    && acme.sh --uninstall-cronjob

# Copy the complete project and install the strato python API
COPY . /tmp/strato-dns-api
RUN cd /tmp/strato-dns-api \
    && uv python install --compile-bytecode --no-cache -i /usr/local/bin ${PYTHON_VERSION} \
    && uv venv --clear .venv \
    && source .venv/bin/activate \
    && uv sync --compile-bytecode --no-dev --no-cache \
    && uv build --wheel --no-cache \
    && deactivate \
    # Now install the wheel in the final location to ensure correct installation and path handling
    && uv venv --prompt strato-acme-py --clear ${STRATO_ACME_VENV_DIR} \
    && source ${STRATO_ACME_VENV_DIR}/bin/activate \
    && uv pip install --no-cache --find-links dist strato_dns_api \
    && deactivate \
    && rm -rf /tmp/strato-dns-api

# Setup entrypoint and scripts
COPY src/scripts/*.sh ${STRATO_ACME_SCRIPTS_DIR}/
COPY src/acme_plugin/dns_strato.sh ${STRATO_ACME_INSTALL_DIR}/dnsapi/dns_strato.sh
RUN chmod +x ${STRATO_ACME_SCRIPTS_DIR}/*.sh \
    && ln -s ${STRATO_ACME_SCRIPTS_DIR}/create-new-wildcard-cert.sh /usr/local/bin/create-new-wildcard-cert.sh \
    && ls -laR ${STRATO_ACME_DIR}

ENTRYPOINT [ "/bin/bash", "-c", "${STRATO_ACME_SCRIPTS_DIR}/entrypoint.sh" ]
