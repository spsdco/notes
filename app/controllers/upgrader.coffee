###############
# If you're reading this code, and you're like
# ERMAGERD, WHY IS THIS IDIOT USING NODE.JS, S`NOT EVEN ASYNC!!11!!
# Well, it's because Spine doesn't work too well when it's async.
# Not sure why, it just loves to run out of memory and crash.
###############
Spine = require 'spine'
marked = require 'marked'

Note = require("../models/note.coffee")
Notebook = require("../models/notebook.coffee")

class window.upgrader extends Spine.Controller
  constructor: ->
    super

    notebookPromise = new $.Deferred()
    notePromise = new $.Deferred()

    Spine.bind "Notebook:ready", notebookPromise.resolve
    Spine.bind "Note:ready", notePromise.resolve

    $.when.apply($, [notebookPromise.promise(), notePromise.promise()]).then =>
      @upgrade(localStorage.version)
      localStorage.version = "2.0"

  upgrade: (version) ->
    # New install, add default notes
    if version is undefined
      for notebook in ['Personal', 'Scrap', 'Work']
        Notebook.create
          name: notebook
          attributes: {starred: false}
          categories: ["General"]
          date: Math.round(new Date()/1000)

      # Semi Ajaxed in, rather than hardcoded.
      $.getJSON('default.json').done (data) ->
        for defaultNote in data
          note = Note.create
            name: defaultNote.name
            excerpt: defaultNote.content.substring(0, 100)
            notebook: 'c-2'
            category: 'General'
            date: Math.round(new Date().getTime()/1000)
          note.saveNote defaultNote.content

        # For whatever reason, it doesn't reload afterwards?
        $("#notebook-all").trigger("click")

    else if version is "1.1"
      console.log "Upgrading DB"
      for note in Note.toJSON()
        note = Note.create
          name: note.name
          starred: false
          categories: note.categories
          date: note.date
        Note.find(note.id).destroy()

      $.getJSON('default.json').done (data) ->
        for defaultNote in data
          note = Note.create
            name: defaultNote.name
            excerpt: defaultNote.content.substring(0, 100)
            notebook: 'c-2'
            category: 'General'
            date: Math.round(new Date().getTime()/1000)
          note.saveNote defaultNote.content

        # For whatever reason, it doesn't reload afterwards?
        $("#notebook-all").trigger("click")

    else if version is "1.0"
      path = window.require 'path'
      fs = window.require 'fs'

      # Make variables. Do checks.
      homedir = window.process.env.HOME

      # Set up where we're going to store stuff.
      if window.process.platform is 'darwin'
        storagedir = path.join(homedir, "/Library/Application Support/Springseed/")
      else if window.process.platform is 'win32'
        storagedir = path.join(process.env.LOCALAPPDATA, "/Springseed/")
      else if window.process.platform is 'linux'
        storagedir = path.join(homedir, '/.config/Springseed/')

      notebookdir = path.join(storagedir, 'Notebooks')
      notebooks = {}

      files = fs.readdirSync notebookdir
      files.forEach (file) =>
        if file.substr(16,5) is ".list"

          # Read the file, syncronously.
          data = fs.readFileSync path.join(notebookdir, file)
          console.log data.toString()

          # Read the old notebook, create a new spine model
          try
            oldnotebook = JSON.parse(data)
            newNotebook = Notebook.create
              name: oldnotebook.name
              categories: ["General"]
              date: Math.round(new Date()/1000)
            # Our mapping array to show the new positions
            notebooks[oldnotebook.id] = newNotebook.id
          catch error
            console.log("there was an error", id)
            # Eh, what can we do?
            return

      # Load the notes from the notebook into the model
      files.forEach (file) =>
        if file.substr(33,5) is ".note"
          raw = fs.readFileSync path.join(notebookdir, file)
          try
            contents = JSON.parse(raw)
            contents.notebook = notebooks[contents.notebook]
          catch error
            contents = {
              name: "Untitled Note"
              content: raw.toString()
              date: Math.round(new Date()/1000)
              notebook: Notebook.all()[0].id
            }

          note = Note.create
            name: contents.name
            excerpt: $(marked(contents.content.substring(0,100))).text()
            notebook: contents.notebook
            category: "General"
            date: contents.date
          note.saveNote(contents.content)

module.exports = upgrader
