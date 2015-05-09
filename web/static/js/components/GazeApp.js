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
      return <li id={tab.id} className={classes}><a>{tab.value}</a></li>
    });
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
