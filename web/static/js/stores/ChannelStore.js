import {Socket} from "../../vendor/phoenix";
import Reflux from "bower_components/reflux/dist/reflux";
import Actions from "../actions";

export default Reflux.createStore({
  listenables: Actions,

  init() {
    this.connected = false;
    this.channels = {};
  },

  getInitialState() {
    return this;
  },

  onConnect() {
    this._socket = new Socket("/gaze/ws");
    this._socket.connect();
    this._socket.onOpen(this.onSocketOpen);
    this._socket.onClose(this.onSocketClose);
    this._socket.onError(this.onSocketClose);
  },

  onJoin(channel) {
    var chan = this._socket.chan(channel, {});

    chan.join().receive("ok", () => {
      chan.on("update", data => {
        this.channels[channel] = data;
        this.trigger(this);
      });
    });
  },

  onSocketOpen() {
    this.connected = true;
    this.trigger(this);
  },

  onSocketClose() {
    this.connected = false;
    this.trigger(this);
  }
});
