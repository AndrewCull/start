"use strict"
LIVERELOAD_PORT = 35728
lrSnippet = require("connect-livereload")(port: LIVERELOAD_PORT)
mountFolder = (connect, dir) ->
  connect.static require("path").resolve(dir)

module.exports = (grunt) ->

  # Load all grunt tasks
  matchdep = require("matchdep")
  matchdep.filterDev("grunt-*").forEach grunt.loadNpmTasks

  # Configurable paths
  coreConfig =
    pkg: grunt.file.readJSON("package.json")
    app: "app"
    dist: "dist"
    banner: do ->
      banner = "/*!\n"
      banner += " * (c) <%= core.pkg.author %>.\n *\n"
      banner += " * <%= core.pkg.name %> - v<%= core.pkg.version %> (<%= grunt.template.today('mm-dd-yyyy') %>)\n"
      banner += " * <%= core.pkg.homepage %>\n"
      banner += " * <%= core.pkg.license.type %> - <%= core.pkg.license.url %>\n"
      banner += " */"
      banner

  # Project configurations
  grunt.initConfig
    core: coreConfig

    coffeelint:
      options:
        indentation: 2
        no_stand_alone_at:
          level: "error"
        no_empty_param_list:
          level: "error"
        max_line_length:
          level: "ignore"

      test:
        files:
          src: ["Gruntfile.coffee"]

    recess:
      test:
        files:
          src: ["<%= core.app %>/assets/less/main.less"]

    connect:
      options:
        port: 9000

        # change this to "0.0.0.0" to access the server from outside
        hostname: "0.0.0.0"

      livereload:
        options:
          middleware: (connect) ->
            [lrSnippet, mountFolder(connect, ".tmp"), mountFolder(connect, coreConfig.app)]

      test:
        options:
          middleware: (connect) ->
            [mountFolder(connect, ".tmp"), mountFolder(connect, "test")]

      dist:
        options:
          middleware: (connect) ->
            [mountFolder(connect, coreConfig.dist)]

    watch:
      coffee:
        files: ["<%= coffeelint.test.files.src %>"]
        tasks: ["coffeelint"]

      less:
        files: ["<%= recess.test.files.src %>"]
        tasks: ["less:server", "recess"]

      livereload:
        options:
          livereload: LIVERELOAD_PORT

        files: ["<%= core.app %>/*.html", "{.tmp,<%= core.app %>}/assets/css/{,*/}*.css", "{.tmp,<%= core.app %>}/assets/js/{,*/}*.js", "<%= core.app %>/assets/img/{,*/}*.{png,jpg,jpeg,gif,webp,svg}"]

    less:
      server:
        options:
          paths: ["<%= core.app %>"]
          dumpLineNumbers: "all"

        files:
          ".tmp/assets/css/main.css": ["<%= core.app %>/assets/less/main.less"]

      dist:
        options:
          paths: ["<%= core.app %>"]

        files:
          "<%= core.dist %>/assets/css/main.css": ["<%= core.app %>/assets/less/main.less"]

    htmlmin:
      dist:
        options:
          removeComments: true
          removeCommentsFromCDATA: true
          removeCDATASectionsFromCDATA: true
          collapseWhitespace: true
          collapseBooleanAttributes: true
          removeAttributeQuotes: true
          removeRedundantAttributes: true
          useShortDoctype: false
          removeEmptyAttributes: true
          removeOptionalTags: false
          removeEmptyElements: false

        files: [
          expand: true
          cwd: "<%= core.app %>"
          src: "**/*.html"
          dest: "<%= core.dist %>/"
        ]

    cssmin:
      dist:
        options:
          banner: "<%= core.banner %>"
          report: "gzip"

        files:
          "<%= core.dist %>/assets/css/main.css": ["<%= core.dist %>/assets/css/main.css"]

    uglify:
      dist:
        options:
          banner: "<%= core.banner %>"
          report: "gzip"

        files:
          "<%= core.dist %>/assets/js/main.js": ["<%= core.app %>/assets/js/main.js"]

    copy:
      sync:
        files: [
          expand: true
          dot: true
          cwd: "<%= core.dist %>/"
          src: ["**"]
          dest: "/Users/sparanoid/Dropbox/Sites/sparanoid.com/lab/<%= core.pkg.name %>/"
        ]

    clean:
      dist:
        files: [
          dot: true
          src: [".tmp", "<%= core.dist %>/*"]
        ]

      sync:
        options:
          force: true

        files: [
          src: "/Users/sparanoid/Dropbox/Sites/sparanoid.com/lab/<%= core.pkg.name %>/"
        ]

    concurrent:
      options:
        logConcurrentOutput: true

      server:
        tasks: ["less:server"]

      dist:
        tasks: ["htmlmin", "cssmin", "uglify"]

  grunt.registerTask "server", ["connect:livereload", "concurrent:server", "watch"]
  grunt.registerTask "test", ["coffeelint", "recess"]
  grunt.registerTask "build", ["clean:dist", "test", "less:dist", "concurrent:dist"]
  grunt.registerTask "sync", ["build", "clean:sync", "copy:sync"]
  grunt.registerTask "default", ["build"]
