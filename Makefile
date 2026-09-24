DOCKER_RUN := docker run --rm --init -v $(shell pwd):/src -w /src -u "$(shell id -u):$(shell id -g)"
# renovate: datasource=github-releases depName=gohugoio/hugo
HUGO_VERSION ?= 0.166.0
HUGO_IMAGE ?= ghcr.io/gohugoio/hugo:v$(HUGO_VERSION)
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
	$(DOCKER_RUN) -it --entrypoint /bin/sh $(HUGO_IMAGE)

.PHONY: serve-without-watch
serve-without-watch:
	HUGO_ENV=production $(HUGO) server --bind=0.0.0.0 -p 8080 --minify --watch=false

# renovate: datasource=npm depName=pageres-cli
PAGERES_VERSION ?= v9.0.0
.PHONY: generate-ogp-images
generate-ogp-images: build
	DOCKER_BUILDKIT=1 docker build --build-arg PAGERES_VERSION=$(subst v,,$(PAGERES_VERSION)) -t generate-ogp-images -f hack/ogp/Dockerfile .
	$(DOCKER_RUN) --cap-add=SYS_ADMIN generate-ogp-images ./hack/ogp/generate-ogp-images.sh

.PHONY: optimize-images
optimize-images:
	DOCKER_BUILDKIT=1 docker build --target export --output . -f hack/optimizer/Dockerfile .
	@find content -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.tiff" -o -name "*.bmp" \) \
		-exec bash -c 'for f; do [[ -f "$${f%.*}.webp" ]] && rm -f "$$f" && echo "Removed original: $$f"; done' _ {} +

