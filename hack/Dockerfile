ARG HUGO_IMAGE

FROM $HUGO_IMAGE AS hugo-base

FROM docker.io/node:16

ARG PAGERES_VERSION

RUN set -x && \
    npm install "pageres-cli@${PAGERES_VERSION}" --location=global

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

COPY --from=hugo-base /usr/lib/hugo/hugo /bin/

ENTRYPOINT []
