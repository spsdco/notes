require './lib/setup.coffee'
Spine = require 'spine'

# Controllers
Panel = require './controllers/panel.coffee'

class App extends Spine.Controller
  elements:
    '#panel': 'panel'

  constructor: ->
    super
    @log "stargin"

    # Init Stuff
    @panel = new Panel( el: @panel )

module.exports = App

