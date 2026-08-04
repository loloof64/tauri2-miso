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
app = component emptyModel updateModel viewModel
-----------------------------------------------------------------------------
updateModel :: Action -> Effect parent props Model Action
updateModel = \case
  NameChanged n ->
    name .= n
  Greet -> do
    n <- use name
    greeting .= ms (greet (fromMisoString n))
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
  ]
-----------------------------------------------------------------------------
