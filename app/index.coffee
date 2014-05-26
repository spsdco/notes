require './lib/setup.coffee'
Spine = require 'spine'

shell = window.require('shell') if window.require
Analytics = require 'analytics-node'

# Upgrader
Upgrader = require('./controllers/upgrader.coffee')

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
Account = require './controllers/account.coffee'
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

    Account.enableChecks()
    Notebook.fetch()
    Note.fetch()

    anal = new Analytics('u9g1p9otaa')

    # We're nosey.
    anal.track({
      'userId': 'anonymous_user',
      'event': 'Open App',
      'properties': {
        'os': @getOS(),
        'version': localStorage.version
      }
    })

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
    new Upgrader()
    @panel = new Panel( el: @panel )
    @sidebar = new Sidebar( el: @sidebar )
    @browser = new Browser( el: @browser )
    @editor = new Editor( el: @editor )
    @popover = new Popover( el: @popoverMask )

    # We'll put the sync conenct here as well.
    Spine.trigger 'sync:authorized' if Sync.oauth.service != "undefined"
    Sync.anal()

    # Stuff for node webkit.
    $('a').on 'click', (e) ->
      e.preventDefault()
      if e.which is 1 or e.which is 2
        shell.openExternal $(@).attr("href")
      return false

    # Going to use this to enable the dev tools, because yolo
    # konami_keys = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65]
    # konami_index = 0
    # $(document).keydown (e) ->
    #   location.reload() if e.keyCode is 116
    #   if e.keyCode is konami_keys[konami_index++]
    #     if konami_index is konami_keys.length
    #       $(document).unbind "keydown", arguments.callee
    #       <nw require>.Window.get().showDevTools()
    #   else
    #     konami_index = 0

  # We're sending an event to the editor here because we need the checksel to be global
  checkSel: ->
    @editor.trigger("checkSel")

  getOS: ->
    ua = navigator.userAgent
    return "Linux" if ua.indexOf("Linux") > -1
    return "Mac OS X 10.9" if ua.indexOf("Mac OS X 10_9") > -1
    return "Mac OS X 10.8" if ua.indexOf("Mac OS X 10_8") > -1
    return "Mac OS X 10.7" if ua.indexOf("Mac OS X 10_7") > -1
    return "Mac OS X 10.6" if ua.indexOf("Mac OS X 10_6") > -1
    return "Windows XP" if ua.indexOf("Windows NT 6.2") > -1
    return "Windows Vista" if ua.indexOf("Windows NT 6") > -1
    return "Windows 7" if ua.indexOf("Windows NT 6.1") > -1
    return "Windows 8" if ua.indexOf("Windows NT 6.2") > -1
    return "Windows 8.1" if ua.indexOf("Windows NT 6.3") > -1

module.exports = App
