module Gaze where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import StartApp
import Effects exposing (Effects)
import Task
import Dict
import Json.Encode
import Gaze.Widget as Widget
import Gaze.Socket as Socket
import Gaze.System as System
import Gaze.Charts as Charts

type alias Model =
  { nav : List ComponentId
  , activeId : ComponentId
  , system : System.Model
  , charts : Charts.Model
  , elemDimensions : Dict.Dict String (Int, Int)
  }

type Action
  = Noop
  | Init
  | Tick
  | Navigate ComponentId
  | Event String String Json.Encode.Value
  | ElemDims (List (String, (Int, Int)))

type ComponentId
  = System
  | Charts

port tasks : Signal (Task.Task Effects.Never ())
port tasks =
  app.tasks

port appInit : Signal ()
port tick : Signal ()

port joinChannel : Signal String
port joinChannel =
  Socket.joinChannelBox |> .signal

port channelPush : Signal (String, String, String)
port channelPush =
  Socket.pushEventBox |> .signal

port channelEvent : Signal (String, String, Json.Encode.Value)

port elemDimensions : Signal (List (String, (Int, Int)))

port registerElemDimensions : Signal (List String)
port registerElemDimensions =
  Widget.elemDimensionsBox |> .signal

port doTick : Signal ()
port doTick =
  Widget.doTickBox |> .signal

main : Signal Html
main = app.html

app : StartApp.App Model
app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = inputs
    }

init : (Model, Effects Action)
init = (model, Effects.none)

model : Model
model =
  { nav = [System, Charts]
  , activeId = System
  , system = System.model
  , charts = Charts.model
  , elemDimensions = Dict.empty
  }

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Navigate id ->
      let (model, effects) = callNavigate {model | activeId = id}
      in (model, Effects.map (always Noop) effects)
    Init ->
      update (Navigate System) model
    Event channel event payload ->
      let model = doEvent model channel event payload
      in (model, Effects.none)
    ElemDims dict ->
      ({model | elemDimensions = Dict.fromList dict}, Effects.none)
    Tick ->
      let (model, effects) = callTick model
      in (model, Effects.map (always Noop) effects)
    Noop ->
      (model, Effects.none)

callNavigate : Model -> (Model, Effects ())
callNavigate model =
  case model.activeId of
    System ->
      let (compModel, effects) = System.navigate model.system
      in ({model | system = compModel}, effects)
    Charts ->
      let (compModel, effects) = Charts.navigate model.charts
      in ({model | charts = compModel}, effects)

callTick : Model -> (Model, Effects ())
callTick model =
  case model.activeId of
    System ->
      let (compModel, effects) = System.tick model.system
      in ({model | system = compModel}, effects)
    Charts ->
      let (compModel, effects) = Charts.tick model.charts
      in ({model | charts = compModel}, effects)

doEvent : Model -> String -> String -> Json.Encode.Value -> Model
doEvent model channel event payload =
  case channel of
    "system" ->
      {model | system = System.event model.system event payload}
    "charts" ->
      {model | charts = Charts.event model.charts event payload}
    _ ->
      model

view : Signal.Address Action -> Model -> Html
view address model =
  div []
    [ viewNav address model
    , div [class "container"] [viewContainer address model]
    ]

inputs : List (Signal Action)
inputs =
  [ Signal.map (always Init) appInit
  , Signal.map (always Tick) tick
  , Signal.map (uncurry3 Event) channelEvent
  , Signal.map ElemDims elemDimensions]

viewNav : Signal.Address Action -> Model -> Html
viewNav address model =
  div [class "navbar navbar-default"]
    [ div [class "container"]
        [ div [class "navbar-header"]
            [ button [type' "button", class "navbar-toggle collapsed", attribute "data-toggle" "collapse", attribute "data-target" "#navbar-collapse"]
                [ span [class "icon-bar"] []
                , span [class "icon-bar"] []
                , span [class "icon-bar"] []
                ]
            , a [class "navbar-brand", href "/gaze"] [text "Gaze"]
            ]
        , div [class "collapse navbar-collapse", id "navbar-collapse"]
            [ ul [class "nav navbar-nav"] (viewNavLinks address model) ]
        ]
    ]

viewNavLinks : Signal.Address Action -> Model -> List Html
viewNavLinks address model =
  let mapper nav =
        li [classList [("active", model.activeId == nav)]]
          [ a [onClick address (Navigate nav)] [text (toString nav)] ]
  in List.map mapper model.nav

viewContainer : Signal.Address Action -> Model -> Html
viewContainer address model =
  case model.activeId of
    System ->
      System.view model.elemDimensions model.system
    Charts ->
      Charts.view model.elemDimensions model.charts

uncurry3 : (a -> b -> c -> d) -> (a, b, c) -> d
uncurry3 fun (a, b, c) =
  fun a b c
