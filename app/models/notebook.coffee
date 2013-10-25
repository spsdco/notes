Spine = require 'spine'

class window.Notebook extends Spine.Model
  @configure 'Notebook',
    'name',
    'categories',
    'date'

  @extend @Sync

  @.bind "beforeUpdate", (notebook) ->
    notebook.updateAttributes {
      "date": Math.round(new Date()/1000)
    }

  @.bind "beforeDestroy", (notebook) ->
    for note in Note.filter(notebook.id, "all")
      note.destroy()
    console.log("destroyinghinginig")

module.exports = Notebook
