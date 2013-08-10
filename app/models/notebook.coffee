Spine = require 'spine'

class window.Notebook extends Spine.Model
  @configure 'Notebook',
    'name',
    'categories'

module.exports = Notebook
