-----------------------------------------------------------------------------
{-# LANGUAGE CPP               #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
module Main where
-----------------------------------------------------------------------------
import           Miso
import           Miso.Html.Element as H
import           Miso.Html.Event as E
import           Miso.Html.Property as P
import           Miso.Lens
import           Miso.String (fromMisoString, ms)
-----------------------------------------------------------------------------
import           Greet (greet)
-----------------------------------------------------------------------------
data Model = Model
  { _name     :: MisoString
  , _greeting :: MisoString
  } deriving (Show, Eq)
-----------------------------------------------------------------------------
name :: Lens Model MisoString
name = lens _name $ \m x -> m { _name = x }
-----------------------------------------------------------------------------
greeting :: Lens Model MisoString
greeting = lens _greeting $ \m x -> m { _greeting = x }
-----------------------------------------------------------------------------
data Action
  = NameChanged MisoString
  | Greet
  | ChessboardMounted
  deriving (Show, Eq)
-----------------------------------------------------------------------------
#ifdef WASM
#ifndef INTERACTIVE
foreign export javascript "hs_start" main :: IO ()
#endif
#endif
-----------------------------------------------------------------------------
main :: IO ()
#ifdef INTERACTIVE
main = reload defaultEvents app
#else
main = startApp defaultEvents app
#endif
-----------------------------------------------------------------------------
emptyModel :: Model
emptyModel = Model { _name = "", _greeting = "" }
-----------------------------------------------------------------------------
app :: App Model Action
app = (component emptyModel updateModel viewModel)
  { styles =
    [ Href "/vendor/cm-chessboard/assets/chessboard.css" False
    , Style "#chessboard { width: 400px; margin: 1rem auto; }"
    ]
  }
-----------------------------------------------------------------------------
updateModel :: Action -> Effect parent props Model Action
updateModel = \case
  NameChanged n ->
    name .= n
  Greet -> do
    n <- use name
    greeting .= ms (greet (fromMisoString n))
  ChessboardMounted ->
    io_ initChessboard
-----------------------------------------------------------------------------
-- | Instantiates a cm-chessboard <https://github.com/shaack/cm-chessboard>
-- widget inside the @#chessboard@ container once it exists in the DOM.
-- The npm package is vendored (unbundled ES module) under
-- @frontend/static/vendor/cm-chessboard@ and registered as
-- @window.Chessboard@ from @frontend/static/index.js@.
--
-- Uses 'inline' (a plain runtime call) rather than the @[js| |]@
-- quasi-quoter: quasi-quotation runs via GHC's interactive interpreter at
-- compile time, which currently fails to dynamically link this project's
-- wasm32-wasi build (in-package sub-library lookup for @greet-core@ is
-- broken in the wasm dyld). 'inline' only executes in the browser at
-- runtime, so it sidesteps that entirely.
initChessboard :: IO ()
initChessboard = do
  obj <- create
  inline chessboardInitJS obj
  where
    chessboardInitJS :: MisoString
    chessboardInitJS = ms $ unlines
      [ "var container = document.getElementById(\"chessboard\");"
      , "if (container && !container.dataset.chessboardMounted) {"
      , "  container.dataset.chessboardMounted = \"true\";"
      , "  new window.Chessboard(container, {"
      , "    position: \"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1\","
      , "    assetsUrl: \"/vendor/cm-chessboard/assets/\""
      , "  });"
      , "}"
      ]
-----------------------------------------------------------------------------
viewModel :: props -> Model -> View Model Action
viewModel _ m = H.main_
  [ P.class_ "container" ]
  [ H.h1_ [] [ "Welcome to Tauri + Miso" ]
  , H.form_
    [ E.onSubmit Greet ]
    [ H.input_
      [ P.id_ "greet-input"
      , P.placeholder_ "Enter a name..."
      , E.onInput NameChanged
      ]
    , H.button_ [ P.type_ "submit" ] [ "Greet" ]
    ]
  , H.p_ [] [ text (m ^. greeting) ]
  , H.div_ [ P.id_ "chessboard", onCreated ChessboardMounted ] []
  ]
-----------------------------------------------------------------------------
