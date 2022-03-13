ifneq (,)
.error This Makefile requires GNU Make.
endif

# Ensure additional Makefiles are present
MAKEFILES = Makefile.docker Makefile.lint
$(MAKEFILES): URL=https://raw.githubusercontent.com/devilbox/makefiles/master/$(@)
$(MAKEFILES):
	@if ! (curl --fail -sS -o $(@) $(URL) || wget -O $(@) $(URL)); then \
		echo "Error, curl or wget required."; \
		echo "Exiting."; \
		false; \
	fi
include $(MAKEFILES)

# Set default Target
.DEFAULT_GOAL := help


# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
# Own vars
TAG        = latest

# Makefile.docker overwrites
NAME       = Bind
VERSION    = latest
IMAGE      = cytopia/bind
DIR        = .
FILE       = Dockerfile
DOCKER_TAG = $(TAG)
ARCH       = linux/amd64

# Makefile.lint overwrites
FL_IGNORES  = .git/,.github/
SC_IGNORES  = .git/,.github/,tests/


# -------------------------------------------------------------------------------------------------
#  Default Target
# -------------------------------------------------------------------------------------------------
.PHONY: help
help:
	@echo "lint                                     Lint project files and repository"
	@echo
	@echo "build [ARCH=...] [TAG=...]               Build Docker image"
	@echo "rebuild [ARCH=...] [TAG=...]             Build Docker image without cache"
	@echo "push [ARCH=...] [TAG=...]                Push Docker image to Docker hub"
	@echo
	@echo "manifest-create [ARCHES=...] [TAG=...]   Create multi-arch manifest"
	@echo "manifest-push [TAG=...]                  Push multi-arch manifest"
	@echo
	@echo "test [ARCH=...]                          Test built Docker image"
	@echo


# -------------------------------------------------------------------------------------------------
#  Docker Targets
# -------------------------------------------------------------------------------------------------
.PHONY: build
build: docker-arch-build

.PHONY: rebuild
rebuild: docker-arch-rebuild

.PHONY: push
push: docker-arch-push


# -------------------------------------------------------------------------------------------------
#  Manifest Targets
# -------------------------------------------------------------------------------------------------
.PHONY: manifest-create
manifest-create: docker-manifest-create

.PHONY: manifest-push
manifest-push: docker-manifest-push


# -------------------------------------------------------------------------------------------------
#  Test Targets
# -------------------------------------------------------------------------------------------------
.PHONY: test
test: _test-integration
test: update-readme

.PHONY: _test-integration
_test-integration:
	./tests/start-ci.sh $(IMAGE) $(NAME) $(VERSION) $(DOCKER_TAG) $(ARCH)

.PHONY: update-readme
update-readme:
	cat "./README.md" \
		| perl -0 -pe "s/<!-- modules -->.*<!-- \/modules -->/<!-- modules -->\n$$(./tests/get-modules.sh $(IMAGE) $(NAME) $(VERSION) $(DOCKER_TAG) $(ARCH))\n<!-- \/modules -->/s" \
		> "./README.md.tmp"
	yes | mv -f "./README.md.tmp" "./README.md"
	git diff --quiet || { echo "Build Changes"; git diff; git status; false; }
