require './lib/setup.coffee'
Spine = require 'spine'

# Splitter. Not working in setup for whatever reason.
Splitter = require('./lib/splitter.js')

# Modals
Notebook = require './models/notebook.coffee'
Note = require './models/note.coffee'

# Controllers
Panel = require './controllers/panel.coffee'
Sidebar = require './controllers/sidebar.coffee'

class App extends Spine.Controller
  elements:
    '#panel': 'panel'
    '#sidebar': 'sidebar'

  constructor: ->
    super

    # Init the Splitter so we can see crap.
    Splitter.init
      parent: $('#parent')[0],
      panels:
        left:
          el: $("#sidebar")[0]
          min: 150
          width: 200
          max: 450
        center:
          el: $("#notes")[0]
          min: 250
          width: 300
          max: 850
        right:
          el: $("#content")[0]
          min: 450
          width: 550
          max: Infinity

    # Init Stuff
    @panel = new Panel( el: @panel )
    @sidebar = new Sidebar( el: @sidebar )

module.exports = App

