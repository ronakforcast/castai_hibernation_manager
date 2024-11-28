default: release

PLATFORMS = linux/amd64,linux/arm64
APP="castai/central_hibernate_manager"
TAG_LATEST=$(APP):latest
TAG_VERSION=$(APP):v0.1


multiarch:
	@echo "==> Building hibernate container"
	docker buildx create --use
	docker buildx build  --platform $(PLATFORMS)  -t $(TAG_VERSION)  -t $(TAG_LATEST) --push .

