import React from "bower_components/react/react";
import Reflux from "bower_components/reflux/dist/reflux";
import d3 from "bower_components/d3/d3";
import ChartsStore from "../stores/ChartsStore";
import Actions from "../Actions";

var MAX_TICKS = 60;

export default React.createClass({
  mixins: [Reflux.listenTo(ChartsStore, "channelUpdate")],

  componentWillMount() {
    Actions.join("charts");
    this.data = [];
  },

  componentDidMount() {
    this.updateCharts([]);
  },

  shouldComponentUpdate(nextProps, nextState) {
    return false;
  },

  channelUpdate(_store) {
    this.data.push(Math.random());

    if (this.data.length > 60)
      this.data.shift();

    this.updateCharts(this.data);
  },

  updateCharts(data) {
    var svg = d3.select("svg#schedulers");
    var box = svg.node().getBoundingClientRect();

    var x = d3.time.scale().range([0, box.width]);
    var y = d3.scale.linear().range([box.height, 0]);

    x.domain([0, MAX_TICKS-1]);
    y.domain([0, 1]);

    var line = d3.svg.line()
        .x((d, i) => x(i))
        .y((d) => y(d));

    svg.select("path").remove();

    svg.append("path")
      .datum(data)
      .attr("class", "line")
      .attr("d", line);
  },

  render() {
    return  <div className="row">
      <div className="col-md-12">
        <div className="panel panel-default">
          <div className="panel-heading">Schedulers</div>
          <div className="panel-body">
            <svg id="schedulers"/>
          </div>
        </div>
      </div>
    </div>;
  }
});
