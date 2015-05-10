export default React.createClass({
  render() {
    return <div>
      {GAZE_INFO.map(([left, right]) => {
        return <div className="row">
          {this.renderPanel(left)}
          {this.renderPanel(right)}
        </div>
      })}
    </div>;
  },

  renderPanel({name, data}) {
    var info = data.map(({name, value}) => {
      return [<dt>{name}</dt>, <dd>{value}</dd>];
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
  }
});
