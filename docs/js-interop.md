# Interop JS / paquets npm graphiques depuis Miso (wasm32-wasi)

Ce guide documente comment intégrer une bibliothèque JS tierce (widget
graphique, éditeur, carte, etc.) dans le frontend Haskell/Miso de ce projet,
et pourquoi une classe entière de mécanismes Miso est à éviter sur notre
toolchain de compilation.

Exemple de référence : l'intégration de
[cm-chessboard](https://github.com/shaack/cm-chessboard) dans
`frontend/app/Main.hs` (branche `sample-chessboard`).

## Le piège : Template Haskell casse la compilation wasm32-wasi

Le build (`make build`, via `wasm32-wasi-ghc` / `wasm32-wasi-cabal`) échoue
avec une erreur du style :

```
Assertion failed: findSystemLibrary(libHSapp-0.1.0.0-inplace-greet-core.so): not found in ...
<no location info>: error:
GHC.ByteCode.Linker.lookupCE
During interactive linking, GHCi couldn't find the following symbol:
  closure:js
```

**Cause** : certains mécanismes de Miso reposent sur *Template Haskell*
(quasi-quotation ou génération de code). Même quand l'expansion ne fait que
construire un AST, GHC doit **exécuter le code compilé du générateur
pendant la compilation**, via son interpréteur bytecode interne (GHCi). Sur
la cible wasm32-wasi, cela nécessite que le linker dynamique (`dyld.mjs`)
charge les bibliothèques du projet (y compris les sous-librairies internes
comme `greet-core`) — et ce chargement échoue actuellement.

**Ce n'est donc pas un problème d'utiliser un paquet npm** — c'est un
problème avec trois modules Miso précis, tous marqués
`{-# LANGUAGE TemplateHaskellQuotes #-}` :

| Module | Fonctionnalité | À la place |
|---|---|---|
| `Miso.FFI.QQ` | quasi-quoteur `[js\| ... \|]` | `Miso.FFI.inline` / `Miso.DSL.eval` (fonctions normales) |
| `Miso.Lens.TH` | `makeLenses` | lenses écrites à la main (voir `name`/`greeting` dans `Main.hs`) |
| `Miso.String.QQ` | quasi-quoteur de strings | littéraux `MisoString` classiques (`OverloadedStrings`) |

**Ce qui fonctionne normalement**, car ce ne sont pas des mécanismes TH :

- Le DSL bas niveau `Miso.DSL` (`new`, `jsg`, `createWith`, `(#)`, `(!)`, `eval`)
- `Miso.FFI.inline` / `Miso.FFI.eval` — fonctions ordinaires, exécutées
  uniquement dans le navigateur au runtime
- `deriving (Generic)` + `deriving anyclass (ToJSVal, FromJSVal)` — repose
  sur `GHC.Generics`, un mécanisme distinct de TH, compilé normalement

## Recette générale pour intégrer un widget JS/npm

1. **Vendoriser le JS**, plutôt que de dépendre d'un bundler (le projet n'en
   a pas) :
   ```
   frontend/static/vendor/<paquet>/
     src/       (ou le build ESM du paquet)
     assets/    (CSS, sprites, etc.)
   ```
   Copier depuis `node_modules/<paquet>` après `bun add -d <paquet>` (garde
   la dépendance npm dans `package.json` pour tracer la version, même si le
   code Haskell ne passe jamais par `node_modules` à l'exécution).

2. **Exposer un global** depuis `frontend/static/index.js` (module ES déjà
   chargé par la page), puisqu'il n'y a pas de bundler côté Haskell :
   ```js
   import { MonWidget } from "./vendor/<paquet>/src/Entrée.js";
   window.MonWidget = MonWidget;
   ```

3. **Charger le CSS** du paquet via le champ `styles` du `Component` Miso
   (`Href`/`Style`), pas via un `<link>` statique dans `index.html` :
   ```haskell
   app = (component emptyModel updateModel viewModel)
     { styles = [ Href "/vendor/<paquet>/assets/style.css" False ] }
   ```

4. **Point de montage** : un élément avec `onCreated`/`onCreatedWith` pour
   déclencher l'initialisation une fois le nœud DOM réellement inséré :
   ```haskell
   H.div_ [ P.id_ "mon-widget", onCreated WidgetMounted ] []
   ```

5. **Instancier** via `inline` (jamais `[js\| \|]`) :
   ```haskell
   initWidget :: IO ()
   initWidget = do
     obj <- create
     inline widgetInitJS obj
     where
       widgetInitJS :: MisoString
       widgetInitJS = ms $ unlines
         [ "var el = document.getElementById(\"mon-widget\");"
         , "if (el && !el.dataset.mounted) {"
         , "  el.dataset.mounted = \"true\";"
         , "  new window.MonWidget(el, { /* options */ });"
         , "}"
         ]
   ```
   Le garde `dataset.mounted` évite une double instanciation si
   `onCreated` est redéclenché (rechargement à chaud, etc.).

6. **Remonter les événements JS → Haskell**, si le widget est interactif :
   utiliser `syncCallback`/`asyncCallback` (`Miso.DSL`) pour transformer un
   callback JS (`.on("event", cb)`) en `Sink action`, qui dispatch une
   `Action` Miso.

7. **Nettoyage** : si le composant peut être démonté dynamiquement, utiliser
   `onDestroyed` pour appeler `.destroy()` côté JS et éviter les fuites
   (listeners, observers, etc.).

## Voir aussi

- `frontend/app/Main.hs` — intégration complète de cm-chessboard suivant
  cette recette (affichage seul, sans coups interactifs pour l'instant).
- `frontend/static/index.js` — exposition du global `window.Chessboard`.
