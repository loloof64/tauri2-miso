# JS / npm UI package interop from Miso (wasm32-wasi)

This guide documents how to integrate a third-party JS library (graphical
widget, editor, map, etc.) into this project's Haskell/Miso frontend, and
why an entire class of Miso mechanisms must be avoided on our build
toolchain.

Reference example: the integration of
[cm-chessboard](https://github.com/shaack/cm-chessboard) in
`frontend/app/Main.hs` (branch `sample-chessboard`).

## The trap: Template Haskell breaks the wasm32-wasi build

The build (`make build`, via `wasm32-wasi-ghc` / `wasm32-wasi-cabal`) fails
with an error like:

```
Assertion failed: findSystemLibrary(libHSapp-0.1.0.0-inplace-greet-core.so): not found in ...
<no location info>: error:
GHC.ByteCode.Linker.lookupCE
During interactive linking, GHCi couldn't find the following symbol:
  closure:js
```

**Cause**: certain Miso mechanisms rely on *Template Haskell* (quasi-
quotation or code generation). Even when the expansion only builds an AST,
GHC must **execute the generator's compiled code during compilation**, via
its internal bytecode interpreter (GHCi). On the wasm32-wasi target, that
requires the dynamic linker (`dyld.mjs`) to load the project's libraries
(including internal sub-libraries like `greet-core`) — and that load
currently fails.

**So this is not a problem with using an npm package** — it's a problem
with three specific Miso modules, all marked
`{-# LANGUAGE TemplateHaskellQuotes #-}`:

| Module | Feature | Use instead |
|---|---|---|
| `Miso.FFI.QQ` | `[js\| ... \|]` quasi-quoter | `Miso.FFI.inline` / `Miso.DSL.eval` (plain functions) |
| `Miso.Lens.TH` | `makeLenses` | hand-written lenses (see `name`/`greeting` in `Main.hs`) |
| `Miso.String.QQ` | string quasi-quoter | plain `MisoString` literals (`OverloadedStrings`) |

**What works normally**, since these are not TH mechanisms:

- The low-level `Miso.DSL` (`new`, `jsg`, `createWith`, `(#)`, `(!)`, `eval`)
- `Miso.FFI.inline` / `Miso.FFI.eval` — plain functions, executed only in
  the browser at runtime
- `deriving (Generic)` + `deriving anyclass (ToJSVal, FromJSVal)` — relies
  on `GHC.Generics`, a mechanism distinct from TH, compiled normally

## General recipe for integrating a JS/npm widget

1. **Vendor the JS**, rather than depending on a bundler (the project
   doesn't have one):
   ```
   frontend/static/vendor/<package>/
     src/       (or the package's ESM build)
     assets/    (CSS, sprites, etc.)
   ```
   Copy from `node_modules/<package>` after `bun add -d <package>` (keep
   the npm dependency in `package.json` to track the version, even though
   the Haskell code never touches `node_modules` at runtime).

2. **Expose a global** from `frontend/static/index.js` (the ES module
   already loaded by the page), since there's no bundler on the Haskell
   side:
   ```js
   import { MyWidget } from "./vendor/<package>/src/Entry.js";
   window.MyWidget = MyWidget;
   ```

3. **Load the CSS** via the `styles` field of the Miso `Component`
   (`Href`/`Style`), not via a static `<link>` in `index.html`:
   ```haskell
   app = (component emptyModel updateModel viewModel)
     { styles = [ Href "/vendor/<package>/assets/style.css" False ] }
   ```

4. **Mount point**: an element with `onCreated`/`onCreatedWith` to trigger
   initialization once the DOM node actually exists:
   ```haskell
   H.div_ [ P.id_ "my-widget", onCreated WidgetMounted ] []
   ```

5. **Instantiate** via `inline` (never `[js\| \|]`):
   ```haskell
   initWidget :: IO ()
   initWidget = do
     obj <- create
     inline widgetInitJS obj
     where
       widgetInitJS :: MisoString
       widgetInitJS = ms $ unlines
         [ "var el = document.getElementById(\"my-widget\");"
         , "if (el && !el.dataset.mounted) {"
         , "  el.dataset.mounted = \"true\";"
         , "  new window.MyWidget(el, { /* options */ });"
         , "}"
         ]
   ```
   The `dataset.mounted` guard avoids double instantiation if `onCreated`
   fires again (hot reload, etc.).

6. **Forward JS events back to Haskell**, if the widget is interactive: use
   `syncCallback`/`asyncCallback` (`Miso.DSL`) to turn a JS callback
   (`.on("event", cb)`) into a `Sink action`, dispatching a Miso `Action`.

7. **Cleanup**: if the component can be unmounted dynamically, use
   `onDestroyed` to call `.destroy()` on the JS side and avoid leaks
   (listeners, observers, etc.).

## See also

- `frontend/app/Main.hs` — full cm-chessboard integration following this
  recipe (display only, no interactive moves yet).
- `frontend/static/index.js` — exposing the `window.Chessboard` global.
