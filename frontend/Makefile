.PHONY: build serve watch clean test

# Installed via ghcup (not the wasm32-wasi-cabal wrapper from the Nix flake,
# which isn't available on the ghcup-only path) — cabal 3.14 pinned because
# 3.16 has a known regression with the GHC wasm backend.
WASM_CABAL := ~/.ghcup/bin/cabal-3.14.2.0
CABAL_WASM_ARGS := --allow-newer=base,template-haskell --with-compiler=wasm32-wasi-ghc --with-hc-pkg=wasm32-wasi-ghc-pkg --with-hsc2hs=wasm32-wasi-hsc2hs --with-haddock=wasm32-wasi-haddock

# Recipes run in one shell so sourcing the wasm toolchain env sticks for the
# whole target, regardless of whether the calling shell (e.g. Tauri's
# beforeDevCommand) already has it on PATH.
.ONESHELL:
SHELL := /bin/bash

build:
	source ~/.ghcup/env
	source ~/.ghc-wasm/env
	$(WASM_CABAL) build $(CABAL_WASM_ARGS) app
	rm -rf public
	cp -r static public
	my_wasm=$$($(WASM_CABAL) list-bin $(CABAL_WASM_ARGS) app | tail -n 1)
	"$$(wasm32-wasi-ghc --print-libdir)/post-link.mjs" --input "$$my_wasm" --output public/ghc_wasm_jsffi.js
	cp -v "$$my_wasm" public/app.wasm

serve:
	bunx http-server public -p 8080 -c-1

watch:
	source ~/.ghcup/env
	source ~/.ghc-wasm/env
	ghciwatch --after-startup-ghci :main --after-reload-ghci :main --watch app --watch src --debounce 50ms --command '$(WASM_CABAL) repl $(CABAL_WASM_ARGS) app -finteractive --repl-options="-fghci-browser -fghci-browser-port=8080"'

test:
	source ~/.ghcup/env
	cabal test greet-spec

clean:
	rm -rf dist-newstyle public
