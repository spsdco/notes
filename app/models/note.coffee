Spine = require 'spine'

class window.Note extends Spine.Model
  @configure 'Note',
    'name',
    'content',
    'notebook',
    'category',
    'date'

module.exports = Note
