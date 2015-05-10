export default React.createClass({
  render() {
    return <div>
      {this.state.panels.map(([left, right]) => {
        return <div className="row" key={left.name}>
          {this.renderPanel(left)}
          {this.renderPanel(right)}
        </div>
      })}
      {this.renderTime()}
    </div>;
  },

  renderPanel({name, data}) {
    var info = data.map(({name, value}) => {
      return [<dt key={"dt-" + name}>{name}</dt>, <dd key={"dd-" + name}>{value}</dd>];
    });

    return <div className="col-md-6">
      <div className="panel panel-default">
        <div className="panel-heading">{name}</div>
        <div className="panel-body">
          <dl className="dl-horizontal">
            {info}
          </dl>
        </div>
      </div>
    </div>;
  },

  renderTime() {
    return <div>Last update: {this.state.time.toISOString()}</div>;
  },

  getInitialState() {
    return {panels: [], time: new Date()}
  },

  componentWillMount() {
    this.props.socket.join("system", {})
      .receive("ok", chan => {
        chan.on("update", this.update);
      })
  },

  update({info}) {
    this.setState({panels: info, time: new Date()});
  }
});
