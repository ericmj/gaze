module Gaze.Charts where

import Html exposing (..)
-- import Html.Attributes exposing (..)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Effects exposing (Effects)
import Json.Encode
import Json.Decode exposing (..)
import String
import Gaze.Util as Util
import Gaze.Socket as Socket

type alias Model =
  { joined : Bool
  , schedulers : List (List Float)
  }

model : Model
model =
  { joined = False
  , schedulers = []
  }

navigate : Model -> (Model, Effects ())
navigate model =
  if model.joined then
    (model, Effects.none)
  else
    ({model | joined = True}, Socket.joinChannel "charts")

event : Model -> String -> Json.Encode.Value -> Model
event model event payload =
  case event of
    "update" ->
      let schedulers = Util.zipDefault [] (decode payload) model.schedulers
                        |> List.map ((List.take 101) << uncurry (::))
      in {model | schedulers = schedulers}
    _ ->
      model

decode : Json.Encode.Value -> (List Float)
decode value =
  let decoder = "schedulers" := Json.Decode.list float
      result = decodeValue decoder value
  in case result of
     Ok value ->
       value
     _ ->
       Debug.crash "decode chars"

view : Model -> Html
view model =
  div [class "row"]
    [ div [class "col-md-12"]
        [ div [class "panel panel-default"]
            [ div [class "panel-heading"] [Html.text "Schedulers"]
            , div [class "panel-body"]
                [ Svg.svg [class "schedulers", viewBox "0 0 100 100", preserveAspectRatio "none"]
                          (viewSchedulers model.schedulers) ]
            ]
        ]
    ]

viewSchedulers : List (List Float) -> List Svg
viewSchedulers schedulers =
  let colors = genColors (List.length schedulers)
  in List.map viewScheduler (Util.zip schedulers colors)

viewScheduler : (List Float, String) -> Svg
viewScheduler (values, color) =
  case values of
    [] ->
      Svg.path [] []
    first :: rest ->
      let values' = Util.zip (List.reverse [0..99]) rest
                     |> List.map (\(x, y) -> "L " ++ toString x ++ " " ++ toString (100 - y*100))
          first' = "M 100 " ++ toString (100 - first*100)
          values'' = first' ++ " " ++ String.join " " values'
      in Svg.path [d values'', class "line", stroke color] []

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

toHexs: Int -> String
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
