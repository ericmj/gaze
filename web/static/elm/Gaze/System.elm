module Gaze.System where

import Html exposing (..)
import Html.Attributes exposing (..)
import Effects exposing (Effects)
import Dict exposing (Dict)
import Json.Encode
import Json.Decode exposing (..)
import Effects exposing (Effects)
import Dict
import Gaze.Component as Component
import Gaze.Widget as Widget
import Gaze.Util as Util
import Gaze.Socket as Socket

type alias Panel = List String
type alias ViewPanel = (String, List String)

type alias Model =
  { joined : Bool
  , panels : List Panel
  }

model =
  { joined = False
  , panels = []
  }

update : Component.Action -> Model -> (Model, Effects ())
update action model =
  case action of
    Component.Navigate ->
      if model.joined then
        (model, Effects.none)
      else
        ({model | joined = True}, Socket.joinChannel "system")
    Component.Tick ->
      (model, Effects.none)
    Component.Event event json ->
      case event of
        "update" ->
          ({model | panels = decode json}, Effects.none)
        _ ->
          (model, Effects.none)

decode : Json.Encode.Value -> List Panel
decode value =
  let panels' = "panels" := Json.Decode.list (Json.Decode.list string)
      result = decodeValue panels' value
  in case result of
       Ok value ->
         value
       _ ->
         Debug.crash "decode system"

view : Dict.Dict String (Int, Int) -> Model -> Html
view elems model =
  let panels' = model.panels |> Util.zip panels |> Util.chunk2
  in div [] (List.map viewPanelRow panels')

viewPanelRow : List (ViewPanel, Panel) -> Html
viewPanelRow panels =
  div [class "row"] (List.map viewPanel panels)

viewPanel : (ViewPanel, Panel) -> Html
viewPanel ((title, headings), model) =
  let rows = Util.zip headings model
      map (header, data) = [dt [] [text header], dd [] [text data]]
      dls = List.map map rows |> List.concat
  in div [class "col-md-6"] [Widget.panel title [dl [class "dl-horizontal"] dls]]

panels =
  [ ("System and architecture", system_headers)
  , ("Memory usage", memory_headers)
  , ("CPUs and threads", cpu_headers)
  , ("Statistics", stats_headers)
  ]

system_headers =
  [ "System version"
  , "ERTS version"
  , "Compiled for"
  , "Emulator wordsize"
  , "Process wordsize"
  , "SMP support"
  , "Thread support"
  , "Async thread pool size"
  ]

memory_headers =
  [ "Total"
  , "Processes"
  , "Atoms"
  , "Binaries"
  , "Code"
  , "ETS"
  ]

cpu_headers =
  [ "Logical CPUs"
  , "Online logical CPUs"
  , "Available logical CPUs"
  , "Schedulers"
  , "Online schedulers"
  , "Available schedulers"
  ]

stats_headers =
  [ "Up time"
  , "Max processes"
  , "Processes"
  , "Run queue"
  , "IO input"
  , "IO output"
  ]
