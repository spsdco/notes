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
    "dragstart": "startdrag"
    "dragend": "stopdrag"

  constructor: ->
    super
    @note.bind "changeNote", @changeNote
    @note.bind "change", @updateNote
    @note.bind "destroy", @deleteNote

  select: ->
    Note.trigger "changeNote", {id: @note.id}

  changeNote: =>
    @el.parent().find(".selected").removeClass("selected")
    @el.addClass("selected")

  updateNote: =>
    @title.text @note.name
    @time.text @note.prettyDate() + " -"
    @excerpt.text @note.excerpt

  deleteNote: =>
    @el.remove()

  startdrag: (e) =>
    @el.css {opacity: 0.4}

    noteid = $(e.target).attr('id').replace("note-", "")
    e.originalEvent.dataTransfer.setData('noteid', noteid)


  stopdrag: (e) =>
    @el.css {opacity: 1}


module.exports = NoteItem
