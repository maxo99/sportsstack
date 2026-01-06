# SportsStack - Agent Guidelines

## Build & Test Commands
**Python (oddstracker/rotoreader):** `uv run pytest`, `uv run pytest path/to/test.py::Test::method`, `uv run ruff check`, `uv run ruff format`, `pylint src/`
**Go (go-sportsagent):** `make test`, `go test ./...`, `go test -v path/to/file_test.go`, `go test -v -run TestName ./...`
**Java (api-gateway/notification-service):** `mvn test`, `mvn test -Dtest=ClassName#methodName`

## Code Style
**Python:** line-length=100, type hints (3.10+ syntax), snake_case functions/vars, PascalCase classes, imports grouped (stdlib→third-party→local), minimal docstrings (disabled in linters)
**Go:** stdlib imports first then local, PascalCase exports/camelCase unexported, consistent `if err != nil` error handling
**Java:** Spring Boot conventions, PascalCase classes/camelCase methods, grouped imports, standard Spring annotations

## Copilot Rules
No comments unless requested. Commands for manual execution. Reusable commands in justfile.
Use 'bd' for task tracking

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
