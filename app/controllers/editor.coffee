Spine = require 'spine'

# Models
Note = require '../models/note.coffee'

class Editor extends Spine.Controller

  elements:
    ".headerwrap .left h1": "title"
    ".headerwrap .right time": "time"

  constructor: ->
    super
    Note.bind("changeNote", @enable)

  enable: (note) =>
    if note isnt undefined
      currentNote = Note.find(note.id)

      @el.removeClass("deselected")
      @title.text currentNote.name
      @time.text currentNote.prettyDate(true)
    else
      @el.addClass("deselected")

module.exports = Editor
