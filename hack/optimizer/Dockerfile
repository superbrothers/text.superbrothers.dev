FROM debian:bookworm-slim AS base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      imagemagick \
      webp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

FROM base AS optimizer
RUN --mount=type=bind,source=content,target=/input \
    --mount=type=bind,source=hack/optimizer/optimize-images.sh,target=/usr/local/bin/optimize-images.sh \
    cp -a /input /src/content && \
    optimize-images.sh /src/content

FROM scratch AS export
COPY --from=optimizer /src/content /content
