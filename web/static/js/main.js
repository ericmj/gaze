import {Socket} from "phoenix"

var elmDiv = document.getElementById('gaze'),
    socket = new Socket("/gaze/socket"),
    channels = {},
    state = {appInit: [], channelEvent: ["", "", ""]},
    app = Elm.embed(Elm.Gaze, elmDiv, state);

socket.connect()

app.ports.joinChannel.subscribe(name => {
  var channel = socket.channel(name, {})
  channel.onMessage = (event, payload, ref) => {
    console.log ["onMessage", event, payload, ref]
    app.ports.channelEvent.send([name, event, payload])
  }
  channel.join()
  channels[name] = channel
})

app.ports.channelPush.subscribe((name, event, payload) => {
  var channel = channels[name]
  channel.push(event, payload)
})

app.ports.appInit.send([])
