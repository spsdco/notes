Spine = require 'spine'

# Node-Webkit. IMPORTANT NOTE: USE WINDOW.REQUIRE
win = window.require('nw.gui').Window.get() if window.require

# Models
Note = require("../models/note.coffee")
Notebook = require("../models/notebook.coffee")

# Controllers
Modal = require("./modal.coffee")
NoteItem = require("./note.item.coffee")

class Panel extends Spine.Controller

  noteTemplate: (->
    require '../views/note.js'
    Handlebars.templates['note']
  )()

  elements:
    "#noteControls": "noteControls"

  events:
    "click #decor img": "windowControl"
    "click #noteControls img": "noteControl"
    "keyup #search": "search"

  maximized: false

  constructor: ->
    super
    Note.bind "changeNote", @toggleNote
    Notebook.bind "changeNotebook", @toggleNotebook
    if win
      win.on 'maximize', =>
        @maximized = true
      win.on 'unmaximize', =>
        @maximized = false

  windowControl: (e) ->
    switch e.currentTarget.className
      when "close"
        win.close()
      when "minimize"
        win.minimize()
      when "maximize"
        win.maximize() if @maximized is false
        win.unmaximize() if @maximized is true

  noteControl: (e) ->
    switch e.currentTarget.id
      when "new"
        if Notebook.current.id isnt "all" or Notebook.current.id isnt "searches"

          # Create the note meta
          note = Note.create
            name: "Untitled Note"
            excerpt: "lorem ipsum dol el emit"
            notebook: Notebook.current.id
            category: if Notebook.current.category is "all" then Notebook.find(Notebook.current.id).categories[0] else Notebook.find(Notebook.current.id).categories[Notebook.current.category]
            date: Math.round(new Date().getTime()/1000)

          # Set the content with the special function
          note.saveNote("lorem ipsum dol el emit swag fagg yolo dog")
      when "share"
        console.log("Sharing")
      when "del"
        Modal.get("delete").run()

  toggleNote: (note) =>
    if note isnt undefined
      @noteControls.removeClass "disabled"
    else
      @noteControls.addClass "disabled"

  toggleNotebook: (notebook) =>
    if notebook.id is "all" or notebook.id is "searches"
      @noteControls.addClass "all"
    else
      @noteControls.removeClass "all"

  search: (e) ->
    console.log "Panel.search called"
    results = Note.search($(e.target).val())

    # This is ugly and hacky and shitty and fucking horrible as sin, but it works, I guess.
    # Also, I could not seemingly access the Browser object without it being itialised, and 
    # I don't know how to get it from index.coffee, so yeah.
    $('#sidebar ul').find('#notebook-searches').show().trigger('click')
    noteList = ''
    for result in results
      noteList += @noteTemplate result
      view = new NoteItem
        el: $('#browser ul').find("#note-#{ result.id }")
        note: result
    $('#browser ul').html(noteList)


module.exports = Panel
