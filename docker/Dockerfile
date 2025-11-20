FROM python:3-alpine

ENV STRATO_ACME_DIR=/strato-acme
ENV STRATO_ACME_INSTALL_DIR=${STRATO_ACME_DIR}/acme.sh
ENV STRATO_ACME_SCRIPTS_DIR=${STRATO_ACME_DIR}/scripts
ENV STRATO_ACME_CONFIG_DIR=${STRATO_ACME_DIR}/config
ENV STRATO_ACME_VENV_DIR=${STRATO_ACME_DIR}/.venv
ENV STRATO_ACME_LOGS_DIR=${STRATO_ACME_DIR}/logs
ENV STRATO_ACME_LOG_FILE=${STRATO_ACME_LOGS_DIR}/strato-acme.log
ENV STRATO_ACME_CERTS_DIR=${STRATO_ACME_DIR}/certs

ENV STRATO_API_CONFIG_FILE=${STRATO_ACME_CONFIG_DIR}/strato-acme-config.json
ENV STRATO_API_PYTHON=strato-dns-api

# Install dependencies needed for the acme client and scripts
RUN apk add --no-cache bash busybox-suid \
    && apk add --no-cache openrc \
    && apk add --no-cache cronie \
    && apk add --no-cache su-exec \
    && apk add --no-cache nano \
    && apk add --no-cache bash curl socat bind-tools openssl

# prepare directories
RUN mkdir -p ${STRATO_ACME_DIR} \
    && mkdir -p ${STRATO_ACME_LOGS_DIR} \
    && mkdir -p ${STRATO_ACME_SCRIPTS_DIR} \
    && mkdir -p ${STRATO_ACME_CONFIG_DIR} \
    && chmod -R 777 ${STRATO_ACME_LOGS_DIR} \
    && mkdir -p ${STRATO_ACME_CERTS_DIR}

# Install acme.sh
RUN curl https://get.acme.sh | sh -s -- home ${STRATO_ACME_INSTALL_DIR} --config-home ${STRATO_ACME_CONFIG_DIR} --cert-home ${STRATO_ACME_CERTS_DIR} --log ${STRATO_ACME_LOG_FILE} \
    && ln -s ${STRATO_ACME_INSTALL_DIR}/acme.sh /usr/local/bin/acme.sh

# copy necessary files
COPY src/scripts/*.sh ${STRATO_ACME_SCRIPTS_DIR}/
COPY src/acme_plugin/dns_strato.sh ${STRATO_ACME_INSTALL_DIR}/dnsapi/dns_strato.sh

RUN chmod +x ${STRATO_ACME_SCRIPTS_DIR}/*.sh \
    && ln -s ${STRATO_ACME_SCRIPTS_DIR}/create-new-wildcard-cert.sh /usr/local/bin/create-new-wildcard-cert.sh \
    && ls -laR ${STRATO_ACME_DIR} \
    && python3 -m venv ${STRATO_ACME_VENV_DIR} \
    && source ${STRATO_ACME_VENV_DIR}/bin/activate \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install ${STRATO_API_PYTHON} \
    && deactivate

ENTRYPOINT [ "sh", "-c", "${STRATO_ACME_SCRIPTS_DIR}/entrypoint.sh" ]
