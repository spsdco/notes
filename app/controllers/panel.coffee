Spine = require 'spine'

# Node-Webkit. IMPORTANT NOTE: USE WINDOW.REQUIRE
win = window.require('nw.gui').Window.get() if window.require

# Models
Note = require("../models/note.coffee")
Notebook = require("../models/notebook.coffee")
Modal = require("../controllers/modal.coffee")

class Panel extends Spine.Controller
  elements:
    "#noteControls": "noteControls"

  events:
    "click #decor img": "windowControl"
    "click #noteControls img": "noteControl"
    "keyup #search input": "search"
    "mouseenter": "enter"
    "mouseleave": "leave"
    "mouseenter img": "leave"
    "mouseleave img": "enter"

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
        if Notebook.current.id isnt "all"

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
    if notebook.id is "all"
      @noteControls.addClass "all"
    else
      @noteControls.removeClass "all"

  search: (e) =>
    # This feels so ugly :/
    searchstring = $(e.target).val()
    Note.search(searchstring)

  enter: (e) =>
    @el.addClass('drag')

  leave: (e) =>
    @el.removeClass('drag')

module.exports = Panel
