SHELL := /bin/bash

# These targets are thin wrappers over uv, kept for muscle memory.
# Everything they do can be done by calling uv directly.

.PHONY: venv
venv:
	@echo "source .venv/bin/activate"

.PHONY: clean
clean: clean-venv
	@echo Cleaning up builds and caches...
	@rm -rf {out,dist,build,.mypy_cache,.ruff_cache}
	@find . -type d -path ./.venv -prune -o -name ".pytest_cache" -exec rm -rf {} \;
	@find . -type d -path ./.venv -prune -o -name "__pycache__" -exec rm -rf {} \;
	@find . -type d -path ./.venv -prune -o -name "*.egg-info" -exec rm -rf {} \;

.PHONY: clean-venv
clean-venv:
	@echo "Deleting virtualenv..."
	@rm -rf .venv

.PHONY: create-venv
create-venv:
	@echo "Creating virtualenv..."
	@uv venv

.PHONY: install
install:
	@echo "Syncing the environment..."
	@uv sync --all-extras

.PHONY: setup
setup: install
	@echo "Setting up repo for local development..."
	@uv run pre-commit install --install-hooks
	@touch .env

.PHONY: lint
lint:
	@echo "Running pre-commit hooks..."
	@uv run pre-commit run --all-files

.PHONY: test
test:
	@echo "Running tests..."
	@uv run pytest tests

.PHONY: build
build:
	@echo Cleaning up previous builds...
	@rm -rf dist/
	@echo "Building..."
	@uv build

.PHONY: build-inspect
build-inspect: PROJECT_NAME = $(shell scripts/project-name.bash)
build-inspect:
	@echo
	@echo "Inspecting wheel..."
	@uv run wheel2json dist/$(PROJECT_NAME)-$(shell cat VERSION)-py3-none-any.whl

	@echo
	@echo "Inspecting archive..."
	@tar -tf dist/$(PROJECT_NAME)-$(shell cat VERSION).tar.gz

.PHONY: docker
docker:
	@echo
	@echo "Building Dockerfile..."
	@scripts/build-docker-image.bash

.PHONY: docker-run
docker-run:
	@echo
	@echo "Running Docker image..."
	@scripts/run-docker-image.bash $(ARGS)

.PHONY: publish-test
publish-test: build
	@echo "Publishing to test repo..."
	@uv publish --index testpypi

.PHONY: publish-test-verify
publish-test-verify:
	@echo "Verifying test.PyPI package..."
	@scripts/verify-publish.bash --test

.PHONY: publish
publish: build
	@echo "Publishing to PyPI..."
	@uv publish

.PHONY: publish-verify
publish-verify:
	@echo "Verifying PyPI package..."
	@scripts/verify-publish.bash --prod
