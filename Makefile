DOCKER_RUN := docker run --rm --init -v $(shell pwd):/src -w /src -u $(shell id -u):$(shell id -g)
HUGO_VERSION := 0.53
HUGO_IMAGE := jojomi/hugo:$(HUGO_VERSION)
HUGO := $(DOCKER_RUN) -p 8080:8080 $(HUGO_IMAGE) hugo

.PHONY: build
build:
		$(HUGO)

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
		echo -n "content/posts/$${yymmdd}-POST.md: "; \
		read post; \
		$(HUGO) new "content/posts/$${yymmdd}-$${post}.md"

.PHONY: run-in-hugo
run-in-hugo:
		$(DOCKER_RUN) -it $(HUGO_IMAGE) /bin/sh
