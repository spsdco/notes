Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

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

  addOne: (notebook) =>
    @list.append @template notebook
    console.log "new notebook w/ id: " + notebook

  new: (e) ->
    val = @input.val()
    if e.which is 13 and val
      # Make a new Notebook
      Notebook.create
        name: val
      @input.val ""

module.exports = Sidebar
