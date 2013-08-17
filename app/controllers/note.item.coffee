Spine = require 'spine'

# Models
Note = require '../models/note.coffee'

class NoteItem extends Spine.Controller

  elements:
    "h2": "title"
    "time": "time"
    "span": "excerpt"

  events:
    "click": "select"

  constructor: ->
    super
    @note.bind "changeNote", @changeNote
    @note.bind "change", @updateNote

  select: ->
    Note.trigger "changeNote", {id: @note.id}

  changeNote: =>
    @el.parent().find(".selected").removeClass("selected")
    @el.addClass("selected")

  updateNote: =>
    @title.text @note.name
    @time.text @note.prettyDate() + " -"
    @excerpt.text @note.excerpt


module.exports = NoteItem
