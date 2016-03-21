module Gaze.Charts where

import Html exposing (..)
import Html.Attributes
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Effects exposing (Effects)
import Json.Encode
import Json.Decode exposing (..)
import String
import Dict
import Gaze.Widget as Widget
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
    ( {model | joined = True}
    , Effects.batch
        [ Socket.joinChannel "charts"
        , Widget.doTick
        ]
    )

tick : Model -> (Model, Effects ())
tick model =
  (model, Widget.registerForElemDims "schedulers")
  |> Debug.log "tick"

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

view : Dict.Dict String (Int, Int) -> Model -> Html
view elems model =
  let size = case Dict.get "schedulers" elems of
               Just size ->
                 size
               _ ->
                 (100, 100)
  in div [class "row"]
       [ div [class "col-md-12"]
           [ Widget.panel (Html.text "Schedulers") (viewSchedulersSvg size model) ]
       ]

viewSchedulersSvg : (Int, Int) -> Model -> Html
viewSchedulersSvg (x, y) model =
  let size = (toFloat x, toFloat y)
  in div [class "col-md-6"]
       [ Svg.svg [id "schedulers"] (viewSchedulers size model.schedulers) ]

viewSchedulers : (Float, Float) -> List (List Float) -> List Svg
viewSchedulers size schedulers =
  let colors = Widget.genColors (List.length schedulers)
  in List.map (viewScheduler size) (Util.zip schedulers colors)

viewScheduler : (Float, Float) -> (List Float, String) -> Svg
viewScheduler size (values, color) =
  let values' = Util.zip (List.reverse [0..100]) values
                 |> List.map (\(x, y) -> (x, 1-y))
                 |> List.map (scalePoint (100, 1) size)
  in case values' of
    [] ->
      Svg.path [] []
    (fX, fY) :: rest ->
      let first = "M " ++ toString fX ++ " " ++ toString fY
          rest' = List.map (\(x, y) -> "L " ++ toString x ++ " " ++ toString y) rest
          values'' = first ++ " " ++ String.join " " rest'
      in Svg.path [d values'', class "line", stroke color] []

scalePoint : (Float, Float) -> (Float, Float) -> (Float, Float) -> (Float, Float)
scalePoint (vX, vY) (sX, sY) (pX, pY) =
  (sX / vX * pX, sY / vY * pY)
