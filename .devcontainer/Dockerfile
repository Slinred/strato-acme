FROM alpine AS downloader

ARG UV_VERSION=0.10.0
ARG JUST_VERSION=1.46.0
ARG STARSHIP_VERSION=1.24.2
ARG PYTHON_VERSION=3.14

RUN apk add --no-cache curl unzip tar \
    && rm -rf /var/cache/apk/*

# uv
RUN curl -LsSf https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz -o uv.tar.gz \
    && tar -xzf uv.tar.gz -C /usr/local/bin --strip-components=1 \
    && rm uv.tar.gz

# just
RUN curl -LsSf https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz -o just.tar.gz \
    && tar -xzf just.tar.gz -C /usr/local/bin \
    && rm just.tar.gz

# starship
RUN curl -LsSf https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz -o starship.tar.gz \
    && tar -xzf starship.tar.gz -C /usr/local/bin  \
    && curl -LsSf https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/RobotoMono.zip -o RobotoMono.zip \
    && mkdir -p /usr/share/fonts/truetype \
    && unzip RobotoMono.zip -d /tmp/RobotoMono \
    && rm -f RobotoMono.zip starship.tar.gz

#########################################################################################

FROM debian:bookworm-slim AS dev

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG USER_NAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV USER_HOME=/home/$USER_NAME
ENV VENV_PATH=${USER_HOME}/acme-strato-py

COPY --from=downloader /usr/local/bin/uv /usr/local/bin/just /usr/local/bin/starship /usr/local/bin/

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
