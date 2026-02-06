# <Project Name> Agent Instructions

> Project overrides for the global `AGENTS.md`. This project is modular and optimised for rapid iteration.

## 1) Context
**Purpose:** [1-2 sentences]
**Target:** STM32 [family/part], board [name]
**Stack:** CubeMX + [CubeIDE/GCC ARM/CMake/Make], C++[20/23], [Go/Python tools]

## 1.5) Context Loading (Files to read on init)
List every file the agent must read before starting work. Be explicit.
- `AGENTS.md` / `CLAUDE.md` (this project's instructions)
- `README.md`
- `<path to .ioc file>` (CubeMX source of truth)
- `<path to protocol definitions / DBC / schema files>`
- `<path to Makefile or primary build entry point>`
- `<path to CI config>`
- `<any other critical context files>`

## 2) Clarify-First (Stop and ask before proceeding)
Ask the user before changes that involve:
- clock tree / power modes / RCC
- linker script / memory layout / sections
- bootloader/DFU/OTA/flash erase/write routines
- interrupt priorities, DMA setup, timing-critical paths
- protocol changes that affect compatibility

If acceptance criteria are unclear, propose 2 options with trade-offs.

## 3) CubeMX Rules (Non-negotiable)
- If a project has a `hal.c` file, this replaces generated `main.c` to allow a
  `main.cpp` entrypoint. Generated references should point to this replacement rather
  than `hal.c/.h`.
- Treat generated code as **read-only**.
- Only modify within approved extension points: [USER CODE blocks / wrappers in `<path>`].
- Source of truth: `<project>.ioc`
- Regeneration should always be done by the user. Provide clear reasoning when this
  should be done.
- After regen: review `git diff` and ensure only expected files changed.

## 4) Repo Map (Where to edit)
- App code (C++): `<path>`
- HAL wrappers/adapters: `<path>`
- CubeMX generated: `<path>`
- Protocol defs: `<path>`
- Tooling (Go): `<path>`
- Tooling (Python): `<path>`
- Build entrypoint: `<path>` (Makefile/CMake/etc.)

## 5) Build / Flash / Run (Copy-paste)
```bash
# Build
<exact command>

# Flash (confirm board/debugger first)
<exact command>

# Serial monitor
<exact command>
```

## 6) Verification (Realistic)

- Go (if applicable):

```bash
go test ./...
go vet ./...
```

- Firmware: build must succeed.
- If no tests cover the change: record a manual smoke check (what you did + observed output).

## 7) Never

- Don't commit secrets.
- Don't disable safety checks/watchdogs to "fix" behaviour.
- Don't hand-edit CubeMX output outside approved extension points.
