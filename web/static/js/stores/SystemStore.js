import Reflux from "bower_components/reflux/dist/reflux";
import channelMixin from "./ChannelMixin";

export default Reflux.createStore({
  mixins: [channelMixin("system")]
});
