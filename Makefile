# VERSION defines the project version for the bundle.
# Update this value when you upgrade the version of your project.
# To re-generate a bundle for another specific version without changing the standard setup, you can:
# - use the VERSION as arg of the bundle target (e.g make bundle VERSION=0.0.2)
# - use environment variables to overwrite this value (e.g export VERSION=0.0.2)
VERSION ?= latest

# CONTAINER_TOOL defines the container tool to be used for building images.
# Be aware that the target commands are only tested with Docker which is
# scaffolded by default. However, you might want to replace it to use other
# tools. (i.e. podman)
CONTAINER_TOOL ?= docker

# CONTAINER_REPO_OVERRIDE overrides the container registry repository to push images to.
CONTAINER_REPO_OVERRIDE ?= quay.io/${USER}

# Image URL to use all building/pushing image targets
# OverWritten due to previous logic and commented generated code
# IMG ?= controller:latest
IMG ?= $(CONTAINER_REPO_OVERRIDE)/oci-storage-initializer:$(VERSION)

# Remove directories and all files ignored by git.
.PHONY: clean
clean:
	rm -rf dist


# Remove directories and all files ignored by git.
.PHONY: clean-all
clean-all: clean
	git clean -Xfd .

##@ General


.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


##@ Development

.PHONY: install-deps
install-deps: ## Install poetry dependencies
	poetry install --no-root --no-interaction --no-cache

##@ Build

.PHONY: build
build: ## Build OCI storage wheel
	poetry build --no-interaction --no-cache


.PHONY: install
install: ## Install OCI storage project
	poetry install --no-interaction --no-cache


.PHONY: image-build
image-build: ## Build docker image with the manager.
	$(CONTAINER_TOOL) build -t ${IMG} .


.PHONY: image-push
image-push: ## Push docker image with the manager.
	$(CONTAINER_TOOL) push ${IMG}