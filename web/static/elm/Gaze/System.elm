module Gaze.System where

import Html exposing (..)
import Html.Attributes exposing (..)
import Effects exposing (Effects)
import Dict exposing (Dict)
import Json.Encode
import Json.Decode exposing (..)
import Gaze.Util as Util
import Gaze.Socket as Socket

type alias Panel = List String
type alias Alloc = List (String, String, String)
type alias ViewPanel = (String, List String)

type alias Model =
  { joined : Bool
  , panels : List Panel
  , alloc : Alloc
  }

model =
  { joined = False
  , panels = []
  , alloc = []
  }

navigate : Model -> (Model, Effects ())
navigate model =
  if model.joined then
    (model, Effects.none)
  else
    ({model | joined = True}, Socket.joinChannel "system")

event : Model -> String -> Json.Encode.Value -> Model
event model event payload =
  case event of
    "update" ->
      let (panels', alloc) = decode payload
      in {model | panels = panels', alloc = alloc}
    _ ->
      model

decode : Json.Encode.Value -> (List Panel, Alloc)
decode value =
  let panels' = "panels" := Json.Decode.list (Json.Decode.list string)
      alloc = "alloc" := Json.Decode.list (tuple3 (,,) string string string)
      decoder = object2 (,) panels' alloc
      result = decodeValue decoder value
  in case result of
       Ok value ->
         value
       _ ->
         Debug.crash "decode system"

view : Model -> Html
view model =
  let panels' = model.panels |> Util.zip panels |> Util.chunk2
  in div [] (List.map viewPanelRow panels' ++ [div [class "row"] [viewAlloc model.alloc]])

viewPanelRow : List (ViewPanel, Panel) -> Html
viewPanelRow panels =
  div [class "row"] (List.map viewPanel panels)

viewPanel : (ViewPanel, Panel) -> Html
viewPanel ((title, headings), model) =
  let rows = Util.zip headings model
      map (header, data) = [dt [] [text header], dd [] [text data]]
      dls = List.map map rows |> List.concat
  in div [class "col-md-6"]
       [ div [class "panel panel-default"]
           [ div [class "panel-heading"] [text title]
           , div [class "panel-body"] [dl [class "dl-horizontal"] dls]
           ]
       ]

viewAlloc : Alloc -> Html
viewAlloc rows =
  let rower (type', block, carrier) =
        tr [] [th [] [text type'], td [] [text block], td [] [text carrier]]
  in div [class "col-md-12"]
       [ div [class "panel panel-default"]
           [ div [class "panel-heading"] [text "Allocators"]
           , div [class "panel-body"]
               [ table [class "table table-striped"]
                   [ thead []
                       [ tr []
                           [ th [] [text "Type"]
                           , th [] [text "Block size"]
                           , th [] [text "Carrier size"]
                           ]
                       ]
                   , tbody [] (List.map rower rows)
                   ]
               ]
           ]
       ]

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
