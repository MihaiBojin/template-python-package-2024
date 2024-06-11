SHELL := /bin/bash
PROJECT_NAME := template_python_package_2024

.PHONY: clean
clean: clean-venv
	@echo Cleaning up builds and caches...
	@rm -rf {out,dist,build,.mypy_cache,.ruff_cache}
	@find . -type d -path ./venv -prune -o -name ".pytest_cache" -exec rm -rf {} \;
	@find . -type d -path ./venv -prune -o -name "__pycache__" -exec rm -rf {} \;
	@find . -type d -path ./venv -prune -o -name "*.egg-info" -exec rm -rf {} \;

.PHONY: clean-venv
clean-venv:
	@echo "Deleting virtualenv..."
	@scripts/delete-venv.bash

.PHONY: create-venv
create-venv:
	@echo "Creating virtualenv..."
	@scripts/create-venv.bash

.PHONY: venv
venv:
	@echo "source venv/bin/activate"

.PHONY: install
install:
	@echo "Installing all dependencies and editable package..."
	@scripts/uninstall-package.bash
	@pip install -e .[cli,dev]

.PHONY: build
build:
	@echo Cleaning up previous builds...
	@rm -rf dist/
	@echo "Building..."
	@pip install '.[dev]'
	@python -m build

.PHONY: build-inspect
build-inspect:
	@echo
	@echo "Inspecting wheel..."
	@wheel2json dist/$(PROJECT_NAME)-$(shell cat VERSION)-py3-none-any.whl

	@echo
	@echo "Inspecting archive..."
	@tar -tf dist/$(PROJECT_NAME)-$(shell cat VERSION).tar.gz

.PHONY: test
test:
	@echo "Running tests..."
	@pytest tests

.PHONY: pre-commit
pre-commit:
	@echo "Running pre-commit hooks..."
	@pre-commit run --all-files

.PHONY: publish-test
publish-test: build
	@echo "Publishing to test repo..."
	@TWINE_PASSWORD=$(TESTPYPI_PASSWORD) twine upload --repository-url https://test.pypi.org/legacy/ dist/\*

.PHONY: publish-test-verify
publish-test-verify:
	@echo "Verifying test.PyPI package..."
	@scripts/verify-publish.bash --test

.PHONY: publish
publish: build
	@echo "Publishing to PyPI..."
	@TWINE_PASSWORD=$(PYPI_PASSWORD) twine upload dist/\*

.PHONY: publish-verify
publish-verify:
	@echo "Verifying PyPI package..."
	@scripts/verify-publish.bash --prod
