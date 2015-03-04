Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

Modal = require './modal.coffee'

class Popover extends Spine.Controller

  elements:
    ".delete-popover": "categoryPopover"
    ".delete-popover input": "categoryInput"
    ".delete-popover": "delpopover"

  events:
    "click": "hidePopover"
    "contextmenu": "hidePopover"
    "click .category-popover button": "addCategory"
    "keyup .category-popover input": "addCategory"
    "click .delete-popover #deleteNotebook": "deleteNotebook"
    "click .delete-popover #renameNotebook": "renameNotebook"
    "keyup .delete-popover #addCat": "addCategory"
    "focusout .delete-popover #addCat": "cleanField"

  constructor: ->
    super

  hidePopover: (e) ->
    # Not sure where to put this, but it is global
    e.preventDefault()
    @el.hide().children().hide() if $(e.target)[0].nodeName isnt "INPUT"

  cleanField: (e) ->
    $(e.target)[0].value = ""


  addCategory: (e) ->
    if e.type is "keyup" and e.which is 13
      # adds the new category on
      notebook = Notebook.find(Notebook.current.id)
      cat = notebook.categories
      name = @categoryInput.val().replace(/\\/g, '')
      if name isnt ''
        cat.push(name)
        notebook.updateAttribute("categories", cat)
        @cleanField(e)

      @el.hide()

  renameNotebook: (e) =>
    # All renaming gets implemented in modal.coffee
    notebookid = @delpopover.attr('data-notebook')
    categoryid = @delpopover.attr('data-category')
    Modal.get('renameNotebook').run(notebookid, categoryid)

  deleteNotebook: (e) =>
    # All deletion gets implemented in modal.coffee
    notebookid = @delpopover.attr('data-notebook')
    categoryid = @delpopover.attr('data-category')
    Modal.get('deleteNotebook').run(notebookid, categoryid)


module.exports = Popover
