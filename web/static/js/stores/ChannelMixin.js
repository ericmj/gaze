import Reflux from "bower_components/reflux/dist/reflux";
import Actions from "../Actions";

export default channelName => {
  return {
    listenables: Actions,

    getInitialState() {
      return null;
    },

    onJoined(joinedChannelName, chan) {
      if (channelName == joinedChannelName) {
        chan.on("update", data => {
          this.trigger(data);
        });
      }
    }
  }
};
