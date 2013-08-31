Spine = require 'spine'

# Models
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'

# Controllers
NoteItem = require '../controllers/note.item.coffee'

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
    Notebook.bind "changeNotebook", @changeNotebook

  addOne: (note) =>
    # We should always be in the right list, but doesn't hurt to check
    if note.notebook is Notebook.current.id and (Notebook.current.category is "all" or note.category is Notebook.find(Notebook.current.id).categories[Notebook.current.category])
      note.date = note.prettyDate()
      @noteBrowser.prepend @template note

      view = new NoteItem
        el: @noteBrowser.find("#note-#{ note.id }")
        note: note

  changeNotebook: (notebook) =>
    dateSort = (a, b) ->
      return b.date - a.date
    
    if notebook.search is true or notebook.search is not undefined
      noteList = ""
      for note in notebook.result
        note.date = note.prettyDate
        noteList += @template note

      @noteBrowser.html noteList

    else
      noteList = ""
      for note in Note.filter(Notebook.current.id, Notebook.current.category).sort(dateSort)
        note.date = note.prettyDate()
        noteList += @template note

      @noteBrowser.html(noteList)

      # Defers for speed
      setTimeout( =>
        for note in Note.filter(Notebook.current.id, Notebook.current.category)
          view = new NoteItem
            el: @noteBrowser.find("#note-#{ note.id }")
            note: note
      , 100)

module.exports = Browser
