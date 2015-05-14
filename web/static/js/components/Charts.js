import React from "bower_components/react/react";
import Reflux from "bower_components/reflux/dist/reflux";
import ChannelStore from "../stores/ChannelStore";
import Actions from "../actions";


export default React.createClass({
  mixins: [Reflux.connect(ChannelStore, "store")],

  componentWillMount() {
    Actions.join("charts");
  },

  render() {
    var channel = this.state.store.channels.charts;
    if (!channel) return <div/>;

    return <div/>;
  }
});
