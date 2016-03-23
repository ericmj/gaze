module Gaze.Alloc where

import Html exposing (..)
import Html.Attributes exposing (.. )
import Effects exposing (Effects)
import Json.Encode
import Json.Decode exposing (..)
import String
import Dict
import Gaze.Component as Component
import Gaze.Widget as Widget
import Gaze.Socket as Socket

type alias Alloc = List (String, String, String)

type alias Model =
  { joined : Bool
  , alloc : Alloc
  }

model : Model
model =
  { joined = False
  , alloc = []
  }

update : Component.Action -> Model -> (Model, Effects ())
update action model =
  case action of
    Component.Navigate ->
      if model.joined then
        (model, Effects.none)
      else
        ( {model | joined = True}
        , Effects.batch
            [ Socket.joinChannel "alloc"
            , Widget.doTick
            ]
        )
    Component.Tick ->
      (model, Effects.none)
    Component.Event event json ->
      case event of
        "update" ->
          ({model | alloc = decode json}, Effects.none)
        _ ->
          (model, Effects.none)

decode : Json.Encode.Value -> Alloc
decode value =
  let alloc = "alloc" := Json.Decode.list (tuple3 (,,) string string string)
      result = decodeValue alloc value
  in case result of
       Ok value ->
         value
       _ ->
         Debug.crash "decode system"

view : Dict.Dict String (Int, Int) -> Model -> Html
view elems model =
  viewAlloc model.alloc

viewAlloc : Alloc -> Html
viewAlloc rows =
  let rower (type', block, carrier) =
        tr [] [th [] [text type'], td [] [text block], td [] [text carrier]]
  in div [class "col-md-12"]
       [ Widget.panel "Allocators"
           [ table [class "table table-striped"]
               [ thead [] [tr [] viewAllocHeaders]
               , tbody [] (List.map rower rows)
               ]
           ]
       ]

viewAllocHeaders : List Html
viewAllocHeaders =
  [ th [] [text "Type"]
  , th [] [text "Block size"]
  , th [] [text "Carrier size"]
  ]
