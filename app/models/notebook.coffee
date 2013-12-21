Spine = require 'spine'

class window.Notebook extends Spine.Model
  @configure 'Notebook',
    'name',
    'categories',
    'date'

  @extend @Sync

  @.bind "beforeUpdate", (notebook, context) ->
    if context isnt "date"
      notebook.updateAttributes {
        "date": Math.round(new Date()/1000)
      }, "date"

  @.bind "beforeDestroy", (notebook) ->
    for note in Note.filter(notebook.id, "all")
      note.destroy()

  subcategoryDestroy: (category) ->
    for note in Note.filter(Notebook.current.id, category)
      note.destroy()

    # this is a terrible hack. I will fix it maybe
    # in theory, they can't an empty subcategory string
    arr = @categories.slice(0)
    arr[category] = ""
    @updateAttribute 'categories', arr

module.exports = Notebook
