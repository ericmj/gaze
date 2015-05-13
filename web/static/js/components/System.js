import Reflux from "bower_components/reflux/dist/reflux";
import ChannelStore from "../stores/ChannelStore";
import Actions from "../actions";

const SYSTEM_HEADERS = [
  "System version",
  "ERTS version",
  "Compiled for",
  "Emulator wordsize",
  "Process wordsize",
  "SMP support",
  "Thread support",
  "Async thread pool size"
]

const MEMORY_HEADERS = [
  "Total",
  "Processes",
  "Atoms",
  "Binaries",
  "Code",
  "ETS"
]

const CPU_HEADERS = [
  "Logical CPUs",
  "Online logical CPUs",
  "Available logical CPUs",
  "Schedulers",
  "Online schedulers",
  "Available schedulers"
]

const STATS_HEADERS = [
  "Up time",
  "Max processes",
  "Processes",
  "Run queue",
  "IO input",
  "IO output"
]


export default React.createClass({
  mixins: [Reflux.connect(ChannelStore, "store")],

  componentWillMount() {
    Actions.join("system");
  },

  render() {
    var channel = this.state.store.channels.system;
    if (!channel) return <div/>;
    var panels = channel.panels;

    return <div>
      <div className="row">
        {this.renderPanel("System and architecture", SYSTEM_HEADERS, panels[0])}
        {this.renderPanel("Memory usage", MEMORY_HEADERS, panels[1])}
      </div>
      <div className="row">
        {this.renderPanel("CPUs and threads", CPU_HEADERS, panels[2])}
        {this.renderPanel("Statistics", STATS_HEADERS, panels[3])}
      </div>
      <div className="row">
        {this.renderAlloc(channel.alloc)}
      </div>
    </div>;
  },

  renderPanel(title, headers, data) {
    var dl = headers.map((header, i) => {
      return [
        <dt key={"dt-" + i}>{header}</dt>,
        <dd key={"dd-" + i}>{data[i]}</dd>
      ];
    });

    return <div className="col-md-6">
      <div className="panel panel-default">
        <div className="panel-heading">{title}</div>
        <div className="panel-body">
          <dl className="dl-horizontal">
            {dl}
          </dl>
        </div>
      </div>
    </div>;
  },

  renderAlloc(rows) {
    return <div className="col-md-12">
      <div className="panel panel-default">
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
              {rows.map(([type, block, carrier], i) => {
                return <tr key={i}>
                  <th>{type}</th>
                  <td>{block}</td>
                  <td>{carrier}</td>
                </tr>
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>;
  }
});
