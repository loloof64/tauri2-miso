{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Test.Hspec

import Greet (greet)

main :: IO ()
main = hspec $
  describe "greet" $ do
    it "greets a given first name" $
      greet "Ada" `shouldBe` "Hello Ada !"

    it "greets an empty name" $
      greet "" `shouldBe` "Hello  !"
