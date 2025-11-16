VIRTUAL_ENV := ".venv"
PYTHON_VERSION := "3.10"
PYTHON_VERSION_FILE := ".python-version"

default:
    @just --list

help:
    @echo "Available commands:"
    @echo "  install    - Install dependencies"
    @echo "  reinstall  - Reinstall dependencies"
    @echo "  lint       - Run pre-commit"
    @echo "  test       - Run tests"
    @echo "  clean      - Clean temporary files"

_create-venv:
    #!/usr/bin/env bash
    if [ ! -d "{{VIRTUAL_ENV}}" ]; then
        uv venv
    fi

_setup-python: _create-venv
    #!/usr/bin/env bash
    if [ ! -f "{{PYTHON_VERSION_FILE}}" ]; then
        uv python install {{PYTHON_VERSION}}
        uv python pin {{PYTHON_VERSION}}
    fi

_install-deps: _setup-python
    #!/usr/bin/env bash
    if [ ! -f ".deps" ] || [ "pyproject.toml" -nt ".deps" ]; then
        uv sync --all-extras --dev
        uv tool install pre-commit
        uv run pre-commit install
        uv run pre-commit install-hooks
        touch .deps
    fi

install: _install-deps
    @printf "\nSetup complete! To activate the virtual environment, run:\n\n    source {{VIRTUAL_ENV}}/bin/activate\n"

reinstall: clean install

lint:
    uv run pre-commit run --all-files

test:
    #!/usr/bin/env bash
    rm -rf coverage
    uv run coverage run --source=. -m pytest -v -p no:warnings .
    uv run coverage combine
    uv run coverage report --fail-under=100

clean:
    rm -rf {{VIRTUAL_ENV}} .pytest_cache .ruff_cache .coverage coverage dist *.egg-info .deps {{PYTHON_VERSION_FILE}} uv.lock
    find . -type d -name __pycache__ -exec rm -rf {} +
    find . -type f -name "*.pyc" -delete

re: clean install
