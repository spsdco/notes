Spine = require 'spine'

# Models
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'
Modal = require '../controllers/modal.coffee'
Settings = require '../controllers/settings.coffee'
Account = require '../controllers/account.coffee'

class Panel extends Spine.Controller
  elements:
    "#loginbox": "login"

  events:
    "dblclick": "maximize"
    "click #decor img": "windowControl"
    "keyup #search input": "search"
    "click #loginbox .name": "userSettings"

  maximized: false

  constructor: ->
    super
    Note.bind "changeNote", @toggleNote
    Notebook.bind "changeNotebook", @toggleNotebook
    # if win
    #   win.on 'maximize', =>
    #     @maximized = true
    #   win.on 'unmaximize', =>
    #     @maximized = false

    setInterval ->
      if Account.isSignedIn()
        $('#loginbox').find('.name').text(Account.get().first_name + " " + Account.get().last_name)
        if Account.get().pro
          $('#loginbox').find('.gopro').text('you\'re pro')
      else
        $('#loginbox').find('.name').text("log in")
        $('#loginbox').find('.gopro').text('go pro')
    ,100

    # Resizes the panel seperator
    browser = $("#browser")
    $(".splitter.split-right").on "mouseup", =>
      @noteControls.width((browser.width()-4))

  userSettings: (e) ->
    Settings.get().show("account")

  windowControl: (e) ->
    # switch e.currentTarget.className
    #   when "close"
    #     win.close()
    #   when "minimize"
    #     win.minimize()
    #   when "maximize"
    #     @maximize()

  maximize: ->
    win.maximize() if @maximized is false
    win.unmaximize() if @maximized is true

  toggleNote: (note) =>
    # if note isnt undefined
    #   @noteControls.removeClass "disabled"
    # else
    #   @noteControls.addClass "disabled"

  toggleNotebook: (notebook) =>
    # if notebook.id is "all"
    #   @noteControls.addClass "all"
    # else
    #   @noteControls.removeClass "all"

  search: (e) =>
    # This feels so ugly :/
    searchstring = $(e.target).val()
    Note.search(searchstring)

module.exports = Panel
