Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

Modal = require './modal.coffee'

class Popover extends Spine.Controller

  elements:
    ".category-popover": "categoryPopover"
    ".category-popover input": "categoryInput"
    ".delete-popover": "delpopover"

  events:
    "click": "hidePopover"
    "contextmenu": "hidePopover"
    "click .category-popover button": "addCategory"
    "keyup .category-popover input": "addCategory"
    "click .delete-popover #deleteNotebook": "deleteNotebook"
    "click .delete-popover #renameNotebook": "renameNotebook"


  constructor: ->
    super

  hidePopover: (e) ->
    # Not sure where to put this, but it is global
    e.preventDefault()
    @el.hide().children().hide() if $(e.target)[0].nodeName isnt "INPUT"

  addCategory: (e) ->
    if e.type is "keyup" and e.which is 13 or e.type is "click"
      # adds the new category on
      notebook = Notebook.find(Notebook.current.id)
      cat = notebook.categories
      cat.push(@categoryInput.val())
      notebook.updateAttribute("categories", cat)

      @el.hide()

  renameNotebook: (e) =>
    # All renaming gets implemented in modal.coffee
    notebookid = @delpopover.attr('current-notebook')
    Modal.get('renameNotebook').run(notebookid)

  deleteNotebook: (e) =>
    # All deletion gets implemented in modal.coffee
    Modal.get('deleteNotebook').run()


module.exports = Popover
