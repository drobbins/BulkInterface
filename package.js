Package.describe({
    name: "robbinsd:bulk-interface",
    version: "0.0.2",
    summary: "Create bulk-interface forms for quickly importing/exporting *SV data.",
    git: "https://github.com/drobbins/BulkInterface.git",
    documentation: "README.md"
});

Package.onUse(function(api) {
    api.versionsFrom("1.1.0.2");

    // Dependencies
    api.use([
        "standard-app-packages", // Contents: http://www.meteorpedia.com/read/standard-app-packages
        "blaze",
        "ui",
        "reactive-var",
        "reactive-dict",
        "coffeescript"
    ]);
    api.use("harrison:papa-parse@1.1.0");
    
    api.export("BulkInterface");

    // Common Files
    api.addFiles("common.coffee");

    // Server-only Files
    api.addFiles("server/bulk-interface.coffee", "server");

    // Client-only Files
    api.addFiles([
        "client/lib/jquery.dataTables.min.js",
        "client/lib/dataTables.bootstrap.css",
        "client/lib/dataTables.bootstrap.js",
        "client/bulk-interface-templates.html",
        "client/bulk-interface.css",
        "client/bulk-interface.coffee"
    ], "client");   
});