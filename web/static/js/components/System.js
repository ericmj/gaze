export default React.createClass({
  render() {
    return <div className="row">
      {this.renderSystem()}
      {this.renderMemory()}
    </div>;
  },

  renderSystem() {
    var info = GAZE_INFO["system"].map(({name, value}) => {
      return [<dt>{name}</dt>, <dd>{value}</dd>];
    });

    return <div className="col-md-6">
      <div className="panel panel-default">
        <div className="panel-heading">System and Architechture</div>
        <div className="panel-body">
          <dl className="dl-horizontal">
            {info}
          </dl>
        </div>
      </div>
    </div>;
  },

  renderMemory() {
    return <div className="col-md-6">
      <div className="panel panel-default">
        <div className="panel-heading">Memory and Usage</div>
        <div className="panel-body">
          Panel content
        </div>
      </div>
    </div>;
  }
});
