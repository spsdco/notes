Spine = require 'spine'

class window.Note extends Spine.Model
  @configure 'Note',
    'name',
    'content',
    'notebook',
    'date'

module.exports = Note
