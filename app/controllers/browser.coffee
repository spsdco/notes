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
    'span': 'title'

  events:
    'click #new': 'newNote'

  constructor: ->
    super
    Note.bind "create", @addOne
    Notebook.bind "changeNotebook", @changeNotebook

  addOne: (note) =>
    # We should always be in the right list, but doesn't hurt to check
    if typeof(Notebook.current) isnt "undefined"
      if note.notebook is Notebook.current.id and (Notebook.current.category is "all" or note.category is Notebook.find(Notebook.current.id).categories[Notebook.current.category])
        note.date = note.prettyDate()
        @noteBrowser.prepend @template note

        view = new NoteItem
          el: @noteBrowser.find("#note-#{ note.id }")
          note: note

  newNote: (e) =>
    if Notebook.current.id isnt "all"

          # Create the note meta
          note = Note.create
            name: "Untitled Note"
            starred: false
            excerpt: "This is your new blank note - add some content!"
            notebook: Notebook.current.id
            category: if Notebook.current.category is "all" then Notebook.find(Notebook.current.id).categories[0] else Notebook.find(Notebook.current.id).categories[Notebook.current.category]
            date: Math.round(new Date().getTime()/1000)

          # Set the content with the special function
          note.saveNote "# This is your new blank note\nAdd some content!", ->

            # Select it and throw it into editable mode
            note.trigger("changeNote")
            note.trigger("openNote")

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
      window.requestAnimationFrame( =>
        for note in Note.filter(Notebook.current.id, Notebook.current.category)
          view = new NoteItem
            el: @noteBrowser.find("#note-#{ note.id }")
            note: note
      )

module.exports = Browser
