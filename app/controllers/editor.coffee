Spine = require 'spine'
marked = require 'marked'
hljs = require ("highlight.js")

# Models
Note = require '../models/note.coffee'

# Controllers
window.Modal = require '../controllers/modal.coffee'

class Editor extends Spine.Controller

  elements:
    ".headerwrap .left input": "title"
    ".headerwrap .right time": "time"
    "#contentread": "contentread"
    "#contentwrite > .inner": "contentwrite"
    ".headerwrap .edit": "toggle"
    "#psuedoinput": "psuedoinput"

  events:
    "click .headerwrap .edit": "toggleMode"
    "click .headerwrap .revert": "revert"
    "keydown #contentwrite > .inner": "keydown"
    "paste #contentwrite > .inner": "paste"
    "dblclick #contentread": "toggleMode"

  constructor: ->
    super
    Note.bind("changeNote", @enable)
    Note.bind("revert", @revertNote)
    @.bind("checkSel", @checkSelWrap)

    aliases = { 'js' : 'javascript', 'py': 'python', 'coffee', 'coffeescript' }
    marked.setOptions {
      highlight: (code, lang) ->
        hljs.highlight(aliases[lang.toLowerCase()] || lang.toLowerCase() || null, code).value
    }
    @controls = $("#editorcontrols")
    @controls.find('#bold').click @formatBold
    @controls.find('#italics').click @formatItalics
    @controls.find('#heading').click @formatHead

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
        @contentwrite.text content
    else
      @el.addClass("deselected")

    @mode = "preview"

  toggleMode: (save) ->
    if @mode is "preview" # enable the editor
      # UI bits and bobs
      @el.addClass("edit")
      @toggle.text("save")
      @title.prop "disabled", false
      @mode = "edit"

      # Focus the text area
      @contentwrite.focus()

    else # disable the editor
      if save is false and Note.current isnt undefined # We're not saving the content (revert button)
        currentNote = Note.find(Note.current.id)
        currentNote.loadNote (content) =>
          @contentwrite.text content
      else
        @controls.hide()
        # Copy the text in
        noteText = @contentwrite.text()
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
      @time.text currentNote.prettyDate(true)

  revert: ->
    Modal.get('revert').run()

  revertNote: =>
    @toggleMode(false)

  # Pops the text into the contenteditable
  insertText: (text) ->
    sel = window.getSelection()
    range = sel.getRangeAt(0)
    range.deleteContents()
    textNode = document.createTextNode(text)
    range.insertNode(textNode)
    range.setStartAfter(textNode)
    sel.removeAllRanges()
    sel.addRange(range)

  keydown: (e) ->
    # Some keys are special
    if e.keyCode is 13 #return
      e.preventDefault()
      @insertText "\n"
    else if e.keyCode is 9 #tab
      e.preventDefault()
      @insertText "    "

  paste: (e) ->
    # Keeps the range for later
    @range = window.getSelection().getRangeAt(0)

    # Paste it into a textarea (removes formatting)
    @psuedoinput.val("").focus()

    # As the paste event isn't instant, put it back in a few secs.
    setTimeout( =>
      s = window.getSelection()
      s.removeAllRanges()
      s.addRange(@range)

      @insertText @psuedoinput.val()
    , 10)

  checkSelWrap: ->
    setTimeout =>
      @checkSel()
    , 50

  checkSel: ->
    sel = window.getSelection()
    if sel.toString().trim() is ''
      @controls.hide()
    else
      @sel = sel
      @selrange = sel.getRangeAt(0)
      @controls.show()
      toppos = @selrange.getBoundingClientRect().top - 55 - @controls.height() + 'px'
      leftpos = @selrange.getBoundingClientRect().right - (@controls.width() / 2) + 'px'
      @controls.css {top: toppos, left: leftpos}

  formatBold: (e) =>
    @selrange.surroundContents(document.createElement("span"))
    text = @el.find("span").text()
    @el.find("span").text("**"+text+"**").contents().unwrap()

  formatItalics: (e) =>
    @selrange.surroundContents(document.createElement("span"))
    text = @el.find("span").text()
    @el.find("span").text("*"+text+"*").contents().unwrap()

  formatHead: (e) =>
    console.log @selrange.toString().substring(0,3)
    if @selrange.toString().substring(0,3) isnt "###"
      @selrange.surroundContents(document.createElement("span"))
      text = @el.find("span").text()
      @el.find("span").text("#"+text+"").contents().unwrap()
    else
      @selrange.surroundContents(document.createElement("span"))
      text = @el.find("span").text()
      @el.find("span").text(text.substring(3)).contents().unwrap()

module.exports = Editor
