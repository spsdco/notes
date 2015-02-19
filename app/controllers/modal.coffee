Spine = require 'spine'
$ = Spine.$

# Needed.
Note = require '../models/note.coffee'
Notebook = require '../models/notebook.coffee'

# Base Modal Class.
class Modal extends Spine.Controller
  constructor: (opts) ->
    super

    # Probably shouldn't be in here, but whatever
    Spine.bind 'sync:meta', =>
      modals['syncmeta'].run()

  state: off

  show: ->
    return unless @state is off
    @state = on
    @el.show(0).addClass 'show'
    if @onShow then @onShow()
    setTimeout ( =>
      @el.on "click.modal", (event) =>
        if event.target.className.indexOf('modals') > -1
          @hide()
    ), 500


  hide: ->
    return unless @state is on
    @state = off
    @el.removeClass 'show'
    setTimeout ( =>
      @el.hide(0)
      if @onHide then @onHide()
    ), 350
    @el.off 'click.modal'

modals = []

module.exports =

  get: (name) ->
    # Return a Modal object. Like a pro.
    return modals[name]

  init: ->
    # Do init stuff here.
    # Like, uh, getting modals sorted. Yolo.
    modals['delete'] = new Modal
      el: $('.modal.delete')
      events:
        'click .true': 'delete'
        'click .false': 'hide'

      run: ->
        @show()

      delete: ->
        # Taken from controllers/panel.coffee.
        if Note.current isnt undefined
          currentNote = Note.find(Note.current.id)

          # Take it out of editmode
          Note.trigger 'changeNote'
          currentNote.destroy()

          @hide()
    
	modals['newNote'] = new Modal
	  el: $('.newNote')
	  events:
	    'click .gotit': 'hide'
	  run: ->
	    @show()

    modals['revert'] = new Modal
      el: $('.modal.revert')
      events:
        'click .true': 'revert'
        'click .false': 'hide'

      run: ->
        @show()

      revert: ->
        Note.trigger 'revert'
        @hide()

    modals['syncmeta'] = new Modal
      el: $('.modal.syncmeta')
      events:
        'click .destroyclient': 'destroyclient'
        'click .destroyserver': 'destroyserver'

      destroyclient: ->
        Sync.firstSync("destroyclient")
        @hide()

      destroyserver: ->
        Sync.firstSync("destroyserver")
        @hide()

      run: ->
        @show()

    modals['deleteNotebook'] = new Modal
      el: $('.modal.deleteNotebook')
      events:
        'click .true': 'delete'
        'click .false': 'hide'

      run: (notebookid, @category) ->
        @notebook = Notebook.find(notebookid)
        if @category is "all"
          @el.find('.type').text "Notebook"
          @el.find('i').text @notebook.name
        else
          @el.find('.type').text "Subcategory"
          @el.find('i').text @notebook.categories[@category]

        @show()

      delete: ->
        Note.trigger 'changeNote'
        if @category is "all"
          @notebook.destroy()
        else
          @notebook.subcategoryDestroy(@category)
        @hide()

    modals['renameNotebook'] = new Modal
      el: $('.modal.renameNotebook')
      events:
        'click .true': 'rename'
        'click .false': 'hide'

      run: (@notebookid, @category) ->
        # Subcategories need a proper lookup
        input = @el.find('input')
        if @category is 'all'
          input.val(Notebook.find(@notebookid).name)
        else
          input.val(Notebook.find(@notebookid).categories[@category])
        @show()

      rename: ->
        # Backslashes only seem to be an issue here
        input = @el.find('input').val()
        input = input.replace(/\\/g, '')
        notebook = Notebook.find(@notebookid)

        # Check for Empty String
        if input isnt ''
          if @category is 'all'
            notebook.updateAttribute 'name', input
          else
            # Subcategories need to be cloned then updated
            # Also, I wish there was a better way to do pointers.
            arr = notebook.categories.slice(0)
            arr[@category] = input
            notebook.updateAttribute 'categories', arr

          Notebook.trigger 'refresh'
        @hide()

    modals['pleaseLogIn'] = new Modal
      el: $('.modal.pleaseLogIn')
      events:
        'click .false': 'hide'

      hide: ->
        @hide()
