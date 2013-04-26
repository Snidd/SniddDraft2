Package.describe({
  summary: "Fetch from Gatherer"
});

Npm.depends({tutor: "0.3.6"},{fibers: "1.0.0"});

Package.on_use(function (api) {
  api.add_files("mtgtutor.js", "server");
});