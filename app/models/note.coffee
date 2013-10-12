Spine = require 'spine'
Notebook = require './notebook.coffee'

class window.Note extends Spine.Model
  @configure 'Note',
    'name',
    'excerpt',
    'notebook',
    'category',
    'date'

  @extend @Sync
  @include @Sync

  # Deletes it from IndexedDB
  @.bind "beforeDestroy", (note) ->
    note.deleteNote()

  # since we can't change .find, we can use this to the same effect
  @filter: (notebook, category) ->
    # returns all the notes if no notebook specified
    if notebook && notebook isnt "all"
      array = Note.findAllByAttribute("notebook", notebook)

      # because 0 evals to false in JS
      category = category.toString()
      # returns items in a category, unless not specfied
      if category && category isnt "all"
        # matches the id number to the realname. i wish i had made a better system.
        category = Notebook.find(notebook).categories[category]
        newArray = []
        for note in array
          newArray.push(note) if note.category is category
        array = newArray
    else
      array = Note.all()
    return array

  @search: (string) ->
    # Ported from 1.0
    results = []
    notes = Note.all()
    for note in notes
      if note.name.match(new RegExp(string, 'i'))# or content.match(new RegExp(string, 'i'))
        note.date = note.prettyDate()
        results.push(note)

    console.log(results)
    Notebook.trigger 'changeNotebook', {id: 'all', category: 'all', search: true, result: results}

  prettyDate: (time) =>
    date = new Date(@date * 1000)
    pad = (n) -> (if (n < 10) then ("0" + n) else n)

    month = [
      "Jan"
      "Feb"
      "Mar"
      "Apr"
      "May"
      "Jun"
      "Jul"
      "Aug"
      "Sep"
      "Oct"
      "Nov"
      "Dec"
    ]

    now = new Date()
    difference = 0
    oneDay = 86400000; # 1000*60*60*24 - one day in milliseconds
    words = ''

    # Find difference between days
    difference = Math.ceil((date.getTime() - now.getTime()) / oneDay)

    # Show difference nicely
    if difference is 0
      words = "Today"
      words = "Yesterday" if now.getDate() isnt date.getDate()
    else if difference is -1
      words = "Yesterday"
    else if difference > 0
      # If the user has a TARDIS
      words = "Today"
    else if difference > -15
      words = Math.abs(difference) + " days ago"
    else if difference > -365
      words = month[date.getMonth()] + " " + date.getDate()
    else
      words = pad(date.getFullYear())+"-"+(pad(date.getMonth()+1))+"-"+pad(date.getDate())

    words += " " + date.getHours() + ":" + pad(date.getMinutes()) if time

    return words


module.exports = Note
