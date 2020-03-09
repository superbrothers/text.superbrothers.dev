DOCKER_RUN := docker run --rm --init -v $(shell pwd):/src -w /src -u $(shell id -u):$(shell id -g)
HUGO_VERSION := 0.66.0
HUGO_IMAGE := klakegg/hugo:$(HUGO_VERSION)
HUGO ?= $(DOCKER_RUN) -p 8080:8080 $(HUGO_IMAGE)

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
		@yymmdd="$$(date +%y%m%d)"; \
		echo -n "content/$${yymmdd}-POST.md: "; \
		read post; \
		$(HUGO) new "$${yymmdd}-$${post}.md"

.PHONY: run-in-hugo
run-in-hugo:
		$(DOCKER_RUN) -it $(HUGO_IMAGE) /bin/sh
