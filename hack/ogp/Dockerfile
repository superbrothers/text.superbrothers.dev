FROM docker.io/node:22-bookworm

ARG PAGERES_VERSION

RUN set -x && \
    npm install "pageres-cli@${PAGERES_VERSION}" serve --location=global

RUN set -x && \
    apt update && \
    apt install -y \
        bash \
        curl \
        chromium \
        fonts-noto-mono \
        fonts-noto-color-emoji \
        fonts-noto-cjk \
        fonts-hack

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

ENTRYPOINT []
