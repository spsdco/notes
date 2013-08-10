Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

class Popover extends Spine.Controller

  elements:
    ".category-popover": "categoryPopover"
    ".category-popover input": "categoryInput"

  events:
    "click": "hidePopover"
    "click .category-popover button": "addCategory"
    "keyup .category-popover input": "addCategory"

  constructor: ->
    super

  hidePopover: (e) ->
    # Not sure where to put this, but it is global
    @el.hide() if $(e.target)[0].nodeName isnt "INPUT"

  addCategory: (e) ->
    if e.type is "keyup" and e.which is 13 or e.type is "click"
      # adds the new category on
      notebook = Notebook.find(Notebook.current.id)
      cat = notebook.categories
      cat.push(@categoryInput.val())
      notebook.updateAttribute("categories", cat)

      @el.hide()


module.exports = Popover
