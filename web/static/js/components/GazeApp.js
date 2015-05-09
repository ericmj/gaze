import cx from "bower_components/classnames";

export default React.createClass({
  render() {
    return this.renderNav();
  },

  renderNav() {
    return <ul className="nav nav-tabs">
      {this.renderTabs()}
    </ul>;
  },

  renderTabs() {
    return this.state.nav.map(tab => {
      var classes = cx({active: tab.active});
      return <li id={tab.id} className={classes}>
        <a onClick={this.tabClick}>{tab.value}</a>
      </li>;
    });
  },

  tabClick(e) {
    for (var tab of this.state.nav) {
      if (e.target.parentElement.id == tab.id)
        tab.active = true;
      else
        tab.active = false;
    }
    this.setState(this.state);
  },

  getInitialState() {
    return {
      nav: [
        {id: "nav_system", value: "System", active: true},
        {id: "nav_load_charts", value: "Load charts", active: false},
        {id: "nav_applications", value: "Applications", active: false}
      ]
    }
  }
});
