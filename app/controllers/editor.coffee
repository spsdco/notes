Spine = require 'spine'
marked = require 'marked'
hljs = require 'highlight.js'

# Models
Note = require '../models/note.coffee'

# Controllers
window.Modal = require '../controllers/modal.coffee'

class Editor extends Spine.Controller

  elements:
    ".headerwrap .left input": "title"
    ".headerwrap .left time": "time"
    "#contentread": "contentread"
    "#contentwrite > .inner": "contentwrite"
    ".headerwrap .edit": "toggle"
    "#psuedoinput": "psuedoinput"
    ".headerwrap i.star": "star"

  events:
    "click .headerwrap .edit": "toggleMode"
    "click .headerwrap .revert": "revert"
    "keydown #contentwrite > .inner": "keydown"
    #"paste #contentwrite > .inner": "paste"
    "dblclick #contentread": "toggleMode"
    "click header .right .delete": "deleteNote"
    "click header .star": "starNote"
    "textInput section.inner": "inputHandler" # used for emojis
    "blur section.inner": "blurHandler" # again, used for emojis


  starNote: ->
    note = Note.find(Note.current.id)
    if note.starred is "true"
      note.updateAttribute("starred", "false")
      @star.addClass("fa-star-o")
      @star.removeClass("fa-star")
      @star.removeClass("starred")
    else
      note.updateAttribute("starred", "true")
      @star.removeClass("fa-star-o")
      @star.addClass("fa-star")
      @star.addClass("starred")

  deleteNote: (e) ->
    note = Note.find(Note.current.id)
    $(".delete-container span.name").text(note.name)
    Modal.get("delete").run()

  constructor: ->
    super
    Note.bind("changeNote", @enable)
    Note.bind "openNote", =>
      @toggleMode()
    Note.bind("revert", @revertNote)
    @.bind("checkSel", @checkSelWrap)

    emojify.setConfig {
      ignored_tags: {
        'CODE': 1
      }
    }
    marked.setOptions {
      highlight: (code, lang) ->
        try
          if lang
            return hljs.highlight(lang.toLowerCase(), code).value
          else
            return hljs.highlightAuto(code).value
        catch error
          code
      tables: true
      sanitize: true
      smartLists: true
      smartypants: true
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

      if currentNote.starred is "true"
        @star.attr('class', 'star fa fa-star starred')
      else
        @star.attr('class', 'star fa fa-star-o')

      # Content
      currentNote.loadNote (content) =>
        @contentread.html marked(content)
        @contentwrite.text content

        # this needs to be bound
        $('#contentread a').attr('target', '_blank').click ->
          return false
    else
      @el.addClass("deselected")


    setInterval(@wc, 1000)

    @mode = "preview"

  wc: ->
    text = $('#contentwrite section').text()
    wc = $(marked(text)).text().split(' ').length
    $('.wc').text(wc)


  toggleMode: (save) ->
    if @mode is "preview" # enable the editor
      # UI bits and bobs
      @el.addClass("edit")
      @toggle.find("i").addClass("fa-lock")
      @toggle.find("i").removeClass("fa-pencil")
      @toggle.find("i")[0].parentNode.title = "Preview Note"
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
        $('#contentread a').attr('target', '_blank').click ->
          return false

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
      @toggle.find("i").removeClass("fa-lock")
      @toggle.find("i").addClass("fa-pencil")
      @toggle.find("i")[0].parentNode.title = "Edit Note"
      @title.prop "disabled", true
      @mode = "preview"
      @time.text currentNote.prettyDate(true)

  revert: ->
    if @mode isnt "preview"
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
      #e.preventDefault()
      @insertText "\n"
    else if e.keyCode is 9 #tab
      e.preventDefault()
      @insertText "    "
    else if e.keyCode is 27 #escape key
      e.preventDefault()
      @toggleMode()

  #paste: (e) ->
  #  # Keeps the range for later
  #  @range = window.getSelection().getRangeAt(0)

  #  # Paste it into a textarea (removes formatting)
  #  #@psuedoinput.val("").focus()

  #  # As the paste event isn't instant, put it back in a few secs.
  #  setTimeout( =>
  #    s = window.getSelection()
  #    s.removeAllRanges()
  #    s.addRange(@range)

  #    @insertText @psuedoinput.val()
  #  , 10)

  checkSelWrap: ->
    setTimeout =>
      @checkSel()
    , 50

  checkSel: ->
    if @mode is "preview"
      @controls.hide()
    else
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

  newString: (str) ->
    @selrange.surroundContents(document.createElement("span"))
    text = @el.find("span").text()
    @el.find("span").text(str).contents().unwrap()

  formatBold: (e) =>
    str = @selrange.toString()
    if str.substring(0,2) is "**" and str.substring(str.length-2,str.length) is "**"
      @newString(str.substring(2,str.length-2))
    else
      @sel.collapseToStart()
      @sel.modify("move", "backward", "character")
      @sel.modify("move", "backward", "character")
      @sel.modify("extend", "forward", "word")
      @sel.modify("extend", "forward", "character")
      @sel.modify("extend", "forward", "character")
      @selrange = @sel.getRangeAt(0)
      str = @selrange.toString()

      if str.substring(0,2) is "**" and str.substring(str.length-2,str.length) is "**"
        @newString(str.substring(2,str.length-2))
      else
        @sel.collapseToStart()
        @sel.modify("move", "forward", "character")
        @sel.modify("move", "forward", "character")
        @sel.modify("extend", "forward", "word")
        @selrange = @sel.getRangeAt(0)
        str = @selrange.toString()
        @newString("**" + str + "**")

  formatItalics: (e) =>

    str = @selrange.toString()
    if str.substring(0,1) is "*" and str.substring(str.length-1,str.length) is "*"
      @newString(str.substring(1,str.length-1))
    else
      @sel.collapseToStart()
      @sel.modify("move", "backward", "character")
      @sel.modify("extend", "forward", "word")
      @sel.modify("extend", "forward", "character")
      @selrange = @sel.getRangeAt(0)
      str = @selrange.toString()

      if str.substring(0,1) is "*" and str.substring(str.length-1,str.length) is "*"
        @newString(str.substring(1,str.length-1))
      else
        @sel.collapseToStart()
        @sel.modify("move", "forward", "character")
        @sel.modify("extend", "forward", "word")
        @selrange = @sel.getRangeAt(0)
        str = @selrange.toString()
        @newString("*#{str}*")

  formatHead: (e) =>
    @sel.modify("extend", "backward", "paragraphboundary")
    @sel.modify("extend", "forward", "paragraphboundary")
    @selrange = @sel.getRangeAt(0)

    if @selrange.toString().substring(0,3) isnt "###"
      @selrange.surroundContents(document.createElement("span"))
      text = @el.find("span").text()
      @el.find("span").text("#"+text+"").contents().unwrap()
    else
      @selrange.surroundContents(document.createElement("span"))
      text = @el.find("span").text()
      @el.find("span").text(text.substring(3)).contents().unwrap()

  inputHandler: (e) ->
    # Handle Emoji creation
    if e.originalEvent.data == ":" # capture colon key
      setTimeout (->
        emojify.run() # ALL the emojis!
      ), 100


  blurHandler: (e) ->
    for i in $('section.inner img.emoji')
      $(i).replaceWith(i.title)


module.exports = Editor
