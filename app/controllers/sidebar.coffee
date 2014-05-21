Spine = require 'spine'

# Models
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'

# Controllers
NotebookItem = require './notebook.item.coffee'
Settings = require './settings.coffee'
Sync = require './sync.coffee'

class Sidebar extends Spine.Controller

  template: (->
    require '../views/notebook.js'
    Handlebars.templates['notebook']
  )()

  events:
    "keyup input": "new"
    "click #settings": "toggleSettings"
    "click #sync": "doSync"

  elements:
    "ul": "list"
    "input": "input"
    "#settings": "settings"
    "#sync": "sync"

  constructor: ->
    super
    Notebook.bind "create", @addOne
    Notebook.bind "changeNotebook", @change
    Notebook.bind "refresh", @refresh
    Notebook.bind "destroy", @destroy

    # Starts and stops the animation
    Spine.bind 'sync:start', =>
      @sync.addClass 'spin'
    Spine.bind 'sync:stop', =>
      @sync.removeClass 'spin'

  addOne: (notebook) =>
    @list.append @template notebook
    view = new NotebookItem
      el: @list.find("#notebook-#{ notebook.id }")
      notebook: notebook

  change: (notebook) =>
    # This is defined here, or some weird shit happens

    # Annoyingly, this is a two step process
    if Note.current
      if Note.current.persist
        setTimeout( =>
          Note.trigger "changeNote", Note.current
        , 100)
      else
        Note.trigger "changeNote"
    else
      Note.trigger "changeNote"

    Notebook.current = notebook

  refresh: () =>
    # Called on load from indexeddb
    html = @template {id: "all", name: "All Notes"}
    for notebook in Notebook.all()
      html += @template notebook
    @list.html(html)

    # Defers for speed
    window.requestAnimationFrame( =>
      # All Notes
      new NotebookItem
        el: @list.find("#notebook-all")
        notebook: {id: "all", name: "All Notes", categories: []}

      # Normal Notes
      for notebook in Notebook.all()
        view = new NotebookItem
          el: @list.find("#notebook-#{ notebook.id }")
          notebook: notebook

      # This feels so bad :(
      if Notebook.current
        Note.current.persist = true if Note.current
        # Doubley bad
        if Notebook.current.id is "all"
          $("#notebook-all").trigger("click")
        else
          Notebook.trigger('changeNotebook', Notebook.current)
      else
        $("#notebook-all").trigger("click")
    )

  destroy: ->
    # This is bad practice, but I knew this would happen.
    # We'll revamp it when we get Smart Lists
    $("#notebook-all").trigger("click")

  new: (e) ->
    val = @input.val()
    if e.which is 13 and val
      # Make a new Notebook
      newNotebook = Notebook.create
        name: val
        categories: ["General"]
        date: Math.round(new Date()/1000)

      # Select that notebook for opening
      Notebook.trigger "changeNotebook", {id: newNotebook.id, category: "all"}
      @input.val ""

  toggleSettings: (e) ->
    Settings.get().show("sync")

  doSync: ->
    if localStorage.oauth
      Sync.doSync()
    else
      @toggleSettings()

module.exports = Sidebar
