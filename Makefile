DOCKER_RUN := docker run --rm --init -v $(shell pwd):/src -w /src
HUGO_VERSION := 0.66.0
HUGO_IMAGE := klakegg/hugo:$(HUGO_VERSION)
HUGO ?= $(DOCKER_RUN) -p 8080:8080 $(HUGO_IMAGE) $(HUGO_OPTS)

.PHONY: build
build:
		$(HUGO)

.PHONY: build-dev
build-dev:
		$(HUGO) -D

.PHONY: serve
serve:
		$(HUGO) server --bind=0.0.0.0 -p 8080

.PHONY: serve-dev
serve-dev:
		$(HUGO) server -D --bind=0.0.0.0 -p 8080

.PHONY: new-post
new-post:
		@HUGO="$(HOGO)" ./hack/new-post.sh

.PHONY: run-in-hugo
run-in-hugo:
		$(DOCKER_RUN) -it $(HUGO_IMAGE) /bin/sh
