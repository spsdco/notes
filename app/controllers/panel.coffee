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
