import Reflux from "bower_components/reflux/dist/reflux";
import cx from "bower_components/classnames";
import System from "./System";
import Actions from "../actions";
import ChannelStore from "../stores/ChannelStore";

export default React.createClass({
  mixins: [Reflux.connect(ChannelStore, "store")],

  componentWillMount() {
    Actions.connect();
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
    var label = this.state.store.connected
              ? <span className="label label-success pull-right">Connected</span>
              : <span className="label label-danger pull-right">Disconnected</span>;

    return <div><h4>{label}</h4></div>;
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
    var component = this.state.activeComponent
                  ? <this.state.activeComponent/>
                  : <div/>;

    return <div className="container main">
      {component}
    </div>;
  },

  getInitialState() {
    return {
      nav: [
        {id: "nav_system",       value: "System",       component: System,  active: true},
        {id: "nav_load_charts",  value: "Load charts",  component: null,    active: false},
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
