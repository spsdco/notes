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
    "dblclick": "maximize"
    "click #decor img": "windowControl"
    "click #noteControls img": "noteControl"
    "keyup #search input": "search"

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

    # Resizes the panel seperator
    browser = $("#browser")
    $(".splitter.split-right").on "mouseup", =>
      @noteControls.width((browser.width()-4))

  windowControl: (e) ->
    switch e.currentTarget.className
      when "close"
        win.close()
      when "minimize"
        win.minimize()
      when "maximize"
        @maximize()

  maximize: ->
    win.maximize() if @maximized is false
    win.unmaximize() if @maximized is true

  noteControl: (e) ->
    switch e.currentTarget.id
      when "new"
        if Notebook.current.id isnt "all"

          # Create the note meta
          note = Note.create
            name: "Untitled Note"
            excerpt: "This is your new blank note - add some content!"
            notebook: Notebook.current.id
            category: if Notebook.current.category is "all" then Notebook.find(Notebook.current.id).categories[0] else Notebook.find(Notebook.current.id).categories[Notebook.current.category]
            date: Math.round(new Date().getTime()/1000)

          # Set the content with the special function
          note.saveNote "# This is your new blank note\nAdd some content!", ->

            # Select it and throw it into editable mode
            note.trigger("changeNote")
            note.trigger("openNote")

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

module.exports = Panel
