DOCKER_RUN := docker run --rm --init -v $(shell pwd):/src -w /src -u "$(shell id -u)"
# renovate: datasource=docker depName=docker.io/klakegg/hugo
HUGO_VERSION ?= 0.101.0
HUGO_IMAGE := docker.io/klakegg/hugo:$(HUGO_VERSION)
HUGO ?= $(DOCKER_RUN) -e HUGO_ENV -p 8080:8080 $(HUGO_IMAGE) $(HUGO_OPTS)

.PHONY: build
build:
	$(HUGO) --minify

.PHONY: build-dev
build-dev:
	$(HUGO) -D

.PHONY: serve
serve:
	HUGO_ENV=production $(HUGO) server --bind=0.0.0.0 -p 8080 --minify

.PHONY: serve-dev
serve-dev:
	$(HUGO) server -D --bind=0.0.0.0 -p 8080

.PHONY: new-post
new-post:
	@HUGO="$(HUGO)" ./hack/new-post.sh

.PHONY: run-in-hugo
run-in-hugo:
	$(DOCKER_RUN) -it $(HUGO_IMAGE) /bin/sh

.PHONY: serve-without-watch
serve-without-watch:
	HUGO_ENV=production $(HUGO) server --bind=0.0.0.0 -p 8080 --minify --watch=false

PAGERES_VERSION ?= v6.0.1
.PHONY: generate-ogp-images
generate-ogp-images:
	DOCKER_BUILDKIT=1 docker build --build-arg HUGO_IMAGE=$(HUGO_IMAGE) --build-arg PAGERES_VERSION=$(subst v,,$(PAGERES_VERSION)) -t generate-ogp-images -f hack/Dockerfile .
	$(DOCKER_RUN) --cap-add=SYS_ADMIN -e HUGO=hugo generate-ogp-images ./hack/generate-ogp-images.sh
