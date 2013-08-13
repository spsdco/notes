Spine = require 'spine'

# Models
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'

# Controllers
NotebookItem = require './notebook.item.coffee'

class Sidebar extends Spine.Controller

  template: (->
    require '../views/notebook.js'
    Handlebars.templates['notebook']
  )()

  events:
    "keyup input": "new"

  elements:
    "ul": "list"
    "input": "input"

  constructor: ->
    super
    Notebook.bind "create", @addOne
    Notebook.bind "changeNotebook", @change
    Notebook.bind "refresh", @refresh

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
    # Called on load
    @log "HIH"

  new: (e) ->
    val = @input.val()
    if e.which is 13 and val
      # Make a new Notebook
      newNotebook = Notebook.create
        name: val
        categories: ["General"]

      # Select that notebook for opening
      Notebook.trigger "changeNotebook", {id: newNotebook.id, category: "all"}
      @input.val ""

module.exports = Sidebar
