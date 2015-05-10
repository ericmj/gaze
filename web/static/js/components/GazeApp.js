import {Socket} from "../../vendor/phoenix";
import cx from "bower_components/classnames";
import System from "./System";
import Actions from "../actions";

export default React.createClass({
  componentDidMount() {
    Actions.last_update.listen(last_update => {
      this.setState({last_update});
    });
  },

  render() {
    return <div>
      {this.renderConnectionStatus()}
      {this.renderNav()}
      {this.renderContainer()}
    </div>;
  },

  renderNav() {
    return <ul className="nav nav-tabs">
      {this.renderTabs()}
    </ul>;
  },

  renderConnectionStatus() {
    var label = this.state.connected
              ? <h4><span className="label label-success pull-right">Connected</span></h4>
              : <h4><span className="label label-danger pull-right">Disconnected</span></h4>;

    return <div>
      {label}
      <span className="text-muted pull-right" style={{"margin-right": "15px"}} title="Last update">
        {this.state.last_update.toISOString()}
      </span>
      </div>;
  },

  renderTabs() {
    return this.state.nav.map(tab => {
      var classes = cx({active: tab.active});
      return <li key={tab.id} id={tab.id} className={classes}>
        <a onClick={this.onTabClick}>{tab.value}</a>
      </li>;
    });
  },

  renderContainer() {
    var component = this.state.active_component
                  ? <this.state.active_component socket={this.state.socket}/>
                  : <div/>;

    return <div className="container main">
      {component}
    </div>;
  },

  getInitialState() {
    var socket = new Socket("/gaze/ws");
    socket.connect();
    socket.onOpen(this.onSocketOpen);
    socket.onClose(this.onSocketClose);
    socket.onError(this.onSocketClose);

    return {
      nav: [
        {id: "nav_system",       value: "System",       component: System,  active: true},
        {id: "nav_load_charts",  value: "Load charts",  component: null,    active: false},
        {id: "nav_applications", value: "Applications", component: null,    active: false}
      ],
      active_component: System,
      socket: socket,
      connected: false,
      last_update: new Date()
    }
  },

  onTabClick(e) {
    var nav = this.state.nav.map(tab => {
      if (e.target.parentElement.id == tab.id) {
        var active_component = tab.component;
        tab.active = true;
      }
      else {
        tab.active = false;
      }
    });
    this.setState({nav, active_component});
  },

  onSocketOpen() {
    this.setState({connected: true});
  },

  onSocketClose() {
    this.setState({connected: false});
  },
});
