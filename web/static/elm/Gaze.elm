module Gaze where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import StartApp
import Effects exposing (Effects)
import Task
import Dict
import Json.Encode
import Gaze.Component as Component
import Gaze.Widget as Widget
import Gaze.Socket as Socket
import Gaze.System as System
import Gaze.Charts as Charts
import Gaze.Alloc as Alloc

type alias Model =
  { nav : List Component.Id
  , activeId : Component.Id
  , system : System.Model
  , charts : Charts.Model
  , alloc : Alloc.Model
  , elemDimensions : Dict.Dict String (Int, Int)
  }

type Action
  = Noop
  | Init
  | Tick
  | Navigate Component.Id
  | Event String String Json.Encode.Value
  | ElemDims (List (String, (Int, Int)))

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
  { nav = [Component.System, Component.Charts, Component.Alloc]
  , activeId = Component.System
  , system = System.model
  , charts = Charts.model
  , alloc = Alloc.model
  , elemDimensions = Dict.empty
  }

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Navigate id ->
      let model = {model | activeId = id}
      in callComponent Component.Navigate id model
    Init ->
      update (Navigate Component.System) model
    Event channel event payload ->
      let id = Component.stringToId channel
      in callComponent (Component.Event event payload) id model
    ElemDims dict ->
      ({model | elemDimensions = Dict.fromList dict}, Effects.none)
    Tick ->
      callComponent Component.Tick model.activeId model
    Noop ->
      (model, Effects.none)

callComponent : Component.Action -> Component.Id -> Model -> (Model, Effects Action)
callComponent action id model =
  let (model, effects) =
    case id of
      Component.System ->
        let (compModel, effects) = System.update action model.system
        in ({model | system = compModel}, effects)
      Component.Charts ->
        let (compModel, effects) = Charts.update action model.charts
        in ({model | charts = compModel}, effects)
      Component.Alloc ->
        let (compModel, effects) = Alloc.update action model.alloc
        in ({model | alloc = compModel}, effects)
  in (model, Effects.map (always Noop) effects)

view : Signal.Address Action -> Model -> Html
view address model =
  div []
    [ viewNav address model
    , div [class "container"] [viewComponent address model]
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

viewComponent : Signal.Address Action -> Model -> Html
viewComponent address model =
  case model.activeId of
    Component.System ->
      System.view model.elemDimensions model.system
    Component.Charts ->
      Charts.view model.elemDimensions model.charts
    Component.Alloc ->
      Alloc.view model.elemDimensions model.alloc

uncurry3 : (a -> b -> c -> d) -> (a, b, c) -> d
uncurry3 fun (a, b, c) =
  fun a b c
