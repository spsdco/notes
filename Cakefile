
Scrunch = require 'coffee-scrunch'
uglify  = require 'uglify-js'
server  = require 'node-static'
http    = require 'http'
fs      = require 'fs'
sass    = require 'node-sass'

# Configuration
config =
  port: 9294
  public: 'public'
  js:
    input:  'app/init.coffee'
    output: 'public/application.js'
    min:    'public/application.js'
  sass:
    input:  'css/index.scss'
    output: 'public/application.css'

# Options
option '-p', '--port [port]', 'Set port for cake server'
option '-w', '--watch', 'Watch the folder for changes'

compile =

  sass: ->
    sass.render {
      file: config.sass.input
      success: (css) ->
        fs.writeFile config.sass.output, css, (err) ->
          console.warn err if err
      error: (err) ->
        console.warn err if err
      outputStyle: 'compressed'
    }

  coffee: (options={}) ->

    scrunch = new Scrunch
      path: config.js.input
      compile: true
      verbose: true
      watch: options.watch

    scrunch.vent.on 'init', ->
      scrunch.scrunch()

    scrunch.vent.on 'scrunch', (data) ->
      console.log '[JS] Writing'
      fs.writeFile config.js.output, data

    scrunch.init()

  minify: ->
    js = uglify.minify(config.js.output).code
    fs.writeFile config.js.min, js


# ===============================================================
# Tasks
# ===============================================================

task 'server', 'Start server', (options) ->

  # Compile files
  compile.sass
  compile.coffee(options)

  # Start Server
  port = options.port or config.port
  file= new(server.Server)(config.public)
  server = http.createServer (req, res) ->
    req.addListener( 'end', ->
      file.serve(req, res)
    ).resume()
  server.listen(port)

  console.log 'Server started on ' + port

task 'build',  'Compile CoffeeScript', compile.coffee
task 'minify', 'Minify application.js', compile.minify
task 'style',  'Compile Stylesheets', compile.sass

