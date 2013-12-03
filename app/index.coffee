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
Browser = require './controllers/browser.coffee'
Editor = require './controllers/editor.coffee'
Popover = require './controllers/popover.coffee'
Modal = require './controllers/modal.coffee'
Settings = require './controllers/settings.coffee'

class App extends Spine.Controller
  elements:
    '#panel': 'panel'
    '#sidebar': 'sidebar'
    '#browser': 'browser'
    '#editor': 'editor'
    '.popover-mask': 'popoverMask'
    '.modal.preferences': 'settings'

  events:
    'mousedown': 'checkSel'
    'mouseup': 'checkSel'

  constructor: ->
    super

    Notebook.fetch()
    Note.fetch()

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
          el: $("#browser")[0]
          min: 250
          width: 300
          max: 850
        right:
          el: $("#editor")[0]
          min: 450
          width: 550
          max: Infinity

    Modal.init()

    Settings.init()

    @settings = Settings.get()

    # Init Stuff
    @panel = new Panel( el: @panel )
    @sidebar = new Sidebar( el: @sidebar )
    @browser = new Browser( el: @browser )
    @editor = new Editor( el: @editor )
    @popover = new Popover( el: @popoverMask )

  # We're sending an event to the editor here because we need the checksel to be global
  checkSel: ->
    @editor.trigger("checkSel")

module.exports = App
