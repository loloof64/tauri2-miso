# Tauri 2 + Miso project template

A Tauri 2, and Miso (haskell-like language + elm-like views) template.

## Prerequisites

- **Rust + platform webview deps** — follow the official [Tauri prerequisites guide](https://v2.tauri.app/start/prerequisites/) for your OS (Rust via [rustup](https://rustup.rs), plus WebView2 on Windows / webkit2gtk on Linux / Xcode on macOS).
- **[Bun](https://bun.sh)** — used to run the project scripts and the Tauri CLI.
- **GHC + Cabal (native)** — used to build and test the Haskell business logic in `frontend/` outside of the browser (`cabal test`). Install via [GHCup](https://www.haskell.org/ghcup/): GHC ≥ 9.10.1 (with TemplateHaskell support) and Cabal ≥ 3.15.
- **GHC WebAssembly backend (`wasm32-wasi`)** — cross-compiles the Miso frontend to the `.wasm` artifact actually loaded by the Tauri webview. Not installed by GHCup alone; bootstrap it via [`ghc-wasm-meta`](https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta) (ghcup-based, no Nix required):

  ```bash
  curl https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta/-/raw/master/bootstrap.sh | SKIP_GHC=1 sh
  source ~/.ghc-wasm/env
  ghcup config add-release-channel https://gitlab.haskell.org/haskell-wasm/ghc-wasm-meta/-/raw/master/ghcup-wasm-0.0.9.yaml
  ghcup install ghc --set wasm32-wasi-9.14 -- --host=x86_64-linux --target=wasm32-wasi --with-intree-gmp --with-system-libffi
  ```

  Also install a pinned Cabal for this cross-build specifically — Cabal 3.16 has a known regression with the GHC wasm backend:

  ```bash
  ghcup install cabal 3.14.2.0
  ```

  This step also pulls in Node.js, `wasi-sdk`, `wasmtime` and `binaryen` under `~/.ghc-wasm/` (used internally by the build, e.g. for Template Haskell support and `post-link.mjs`) — no need to install these separately. `frontend/Makefile` sources `~/.ghc-wasm/env` itself, so it doesn't need to already be on `PATH` in your shell.

  > [!NOTE]
  > On Windows, run the bootstrap inside **WSL** (e.g. `wsl -d Ubuntu-24.04`), not PowerShell or Git Bash — the script assumes a real Linux/macOS environment and fails partway through under MSYS (Git Bash). On a fresh Ubuntu WSL install, also install the packages the script shells out to before running it: `sudo apt-get install -y jq unzip zstd`.

- **Git** — required for Cabal to fetch Miso's source from its repository on first build.

> [!NOTE]
> The wasm toolchain bootstrap downloads several hundred MB and the GHC wasm backend itself is a few GB once installed; the very first `frontend` build (native or wasm) also compiles all Haskell dependencies from source, so expect it to take a while.

- install dependencies : `bun install`

- run Tauri in dev mode : `bun run tauri dev` or `bun run tauri android dev`

- Don't forget to run `bun run tauri android init` if you're targeting Android (`bun run tauri ios init` for IOS.)

### Building

- `bun run tauri build`
- `bun run tauri android build`

### Commit messages

This project uses [Husky](https://typicode.github.io/husky/) with a `commit-msg` hook to enforce the [Conventional Commits](https://www.conventionalcommits.org/) format: `<type>: <description>`.

Allowed types:

| Emoji | Type       | Description                                                        |
| ----- | ---------- | ------------------------------------------------------------------ |
| 🏗️    | `build`    | Changes to the build system or external dependencies               |
| 🧹    | `chore`    | Maintenance tasks that don't affect src or test files              |
| ⚙️    | `ci`       | Changes to CI configuration and scripts                            |
| 📚    | `docs`     | Documentation only changes                                         |
| ✨    | `feat`     | A new feature                                                      |
| 🐛    | `fix`      | A bug fix                                                          |
| ⚡    | `perf`     | A code change that improves performance                            |
| ♻️    | `refactor` | A code change that neither fixes a bug nor adds a feature          |
| ⏪    | `revert`   | Reverts a previous commit                                          |
| 💄    | `style`    | Changes that do not affect the meaning of the code (formatting, …) |
| ✅    | `test`     | Adding or correcting tests                                         |

Example: `feat: add dark mode toggle`
