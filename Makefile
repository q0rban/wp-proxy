# Run "make help" to see a description of the targets in this Makefile.

# The destination image to push to.
export DESTINATION_DOCKER_IMAGE ?= someorg/someimage

## You probably don't need to modify any of the following.
# Today's date.
export DATE := $(shell date "+%Y-%m-%d")
# The directory to keep track of build steps.
export BUILD_DIR := build-${DATE}

.PHONY: all
all: push-image ## Run all the targets in this Makefile required to tag a new Docker image.

.PHONY: help
help: ## Print out the help for this Makefile.
	@printf '\n%s\n' '-----------------------'
	@$(MAKE) targets

# To add a target to the help, add a double comment (##) on the target line.
.PHONY: targets
targets: ## Print out the available make targets.
# 	# This was stolen and adapted from:
# 	# https://github.com/nodejs/node/blob/f05eaa4a537ed7ef57814d951d64c25ef2844720/Makefile#L73-L78.
	@printf "Available targets:\n\n"
	@grep -h -E '^[a-zA-Z0-9%._-]+:.*?## .*$$' Makefile 2>/dev/null | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@printf "\nFor more targets and info see the comments in the Makefile.\n"

.PHONY: push-image
push-image: tag ## Push the tagged images to the docker registry.
#	# Push the images.
	docker push ${DESTINATION_DOCKER_IMAGE}
#	# Clean up after ourselves.
	$(MAKE) clean

.PHONY: tag
tag: ${BUILD_DIR}/build-image ## Build and tag the image.
${BUILD_DIR}/build-image: ${BUILD_DIR}
#	# Build the Dockerfile in this directory.
	docker build -t $(DESTINATION_DOCKER_IMAGE):latest .
	@touch $(@)

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}
	@printf "Prepared build environment.\n"

clean: ## Clean up all locally tagged Docker images and build directories.
#	# Delete all image tags.
	-docker rmi $(DESTINATION_DOCKER_IMAGE):latest
#	# Remove the build dir.
	-rm -r ${BUILD_DIR}
