Spine = require 'spine'

# Models
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'

# Controllers
NotebookItem = require './notebook.item.coffee'
Settings = require './settings.coffee'

class Sidebar extends Spine.Controller

  template: (->
    require '../views/notebook.js'
    Handlebars.templates['notebook']
  )()

  events:
    "keyup input": "new"
    "click #settings": "toggleSettings"

  elements:
    "ul": "list"
    "input": "input"
    "#settings": "settings"

  constructor: ->
    super
    Notebook.bind "create", @addOne
    Notebook.bind "changeNotebook", @change
    Notebook.bind "refresh", @refresh
    Notebook.bind "destroy", @destroy

  addOne: (notebook) =>
    @list.append @template notebook
    view = new NotebookItem
      el: @list.find("#notebook-#{ notebook.id }")
      notebook: notebook

  change: (notebook) =>
    # This is defined here, or some weird shit happens
    Note.trigger "changeNote"
    Notebook.current = notebook

  refresh: () =>
    # Called on load from indexeddb
    html = @template {id: "all", name: "All Notes"}
    for notebook in Notebook.all()
      html += @template notebook
    @list.html(html)

    # Defers for speed
    setTimeout( =>
      # All Notes
      new NotebookItem
        el: @list.find("#notebook-all")
        notebook: {id: "all", name: "All Notes", categories: []}
      # This feels so bad :(
      $("#notebook-all").trigger("click")

      # Normal Notes
      for notebook in Notebook.all()
        view = new NotebookItem
          el: @list.find("#notebook-#{ notebook.id }")
          notebook: notebook
    , 100)

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
    Settings.get().show()

module.exports = Sidebar
