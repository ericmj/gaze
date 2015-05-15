import React from "bower_components/react/react";
import Reflux from "bower_components/reflux/dist/reflux";
import ChartsStore from "../stores/ChartsStore";
import Actions from "../Actions";


export default React.createClass({
  mixins: [Reflux.listenTo(ChartsStore, "channelUpdate")],

  componentWillMount() {
    Actions.join("charts");
  },

  render() {

    return <div/>;
  }
});
