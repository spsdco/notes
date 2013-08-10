Spine = require 'spine'

# Models
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

  addOne: (notebook) =>
    @list.append @template notebook
    view = new NotebookItem
      el: @list.find("#notebook-#{ notebook.id }")
      notebook: notebook

  change: (obj) =>
    Notebook.current = obj

  new: (e) ->
    val = @input.val()
    if e.which is 13 and val
      # Make a new Notebook
      Notebook.create
        name: val
        categories: ["General"]
      @input.val ""

module.exports = Sidebar
