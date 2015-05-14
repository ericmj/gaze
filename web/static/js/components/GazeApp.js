import React from "bower_components/react/react";
import Reflux from "bower_components/reflux/dist/reflux";
import cx from "bower_components/classnames";
import System from "./System";
import Charts from "./Charts";
import Actions from "../actions";
import ChannelStore from "../stores/ChannelStore";

export default React.createClass({
  mixins: [Reflux.connect(ChannelStore, "store")],

  componentWillMount() {
    Actions.connect();
  },

  render() {
    return <div>
      {this.renderNav()}
      {this.renderContainer()}
    </div>;
  },

  renderNav() {
    return <div className="navbar navbar-default">
      <div className="container">
        <div className="navbar-header">
          <button type="button" className="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar-collapse">
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
          </button>
          <a className="navbar-brand" href="/gaze">Gaze</a>
        </div>

        <div className="collapse navbar-collapse" id="navbar-collapse">
          <ul className="nav navbar-nav">
            {this.renderNavs()}
          </ul>
        </div>
      </div>
    </div>;
  },

  renderConnectionStatus() {
    var label = this.state.store.connected
              ? <span className="label label-success pull-right">Connected</span>
              : <span className="label label-danger pull-right">Disconnected</span>;

    return <div><h4>{label}</h4></div>;
  },

  renderNavs() {
    return this.state.nav.map(nav => {
      var classes = cx({active: nav.active});
      return <li key={nav.id} id={nav.id} className={classes}>
        <a onClick={this.onTabClick}>{nav.value}</a>
      </li>;
    });
  },

  renderContainer() {
    var component = this.state.activeComponent
                  ? <this.state.activeComponent/>
                  : <div/>;

    return <div className="container">
      {component}
    </div>;
  },

  getInitialState() {
    return {
      nav: [
        {id: "nav_system",       value: "System",       component: System,  active: true},
        {id: "nav_load_charts",  value: "Load charts",  component: Charts,  active: false},
        {id: "nav_applications", value: "Applications", component: null,    active: false}
      ],
      activeComponent: System
    }
  },

  onTabClick(e) {
    var activeComponent;

    var nav = this.state.nav.map(tab => {
      if (e.target.parentElement.id == tab.id) {
        activeComponent = tab.component;
        tab.active = true;
      }
      else {
        tab.active = false;
      }
      return tab;
    });
    this.setState({nav, activeComponent});
  },
});
