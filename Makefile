# Agilance — one entry point for local development and Docker.
#
#   make help        list targets
#   make up          run backend + frontend in Docker (hot reload)
#   make dev         run both directly on this machine (no Docker)
#
# Requires: docker compose v2 (for the Docker targets); Python 3.12 + Node 20
# with `uv` optional (for the local targets).

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Relative paths on purpose: the project lives in a folder with spaces in its
# name, so absolute paths would need quoting in every recipe.
BACKEND   := backend
FRONTEND  := frontend
COMPOSE   := docker compose
PROD      := $(COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml
PYTHON    ?= python3.12
VENV      := $(BACKEND)/.venv

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

.PHONY: up up-build up-voice up-localdb down restart logs logs-backend logs-frontend ps
up: check-env ## Start backend + frontend in Docker with hot reload
	$(COMPOSE) up

up-build: check-env ## Rebuild images, then start
	$(COMPOSE) up --build

up-voice: check-env ## Start backend + frontend + LiveKit voice agent
	$(COMPOSE) --profile voice up

up-localdb: check-env ## Start with a local Postgres instead of Supabase
	$(COMPOSE) --profile localdb up

down: ## Stop and remove containers (keeps volumes)
	$(COMPOSE) --profile voice --profile localdb down

restart: down up ## Restart the dev stack

logs: ## Tail all logs
	$(COMPOSE) logs -f

logs-backend: ## Tail backend logs
	$(COMPOSE) logs -f backend

logs-frontend: ## Tail frontend logs
	$(COMPOSE) logs -f frontend

ps: ## Show running services
	$(COMPOSE) ps

.PHONY: prod-build prod-up prod-down
prod-build: check-env ## Build production images
	$(PROD) build

prod-up: check-env ## Run production images detached
	$(PROD) up --build -d

prod-down: ## Stop production stack
	$(PROD) down

.PHONY: shell-backend shell-frontend
shell-backend: ## Open a shell in the backend container
	$(COMPOSE) exec backend sh

shell-frontend: ## Open a shell in the frontend container
	$(COMPOSE) exec frontend sh

# ---------------------------------------------------------------------------
# Local (no Docker)
# ---------------------------------------------------------------------------

.PHONY: install install-backend install-frontend
install: install-backend install-frontend ## Install backend venv + frontend node_modules

install-backend: ## Create backend/.venv (Python 3.12) and install requirements
	@if command -v uv >/dev/null 2>&1; then \
	  uv venv --python 3.12 "$(VENV)" && uv pip install --python "$(VENV)/bin/python" -r "$(BACKEND)/requirements.txt"; \
	else \
	  $(PYTHON) -m venv "$(VENV)" && "$(VENV)/bin/pip" install -r "$(BACKEND)/requirements.txt"; \
	fi

install-frontend: ## npm install in frontend/
	cd "$(FRONTEND)" && npm install

.PHONY: backend frontend agent dev
backend: ## Run FastAPI locally with reload on :8000
	cd "$(BACKEND)" && .venv/bin/uvicorn main:app --reload --port 8000

frontend: ## Run Next.js dev server locally on :3000
	cd "$(FRONTEND)" && npx next dev --port 3000

agent: ## Run the LiveKit voice agent locally
	cd "$(BACKEND)" && .venv/bin/python agent.py dev

dev: check-env ## Run backend + frontend locally in one terminal (Ctrl-C stops both)
	@trap 'kill 0' EXIT INT TERM; \
	( cd "$(BACKEND)" && .venv/bin/uvicorn main:app --reload --port 8000 2>&1 | sed 's/^/[backend] /' ) & \
	( cd "$(FRONTEND)" && npx next dev --port 3000 2>&1 | sed 's/^/[frontend] /' ) & \
	wait

# ---------------------------------------------------------------------------
# Quality
# ---------------------------------------------------------------------------

.PHONY: test test-pathways typecheck lint check
test: test-pathways ## Run all tests

test-pathways: ## Unit-test the clinical pathway engine (stdlib only)
	cd "$(BACKEND)" && python3 -m unittest pathways.tests.test_engine -v

typecheck: ## Type-check the frontend
	cd "$(FRONTEND)" && npx tsc --noEmit -p tsconfig.json

lint: ## Lint the frontend
	cd "$(FRONTEND)" && npx next lint

check: test typecheck lint ## Tests + typecheck + lint

# ---------------------------------------------------------------------------
# Housekeeping
# ---------------------------------------------------------------------------

.PHONY: check-env clean clean-docker
check-env: ## Verify the env files that hold secrets exist
	@[ -f "$(BACKEND)/.env" ] || { echo "✗ backend/.env is missing (needs SUPABASE_DATABASE_URL, OPENAI_API_KEY, LIVEKIT_*)"; exit 1; }
	@[ -f "$(FRONTEND)/.env.local" ] || echo "! frontend/.env.local not found — using compose defaults (no Prisma DATABASE_URL, no NextAuth secret)"

clean: ## Remove build artefacts (keeps node_modules and .venv)
	rm -rf "$(FRONTEND)/.next" "$(BACKEND)/__pycache__" "$(BACKEND)/pathways/__pycache__" "$(BACKEND)"/pathways/*/__pycache__

clean-docker: ## Stop stack and delete its volumes (node_modules cache, .next, local DB data)
	$(COMPOSE) --profile voice --profile localdb down -v

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
