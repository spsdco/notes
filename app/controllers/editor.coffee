Spine = require 'spine'
marked = require 'marked'

# Models
Note = require '../models/note.coffee'

class Editor extends Spine.Controller

  elements:
    ".headerwrap .left input": "title"
    ".headerwrap .right time": "time"
    "#contentread": "contentread"
    "textarea": "contentwrite"
    ".headerwrap .edit": "toggle"
    "#focus": "focus"

  events:
    "click .headerwrap .edit": "toggleMode"

  constructor: ->
    super
    Note.bind("changeNote", @enable)

  enable: (note) =>
    # Put back into the right mode
    @toggleMode() if @mode is "edit"

    # Loads note
    Note.current = note
    if note isnt undefined
      currentNote = Note.find(note.id)

      @el.removeClass("deselected")
      @title.val currentNote.name
      @time.text currentNote.prettyDate(true)

      # Content
      currentNote.loadNote (content) =>
        @contentread.html marked(content)
        @contentwrite.val content
    else
      @el.addClass("deselected")

    @mode = "preview"

  toggleMode: ->
    if @mode is "preview" # enable the editor
      # UI bits and bobs
      @el.addClass("edit")
      @toggle.text("save")
      @title.prop "disabled", false
      @mode = "edit"

      # Focus the text area
      @contentwrite.focus()

    else # disable the editor
      # Copy the text in
      noteText = @contentwrite.val()
      @contentread.html marked(noteText)

      # Save it
      if Note.current isnt undefined
        currentNote = Note.find(Note.current.id)

        # Excerpts nicely
        info = noteText
        if info.length > 90
          info = info.substring(0, 100)
          lastIndex = info.lastIndexOf(" ")
          info = info.substring(0, lastIndex) + "&hellip;"
        info = $(marked(info)).text()
        info = info.split("\n").join(" ")

        # Update Spine
        currentNote.updateAttributes {
          "name": @title.val()
          "excerpt": info
          "date": Math.round(new Date()/1000)
        }

        # Update IndexedDB
        currentNote.saveNote(noteText)

      # The opposite
      @el.removeClass("edit")
      @toggle.text("edit")
      @title.prop "disabled", true
      @mode = "preview"

module.exports = Editor
