Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

class NotebookItem extends Spine.Controller
  elements:
    "ul": "category"

  events:
    "click": "expand"
    "click li": "filter"
    "click .icon": "newCategory"

  constructor: ->
    super
    @notebook.bind "update", @update

  expand: ->
    @el.parent()
      .children()
      .removeClass('expanded selected')
    @el.addClass('selected')

    # Only show the categories if there's more than one.
    @el.addClass('expanded') if @notebook.categories.length > 1

    # Open All Notes
    Notebook.trigger("changeNotebook", {id: @notebook.id, category: "all"})

  filter: (e) ->
    @category.find("li").removeClass('selected')
    $(e.currentTarget).addClass("selected")

  newCategory: (e) ->
    $(".popover-mask").show()
    target = $(e.target).parent()

    $(".category-popover").css({left: target.outerWidth(), top: target.offset().top}).show()
      .find("input").val('').focus()

  update: =>
    # Subcategories
    str = "<li data-category='all' class='selected'>All Notes</li>"
    for category, i in @notebook.categories
      str += "<li data-category=" + i + ">" + category + "</li>"
    @category.html(str)

    @el.addClass('expanded') if @notebook.categories.length > 1

module.exports = NotebookItem
