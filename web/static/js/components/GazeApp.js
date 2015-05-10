import {Socket} from "../../vendor/phoenix";
import cx from "bower_components/classnames";
import System from "./System";

export default React.createClass({
  render() {
    return <div>
      {this.renderNav()}
      {this.renderContainer()}
    </div>;
  },

  renderNav() {
    return <ul className="nav nav-tabs">
      {this.renderTabs()}
    </ul>;
  },

  renderTabs() {
    return this.state.nav.map(tab => {
      var classes = cx({active: tab.active});
      return <li key={tab.id} id={tab.id} className={classes}>
        <a onClick={this.tabClick}>{tab.value}</a>
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

  tabClick(e) {
    for (var tab of this.state.nav) {
      if (e.target.parentElement.id == tab.id) {
        this.state.active_component = tab.component;
        tab.active = true;
      }
      else {
        tab.active = false;
      }
    }
    this.setState(this.state);
  },

  getInitialState() {
    var socket = new Socket("/gaze/ws");
    socket.connect();

    return {
      nav: [
        {id: "nav_system",       value: "System",       component: System,  active: true},
        {id: "nav_load_charts",  value: "Load charts",  component: null,    active: false},
        {id: "nav_applications", value: "Applications", component: null,    active: false}
      ],
      active_component: System,
      socket: socket
    }
  }
});
