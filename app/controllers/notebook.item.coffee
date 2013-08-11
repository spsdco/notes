Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

class NotebookItem extends Spine.Controller
  elements:
    "ul": "category"

  events:
    "click": "expand"
    "click .icon": "newCategory"

  constructor: ->
    super
    @notebook.bind "update", @update

  expand: (e) =>
    @el.parent()
      .children()
      .removeClass('expanded selected')
    @el.addClass('selected')

    # Only show the categories if there's more than one.
    @el.addClass('expanded') if @notebook.categories.length > 1

    # Filters
    @category.find("li").removeClass('selected')
    if $(e.target).attr("data-category")
      # Special Call - Not just all
      $(e.target).addClass("selected")
      Notebook.trigger("changeNotebook", {id: @notebook.id, category: $(e.target).attr("data-category")})
    else
      # Open All Notes
      @el.find("[data-category='all']").addClass("selected")
      Notebook.trigger("changeNotebook", {id: @notebook.id, category: "all"})

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
