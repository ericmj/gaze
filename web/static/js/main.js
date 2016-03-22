import {Socket} from "phoenix"

var elmDiv = document.getElementById('gaze'),
    socket = new Socket("/gaze/socket"),
    channels = {},
    elemDimensions = [],
    state = {appInit: [], channelEvent: ["", "", ""], elemDimensions: [], tick: []},
    app = Elm.embed(Elm.Gaze, elmDiv, state);

var onresize = () => {
  var dims = [];
  elemDimensions.forEach(elem => {
    var domElem = document.getElementById(elem)
    if (domElem) {
      var box = domElem.getBoundingClientRect()
      dims.push([elem, [box.width, box.height]])
    }
  })

  app.ports.elemDimensions.send(dims)
}

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

app.ports.registerElemDimensions.subscribe(ids => {
  Array.prototype.push.apply(elemDimensions, ids);
  onresize()
})

app.ports.doTick.subscribe(() => {
  app.ports.tick.send([])
})

window.onresize = onresize

app.ports.appInit.send([])
