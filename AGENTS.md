# AGENTS.md

Roblox Lua scripts for the **Delta** executor (Android). No build, test, lint, or CI tooling exists — do not invent `npm`/`make`/`luacheck` steps. Verification is manual: paste/execute in the executor inside Roblox.

## Directory boundaries

- `Scripts/` — the only tracked source. All project code goes here.
- `Autoexecute/`, `Internals/`, `Workspace/` — Delta executor runtime dirs, **gitignored**. Never edit or commit them. `Internals/Secured/` contains anti-scam toggles; do not paste content there.
- `Scripts/GlobalSystemFiles/` — non-Lua project files (`Config.json`, `DocProjectGlobal.md`, `TODO.md`) placed here so Delta does not try to load them as scripts. Keep docs/config there, not loose in `Scripts/`.
- `.luaurc` and `.nomedia` are gitignored local files.
- **Delta UI gotcha:** a Delta update swapped the **Delete** and **Execute** buttons — double-check before any destructive action in the executor (this once wiped `GlobalControler.lua`).

## Architecture (authoritative: `Scripts/GlobalSystemFiles/DocProjectGlobal.md`)

- **GS = `Scripts/GlobalScripts/`** — logic only, no GUI.
- **GM = `Scripts/GlobalModules/`** — GUI only, no logic.
  Strict split; do not mix. UI strings and user-facing text are Russian (`Language: RU`).
- `Scripts/GlobalControler.lua` — single entrypoint, **runs first** and raises everything else (no manual module loading). It must: detect an already-running instance and exit early; discover modules; read each module's `GetTable` (which Home slot) and `GetPosition` (z-order); collision-check X/Y placement via `GC:ClaimPosition(w,h)` / `GC:ReleaseWindow`; then load settings from `GlobalSystemFiles/Config.json` (theme, language, window size, per-module settings, icon paths).
- Module contract (demo `V26.1.0R`): one table per file, `return` + `env[FileName]`; fields `GetTable` (tab: `Player`/`Server`/`Settings`), `GetPosition`, `Name`, `Desc`, `Open(config)`; `config = Config.modules[FileName]`, icon = `Config.icons[FileName]`. Startup shows only a 64×64 `[N]` launcher — the hub opens on click, ✕ hides it back. Clicking a module card opens it **inline in the hub** (no separate floating window); `←` returns to the card list. Embedded modules get **no WindowBase header** (hub header is the only one). Default tabs always: `Player | Server | Settings`. Optional quick-toggle on the card: `QuickToggle=true` + `IsOn()`/`SetOn(on)`/`Restore(config)` — state persists via `GC:SaveModuleState` → Config.json. Settings module uses `GC:SetLanguage`/`SetTheme`/`SetAccent`/`SetHubTransparency`. Full contract: end of `DocProjectGlobal.md`.
- Load order is GS first, then GM, with up to 5 retry passes (GM may `assert` on GS globals). Loader uses `readfile` + `loadstring`; falls back to a hardcoded file list if `listfiles` is unavailable.
- `Config.json` is the settings source of truth (currently `{}` — extend it rather than hardcoding settings).
- `TODO.md` is the shared human+AI task log — record ideas/tasks there.

## Code conventions (from shipped scripts in git history)

- Module idiom — idempotent global registration:
  ```lua
  local env = getgenv and getgenv() or _G
  if env.MyModule then return env.MyModule end
  -- ...
  env.MyModule = MyModule
  return MyModule
  ```
  Dependencies between modules are read from `env.X` (plus `assert` on missing ones).
- Roblox/executor APIs only: `game:GetService`, `task.spawn`/`task.wait`/`task.cancel` (never global `wait`), `Instance.new`, `pcall` around UI/anti-cheat-sensitive operations.
- Tabs for indentation.
- No test framework. The historical pattern is a diagnostic script (see `Test.lua` at `git show HEAD:Scripts/Test.lua`) that renders findings in an on-screen GUI — reuse that approach for runtime checks.

## Versioning & commits

- Version format: `year.release.patch` + stage letter — `R`elease / `P`re-release / `B`eta / `D`emo. Example: `26.1.5R`.
- Commit messages: Russian, prefixed with the version — `V26.0.1D: <что сделано>`.
- Branch: work on `main`; no PR/CI process exists.

## Read first

- `Scripts/GlobalSystemFiles/DocProjectGlobal.md` — project spec (overrides this file if they conflict).
- `Scripts/GlobalSystemFiles/TODO.md` — current tasks.
