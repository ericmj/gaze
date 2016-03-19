module Gaze.Socket where

import Effects exposing (Effects)

joinChannelBox : Signal.Mailbox String
joinChannelBox =
  Signal.mailbox ""

pushEventBox : Signal.Mailbox (String, String, String)
pushEventBox =
  Signal.mailbox ("", "", "")

joinChannel : String -> Effects ()
joinChannel name =
  Signal.send joinChannelBox.address name
    |> Effects.task

pushEvent : String -> String -> String -> Effects ()
pushEvent name event payload =
  Signal.send pushEventBox.address (name, event, payload)
    |> Effects.task
