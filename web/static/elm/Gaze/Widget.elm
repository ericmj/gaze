module Gaze.Widget where

import Html exposing (..)
import Html.Attributes as Attr
import Svg exposing (..)
import Svg.Attributes as SvgAttr
import String
import Effects exposing (Effects)
import Task
import Gaze.Util as Util

elemDimensionsBox : Signal.Mailbox (List String)
elemDimensionsBox =
  Signal.mailbox []

registerForElemDims : List String -> Effects ()
registerForElemDims ids =
  Signal.send elemDimensionsBox.address ids
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
  div [Attr.class "panel panel-default"]
    [ div [Attr.class "panel-heading"] [heading]
    , div [Attr.class "panel-body"] [body]
    ]

autoScaleChart : List Html.Attribute -> (Float, Float) -> Float -> List (List Float) -> Html
autoScaleChart attrs size scaleX values =
  let scaleY = values |> List.concat |> List.foldl Basics.max 1
      scaleY' = scaleY / 10 |> ceiling |> ((*) 10) |> toFloat
      values' = List.map (List.map ((-) scaleY')) values
  in chart attrs size (scaleX, scaleY') values'

chart : List Html.Attribute -> (Float, Float) -> (Float, Float) -> List (List Float) -> Html
chart attrs size scale values =
  Svg.svg attrs (chartPaths size scale values)

chartPaths : (Float, Float) -> (Float, Float) -> List (List Float) -> List Svg
chartPaths size scale values =
  let colors = genColors (List.length values)
  in List.map (chartPath size scale) (Util.zip values colors)

chartPath : (Float, Float) -> (Float, Float) -> (List Float, String) -> Svg
chartPath size (scaleX, scaleY) (values, color) =
  let values' = Util.zip (List.reverse [0..scaleX]) values
                  |> List.map (scalePoint (scaleX, scaleY) size)
  in case values' of
       [] ->
         Svg.path [] []
       (fX, fY) :: rest ->
         let first = "M " ++ toString fX ++ " " ++ toString fY
             rest' = List.map (\(x, y) -> "L " ++ toString x ++ " " ++ toString y) rest
             values'' = first ++ " " ++ String.join " " rest'
         in Svg.path [SvgAttr.d values'', Attr.class "line", SvgAttr.stroke color] []

scalePoint : (Float, Float) -> (Float, Float) -> (Float, Float) -> (Float, Float)
scalePoint (vX, vY) (sX, sY) (pX, pY) =
  (sX / vX * pX, sY / vY * pY)

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
