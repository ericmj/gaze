module Gaze.Widget where

import Html exposing (..)
import Html.Attributes exposing (..)
import String
import Effects exposing (Effects)
import Task

elemDimensionsBox : Signal.Mailbox String
elemDimensionsBox =
  Signal.mailbox ""

registerForElemDims : String -> Effects ()
registerForElemDims id =
  Signal.send elemDimensionsBox.address id
    |> Effects.task

doTickBox : Signal.Mailbox ()
doTickBox =
  Signal.mailbox ()

doTick : Effects ()
doTick =
  Signal.send doTickBox.address ()
    |> Effects.task

panel : Html -> Html -> Html
panel heading body =
  div [class "panel panel-default"]
    [ div [class "panel-heading"] [heading]
    , div [class "panel-body"] [body]
    ]

genColors : Int -> List String
genColors num =
  [1..num]
    |> List.map (\i -> hsvToRgb (1 / toFloat num * toFloat i, 1, 1))
    |> List.map colorToString

hsvToRgb : (Float, Float, Float) -> (Int, Int, Int)
hsvToRgb (h, s, v) =
  let i = floor (h * 6)
      f = h * 6 - (toFloat i)
      p = v * (1 - s)
      q = v * (1 - f * s)
      t = v * (1 - (1 - f) * s)
      (r, g, b) = case i % 6 of
                    0 -> (v, t, p)
                    1 -> (q, v, p)
                    2 -> (p, v, t)
                    3 -> (p, q, v)
                    4 -> (t, p, v)
                    5 -> (v, p, q)
                    _ -> Debug.crash "make elm happy"
  in (floor (r*255), floor (g*255), floor (b*255))

colorToString : (Int, Int, Int) -> String
colorToString (a, b, c) =
  "#" ++ String.join "" (List.map numToHexString [a, b, c])

numToHexString : Int -> String
numToHexString num =
  if num == 0 then
    "00"
  else if num < 16 then
    "0" ++ toHexs num
  else
    toHexs num

toHexs : Int -> String
toHexs num =
  if num // 16 == 0 then
    toHex num
  else
    toHexs (num // 16) ++ toHex (num % 16)

toHex : Int -> String
toHex num =
  if num < 10 then
    toString num
  else
    case num of
      10 -> "A"
      11 -> "B"
      12 -> "C"
      13 -> "D"
      14 -> "E"
      15 -> "F"
      _ -> Debug.crash "invalid toHex"
