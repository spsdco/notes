Spine = require 'spine'

class window.Notebook extends Spine.Model
  @configure 'Notebook',
    'name',
    'categories'

  @extend @Sync

module.exports = Notebook
