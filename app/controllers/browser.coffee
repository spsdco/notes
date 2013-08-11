Spine = require 'spine'

# Models
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'

class Browser extends Spine.Controller

  template: (->
    require '../views/note.js'
    Handlebars.templates['note']
  )()

  elements:
    'ul': 'noteBrowser'

  constructor: ->
    super
    Note.bind "create", @addOne
    Notebook.bind "changeNotebook", @change

  addOne: (note) =>
    # We should always be in the right list, but doesn't hurt to check
    if note.notebook is Notebook.current.id and (Notebook.current.category is "all" or note.category is Notebook.find(Notebook.current.id).categories[Notebook.current.category])
      note.date = note.prettyDate()
      @noteBrowser.prepend @template note

  change: =>
    noteList = ""
    for note in Note.filter(Notebook.current.id, Notebook.current.category)
      note.date = note.prettyDate()
      noteList += @template note

    @noteBrowser.html(noteList)

module.exports = Browser
