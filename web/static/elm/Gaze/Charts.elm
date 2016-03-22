module Gaze.Charts where

import Html exposing (..)
import Html.Attributes exposing (.. )
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
  , memory : List (List Float)
  , io : List (List Float)
  }

model : Model
model =
  { joined = False
  , schedulers = []
  , memory = []
  , io = []
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
  (model, Widget.registerForElemDims ["schedulers", "memory", "io"])

event : Model -> String -> Json.Encode.Value -> Model
event model event payload =
  case event of
    "update" ->
      let (schedulers, memory, io) = decode payload
          schedulers' = List.map ((-) 1) schedulers
      in {model | schedulers = track schedulers' model.schedulers
                , memory = track memory model.memory
                , io = track io model.io
                }
    _ ->
      model

track : List Float -> List (List Float) -> List (List Float)
track payload existing =
  Util.zipDefault [] payload existing
    |> List.map ((List.take 101) << uncurry (::))

decode : Json.Encode.Value -> (List Float, List Float, List Float)
decode value =
  let schedulers = "schedulers" := Json.Decode.list float
      memory = "memory" := Json.Decode.list float
      io = "io" := Json.Decode.list float
      decoder = object3 (,,) schedulers memory io
      result = decodeValue decoder value
  in case result of
     Ok value ->
       value
     _ ->
       Debug.crash "decode chars"

view : Dict.Dict String (Int, Int) -> Model -> Html
view elems model =
  let schedulerSize = Dict.get "schedulers" elems |> Maybe.withDefault (100, 100)
      memorySize = Dict.get "memory" elems |> Maybe.withDefault (100, 100)
      ioSize = Dict.get "io" elems |> Maybe.withDefault (100, 100)
  in div []
       [ div [class "row"]
           [ div [class "col-md-12"]
              [ Widget.panel (Html.text "Schedulers") (viewSchedulersSvg schedulerSize model) ]
           ]
       , div [class "row"]
           [ div [class "col-md-6"]
              [ Widget.panel (Html.text "Memory usage (MB)") (viewMemorySvg memorySize model) ]
           , div [class "col-md-6"]
              [ Widget.panel (Html.text "IO usage (kB)") (viewIOSvg ioSize model) ]
           ]
       ]

viewSchedulersSvg : (Int, Int) -> Model -> Html
viewSchedulersSvg (x, y) model =
  let size = (toFloat x, toFloat y)
  in div [] [Widget.chart [id "schedulers"] size (100, 1) model.schedulers]

viewMemorySvg : (Int, Int) -> Model -> Html
viewMemorySvg (x, y) model =
  let size = (toFloat x, toFloat y)
  in div [] [Widget.autoScaleChart [id "memory"] size 100 model.memory]

viewIOSvg : (Int, Int) -> Model -> Html
viewIOSvg (x, y) model =
  let size = (toFloat x, toFloat y)
  in div [] [Widget.autoScaleChart [id "io"] size 100 model.io]
