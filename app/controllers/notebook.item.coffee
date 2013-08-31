Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

class NotebookItem extends Spine.Controller
  elements:
    "ul": "category"

  events:
    "click": "expand"
    "contextmenu": "expand"
    "contextmenu": "toggleMore"
    "click .icon": "newCategory"
    "dragenter": "onDragEnter"
    "dragover": "onDragOver"
    "drop": "onDrop"

  constructor: ->
    super
    if @notebook.id isnt "all"
      @notebook.bind "changeNotebook", @changeNotebook
      @notebook.bind "update", @update

  expand: (e) =>
    # Categories
    if $(e.target).attr("data-category")
      Notebook.trigger("changeNotebook", {id: @notebook.id, category: $(e.target).attr("data-category")})
    else
      Notebook.trigger("changeNotebook", {id: @notebook.id, category: "all"})

    # Hacky, but whatever.
    @changeNotebook({id: "all", category: "all"}) if @notebook.id is "all"

  toggleMore: (e) =>
    @expand(e)
    e.preventDefault()
    if !$(e.target).hasClass("icon") and @notebook.id isnt "all"
      $(".popover-mask").show()
      target = $(e.target).parent()

      if $(e.target).attr("data-category") is "all"
        return
      else if $(e.target).attr("data-category")
        $(".delete-popover").css({left: target.outerWidth(), top: $(e.target).offset().top-($(".delete-popover").height()/3)}).show()
      else
        # THIS LINE IS AMAZING o.o
        id = @el.attr('id').replace('notebook-','')
        $(".delete-popover").css({left: target.outerWidth(), top: @el.offset().top}).attr('current-notebook', id).show()

  changeNotebook: (notebook) =>
    # This is seperated because we don't want to do DOM triggers.
    @el.parent()
      .children()
      .removeClass('expanded selected')
    @el.addClass('selected')

    # Only show the categories if there's more than one.
    @el.addClass('expanded') if @notebook.categories.length > 1

    # Select the right one
    @category.find("li").removeClass('selected')
    @el.find("[data-category='#{notebook.category}']").addClass("selected")

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

  onDragEnter: (e) =>
    e.preventDefault()

  onDragOver: (e) =>
    e.preventDefault()
    if @notebook.id is "all"
      # No.
      return false;
    else
      setTimeout(=>
        @expand(e)
      ,500)

  onDrop: (e) =>
    # Create the note in this Notebook, delete the old one. Seems like it would work.
    # Get the notebook id!
    if @notebook.id is "all"
      # OMG PLS NO.
      return false;
    else
      noteid = e.originalEvent.dataTransfer.getData('noteid')
      note = Note.find(noteid)
      if $(e.target).attr("data-category")
        category = $(e.target).text()
      else
        category = "all"

      note.updateAttributes {
        "notebook": @notebook.id,
        "category": category
      }

      # Finally, refresh!
      Notebook.trigger('refresh')

module.exports = NotebookItem
