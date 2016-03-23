module Gaze.Component where

import Json.Encode

type Action
  = Navigate
  | Tick
  | Event String Json.Encode.Value

type Id
  = System
  | Charts
  -- | Alloc

stringToId : String -> Id
stringToId string =
  case string of
    "system" ->
      System
    "charts" ->
      Charts
    _ ->
      Debug.crash "stringToId"
