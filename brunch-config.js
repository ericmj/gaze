exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: 'js/app.js',
      order: {
        before: [
          /^bower_components/,
          /^web\/static\/vendor/
        ]
      }
    },
    stylesheets: {
      joinTo: 'css/app.css'
    },
    templates: {
      joinTo: 'js/app.js'
    }
  },

  conventions: {
    vendor: []
  },

  paths: {
    watched: ["web/static", "test/static"],
    public: "priv/static"
  }
};
