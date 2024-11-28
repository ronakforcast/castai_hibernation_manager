# Variables
PLATFORMS = linux/amd64,linux/arm64
APP = castai/central_hibernate_manager
TAG_LATEST = $(APP):latest
TAG_VERSION = $(APP):v0.1

# Enable BuildKit
export DOCKER_BUILDKIT = 1

# Default target
default: release

# Build the Docker image for multiple architectures
multiarch:
	@echo "==> Building hibernate container"
	# Check if the multiarch builder already exists, if not, create one
	@if ! docker buildx inspect multiarch-builder &>/dev/null; then \
		echo "No buildx builder found, creating one..."; \
		docker buildx create --use --name multiarch-builder; \
	else \
		echo "Using existing buildx builder..."; \
	fi
	docker buildx inspect multiarch-builder --bootstrap
	docker buildx build \
		--platform $(PLATFORMS) \
		-t $(TAG_VERSION) \
		-t $(TAG_LATEST) \
		--push \
		.

# Push the Docker image to Docker Hub
push:
	@echo "Image pushed to Docker Hub: $(TAG_VERSION), $(TAG_LATEST)"

# Clean up the buildx builder
clean:
	-docker buildx rm multiarch-builder || true