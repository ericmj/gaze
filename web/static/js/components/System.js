import Reflux from "bower_components/reflux/dist/reflux";
import ChannelStore from "../stores/ChannelStore";
import Actions from "../actions";

export default React.createClass({
  mixins: [Reflux.connect(ChannelStore, "store")],

  componentWillMount() {
    Actions.join("system");
  },

  render() {
    var channel = this.state.store.channels.system;
    if (!channel) return <div/>;

    return <div>
      {channel.panels.map(([left, right]) => {
        return <div className="row" key={left.name}>
          {this.renderPanel(left)}
          {this.renderPanel(right)}
        </div>
      })}
      <div className="row">
        <div className="col-md-12">
          {this.renderAlloc(channel.alloc)}
        </div>
      </div>
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

  renderAlloc(rows) {
    return <div className="panel panel-default">
      <div className="panel-heading">Allocators</div>
      <div className="panel-body">
        <table className="table table-striped">
          <thead>
            <tr>
              <th>Type</th>
              <th>Block size</th>
              <th>Carrier size</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(([type, block, carrier]) => {
              return <tr>
                <th>{type}</th>
                <td>{block}</td>
                <td>{carrier}</td>
              </tr>
            })}
          </tbody>
        </table>
      </div>
    </div>;
  }
});
