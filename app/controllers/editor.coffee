Spine = require 'spine'
marked = require 'marked'

# Models
Note = require '../models/note.coffee'

class Editor extends Spine.Controller

  elements:
    ".headerwrap .left h1": "title"
    ".headerwrap .right time": "time"
    "#contentread": "contentread"
    "textarea": "contentwrite"
    ".headerwrap .edit": "toggle"

  events:
    "click .headerwrap .edit": "toggleMode"

  constructor: ->
    super
    Note.bind("changeNote", @enable)

  enable: (note) =>
    if note isnt undefined
      currentNote = Note.find(note.id)

      @el.removeClass("deselected")
      @title.text currentNote.name
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
      @title.attr "contenteditable", "true"
      @mode = "edit"

      # Focus the text area
      @contentwrite.focus()

    else # disable the editor
      # Copy the text in
      noteText = @contentwrite.val()
      @contentread.html marked(noteText)

      # Save it
      currentNote = Note.find(Note.current.id)
      currentNote.updateAttribute("date", Math.round(new Date()/1000))
      currentNote.saveNote(noteText)

      # The opposite
      @el.removeClass("edit")
      @toggle.text("edit")
      @title.attr "contenteditable", "false"
      @mode = "preview"

module.exports = Editor
