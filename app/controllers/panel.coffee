Spine = require 'spine'

# Node-Webkit. IMPORTANT NOTE: USE WINDOW.REQUIRE
win = window.require('nw.gui').Window.get() if window.require

# Models
Note = require("../models/note.coffee")
Notebook = require("../models/notebook.coffee")

class Panel extends Spine.Controller
  elements:
    "#noteControls": "noteControls"

  events:
    "click #decor img": "windowControl"
    "click #noteControls img": "noteControl"

  constructor: ->
    super
    Note.bind "changeNote", @toggle

  windowControl: (e) ->
    switch e.currentTarget.className
      when "close"
        win.close()
      when "minimize"
        win.minimize()
      when "maximize"
        win.maximize()

  noteControl: (e) ->
    switch e.currentTarget.id
      when "new"
        Note.create
          name: "Untitled Note"
          excerpt: "lorem ipsum dol el emit"
          notebook: Notebook.current.id
          category: if Notebook.current.category is "all" then Notebook.find(Notebook.current.id).categories[0] else Notebook.find(Notebook.current.id).categories[Notebook.current.category]
          date: Math.round(new Date().getTime()/1000)
      when "share"
        console.log("Sharing")
      when "del"
        console.log("Deleting")

  toggle: (note) =>
    if note isnt undefined
      @noteControls.removeClass("disabled")
    else
      @noteControls.addClass("disabled")


module.exports = Panel
