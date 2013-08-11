Spine = require 'spine'

# Models
Note = require '../models/note.coffee'

class NoteItem extends Spine.Controller

  events:
    "click": "select"

  constructor: ->
    super
    @note.bind "changeNote", @changeNote

  select: ->
    Note.trigger "changeNote", {id: @note.id}

  changeNote: =>
    @el.parent().find(".selected").removeClass("selected")
    @el.addClass("selected")

module.exports = NoteItem
