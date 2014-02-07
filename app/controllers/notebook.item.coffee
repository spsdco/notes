Spine = require 'spine'

# Models
Notebook = require '../models/notebook.coffee'

class NotebookItem extends Spine.Controller
  elements:
    'ul': 'category'

  events:
    'click': 'expand'
    'contextmenu': 'expand'
    'contextmenu': 'toggleMore'
    'click .icon': 'newCategory'
    'dragenter': 'onDragEnter'
    'dragleave': 'onDragLeave'
    'dragover': 'onDragOver'
    'drop': 'onDrop'

  constructor: ->
    super
    if @notebook.id isnt 'all'
      @notebook.bind 'changeNotebook', @changeNotebook
      @notebook.bind 'update', @update
      @notebook.bind 'destroy', @destroy

  expand: (e) =>
    # Categories
    if $(e.target).attr('data-category')
      Notebook.trigger('changeNotebook', {id: @notebook.id, category: $(e.target).attr('data-category')})
    else
      Notebook.trigger('changeNotebook', {id: @notebook.id, category: 'all'})

    # Hacky, but whatever.
    @changeNotebook({id: 'all', category: 'all'}) if @notebook.id is 'all'

  toggleMore: (e) =>
    @expand(e)
    e.preventDefault()
    if !$(e.target).hasClass('icon') and @notebook.id isnt 'all'
      $('.popover-mask').show()
      target = $(e.target).parent()

      if $(e.target).attr('data-category') is 'all'
        return

      # Category
      else if $(e.target).attr('data-category')
        $('.delete-popover').css(
          left: target.outerWidth(),
          top: $(e.target).offset().top-($('.delete-popover').height()/3)
        ).attr('data-notebook', @notebook.id
        ).attr('data-category', $(e.target).attr('data-category')
        ).show()

      # Book
      else
        $('.delete-popover').css(
          left: target.outerWidth(),
          top: @el.offset().top
        ).attr('data-notebook', @notebook.id
        ).attr('data-category', 'all'
        ).show()

  changeNotebook: (notebook) =>
    @el.parent()
      .children()
      .removeClass('expanded selected')
    @el.addClass('selected')

    # Only show the categories if there's more than one.
    @el.addClass('expanded') if @notebook.categories.length > 1

    # Select the right one
    @category.find('li').removeClass('selected')
    @el.find("[data-category='#{notebook.category}']").addClass('selected')

  newCategory: (e) ->
    $('.popover-mask').show()
    target = $(e.target).parent()

    $('.category-popover').css({left: target.outerWidth(), top: target.offset().top}).show()
      .find('input').val('').focus()

  update: =>
    # Subcategories
    str = '<li data-category="all" class="selected">All Notes</li>'
    for category, i in @notebook.categories
      str += "<li data-category=#{i}>#{category}</li>"
    @category.html(str)

    @el.addClass('expanded') if @notebook.categories.length > 1

  destroy: =>
    @el.remove()

  onDragEnter: (e) =>
    e.preventDefault()
    if ($(e.target).attr('data-category') and $(e.target).attr('data-category') isnt 'all') or $(e.currentTarget).attr('id') isnt 'notebook-all'
      $(e.target).addClass('dragover')

  onDragLeave: (e) =>
    e.preventDefault()
    $(e.target).removeClass('dragover')

  onDragOver: (e) =>
    e.preventDefault()
    if @notebook.id is 'all' or $(e.target).attr('data-category') is 'all'
      # No.
      return false

  onDrop: (e) =>
    # Create the note in this Notebook, delete the old one.
    if @notebook.id is 'all' or $(e.target).attr('data-category') is 'all'
      return false;
    else
      noteid = e.originalEvent.dataTransfer.getData('noteid')
      note = Note.find(noteid)
      if $(e.target).attr('data-category')
        category = $(e.target).text()
        $(e.target).removeClass('dragover') # Reset CSS changes
      else
        category = @notebook.categories[0] # Default Category

      note.updateAttributes {
        'notebook': @notebook.id,
        'category': category
      }

      # Finally, refresh!
      Notebook.trigger 'changeNotebook', {id: Notebook.current.id, category: Notebook.current.category}

module.exports = NotebookItem
