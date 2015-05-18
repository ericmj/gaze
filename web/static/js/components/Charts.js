import React from "bower_components/react/react";
import Reflux from "bower_components/reflux/dist/reflux";
import d3 from "bower_components/d3/d3";
import ChartsStore from "../stores/ChartsStore";
import Actions from "../Actions";

var MAX_TICKS = 60;

export default React.createClass({
  mixins: [Reflux.listenTo(ChartsStore, "updateCharts")],

  componentWillMount() {
    Actions.join("charts");
  },

  shouldComponentUpdate(nextProps, nextState) {
    return false;
  },

  updateCharts({all, average, max_ticks}) {
    var svg = d3.select("svg#schedulers");
    var box = svg.node().getBoundingClientRect();

    var x = d3.time.scale().range([0, box.width]);
    var y = d3.scale.linear().range([box.height, 0]);

    x.domain([max_ticks-1, 0]);
    y.domain([0, 1]);

    var line = d3.svg.line()
        .interpolate("monotone")
        .x((d, i) => x(i))
        .y((d) => y(d));

    var colors = genColors(all.length + 1);

    svg.selectAll("path").remove();

    all.slice().reverse().forEach((data, i) => {
      svg.append("path")
        .datum(data.slice().reverse())
        .attr("class", "line")
        .style("stroke", colors[i])
        .attr("d", line);
    });

    svg.append("path")
      .datum(average.slice().reverse())
      .attr("class", "line")
      .style("stroke", colors[0])
      .style("stroke-width", "2.5px")
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

var hsvToRgb = (h, s, v) => {
  var r, g, b, i, f, p, q, t;
  if (h && s === undefined && v === undefined) {
      s = h.s, v = h.v, h = h.h;
  }
  i = Math.floor(h * 6);
  f = h * 6 - i;
  p = v * (1 - s);
  q = v * (1 - f * s);
  t = v * (1 - (1 - f) * s);
  switch (i % 6) {
      case 0: r = v, g = t, b = p; break;
      case 1: r = q, g = v, b = p; break;
      case 2: r = p, g = v, b = t; break;
      case 3: r = p, g = q, b = v; break;
      case 4: r = t, g = p, b = v; break;
      case 5: r = v, g = p, b = q; break;
  }
  return {
      r: Math.floor(r * 255),
      g: Math.floor(g * 255),
      b: Math.floor(b * 255)
  }
}

var hsvToHexColor = (h, s, v) => {
  var {r, g, b} = hsvToRgb(h, s, v);
  var [r, g, b] = [r, g, b].map(c => toHexString(c));

  return `#${r}${g}${b}`;
}

var toHexString = (num) => {
  if (num == 0)
    return "00";
  else if (num < 16)
    return `0${num.toString(16)}`;
  else
    return num.toString(16);
}

var genColors = (num) => {
  var range = 1 / num;
  var colors = [];

  for (var i = 1; i <= num; i++) {
    var color = hsvToHexColor(range*i, 1, 1);
    colors.push(color);
  }

  return colors;
}
