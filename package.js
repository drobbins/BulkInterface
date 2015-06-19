Package.describe({
    name: "robbinsd:bulk-interface",
    version: "0.0.2",
    summary: "Create bulk-interface forms for quickly importing/exporting *SV data.",
    git: "https://github.com/drobbins/BulkInterface.git",
    documentation: "README.md"
});

Package.onUse(function(api) {
    api.versionsFrom("1.1.0.2");
    api.use("coffeescript");
    api.use(["standard-app-packages", "templating", "blaze", "ui", "reactive-var", "reactive-dict"]);
    api.use("harrison:papa-parse@1.1.0");
    if (api.export) api.export("BulkInterface");
    api.addFiles(["bulk-interface-templates.html", "bulk-interface.css"], "client");
    api.addFiles(["lib/jquery.dataTables.min.js", "lib/dataTables.bootstrap.css", "lib/dataTables.bootstrap.js"], "client")
    api.addFiles("bulk-interface.coffee");
});