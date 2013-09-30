Spine = require 'spine'

class window.Notebook extends Spine.Model
  @configure 'Notebook',
    'name',
    'categories'

  @extend @Sync

  @.bind "beforeDestroy", (notebook) ->
    for note in Note.filter(notebook.id, "all")
      note.destroy()
    console.log("destroyinghinginig")

module.exports = Notebook
