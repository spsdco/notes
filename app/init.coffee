jQuery  = require("jqueryify")
exports = this
jQuery ->
  App = require './index.coffee'
  exports.app = new App
    el: $('body')
