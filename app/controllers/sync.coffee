Spine = @Spine or require('spine')
io = require 'socket.io-client'
Model = Spine.Model

# Connection states
OFFLINE = 0
IN_PROGRESS = 1
ONLINE = 2

window.Sync =

  queue: JSON.parse localStorage.Queue or '{"Note": {}, "Notebook": {}}'

  # Hold pending actions
  pending: []

  # Run pending actions
  _clearPending: ->
    for [fn, that, args] in @pending by - 1
      fn.apply(that, args)
      @pending.length--

  # If connection is not ready, then we will wait until it is
  defer: (self, fn, args...) ->
    if @state is ONLINE
      fn.apply(self, args)
    else
      @pending.push [fn, self,  args]

  state: OFFLINE

  auth: ->
    socket = io.connect("https://springseed-oauth.herokuapp.com:443")
    socket.on "meta", (data) ->
      console.log(data)

    socket.on "authorized", (data) ->
      # We have a token. We can do anything!
      localStorage.Token = data.access_token

      # Get user accountinfo because yolo
      $.ajax(
        type: "get"
        crossDomain: true
        dataType: "json"
        url: "https://api.dropbox.com/1/account/info"
        beforeSend: (xhr) ->
          xhr.setRequestHeader "Authorization", "Bearer " + data.access_token
      ).done (accountinfo) ->
        console.log accountinfo

      # Free up server resources. Cause why not.
      socket.disconnect()

  connect: (fn) ->

    # Only run connect once
    if @state isnt OFFLINE and typeof fn is 'function 'then return fn()
    @state = IN_PROGRESS

    request = indexedDB.open("springseed", 1)

    request.onupgradeneeded = (e) =>
      @db = e.target.result

      # We're going to just be storing all the spine stuff in one store,
      # just because I cbf seperating the Keys.
      @db.createObjectStore("meta")

      # We'll make another store to seperate the note s
      @db.createObjectStore("notes")

    request.onsuccess = (e) =>
      Sync.db = e.target.result
      @state = ONLINE
      fn() if typeof fn is 'function'
      @_clearPending()

  # Check an event, and if it is a model update add it to the queue
  addToQueue: (event, args) ->
    if @queue[args.constructor.name][args.id] and @queue[args.constructor.name][args.id][0] is "create"
      # create + destroy = nothing
      if event is "destroy"
        delete @queue[args.constructor.name][args.id]
    else
      # Otherwiswe, add it to the queue
      @queue[args.constructor.name][args.id] = [event, new Date().getTime()]
    @saveQueue()

  saveQueue: ->
    # Save queue to localstorage
    localStorage.Queue = JSON.stringify @queue

  # Merges the client & server, using a queue
  # Spits out the result, id changes & fs changes
  merger: (client, server, queue) ->

    # Creates an array index
    indexer = (db) ->
      result = {}
      for k,v of db
        # Sets Up Index
        result[k] = {}
        result[k].max = 0

        # Indexes Items
        for key, index in db[k]
          result[k][key.id] = index

          # Checks for the highest number
          num = parseInt(key.id.substring(2, key.id.length))
          result[k].max = num if num > result[k].max

      result #return

    clientindex = indexer(client)
    resultant = JSON.parse(JSON.stringify(server))
    resultantindex = indexer(resultant)
    namechanges = {"Notebook": [], "Note": []}
    fschanges = {"Notebook": [], "Note": []}

    # Add Changes from client
    for type of queue
      for key, value of queue[type]
        switch value[0]
          when "create"
            # we copy the change into the resultant
            oldId = key
            newId = "c-" + (resultantindex[type].max += 1)
            client[type][clientindex[type][key]].id = newId
            resultant[type].push(client[type][clientindex[type][key]])

            # update the index
            resultantindex[type][newId] = resultant[type].length

            # add to fschanges
            fschanges[type].push(["upload", newId])

            # add to name changes
            namechanges[type].push([oldId, newId]) if oldId isnt newId

          when "update"
            # If the item update was before the update on the server, create a conflicted copy
            if Math.round(value[1]/1000) < resultant[type][resultantindex[type][key]].date
              # bad case of DRY here

              # we copy the change into the resultant
              oldId = key
              newId = "c-" + (resultantindex[type].max += 1)
              client[type][clientindex[type][key]].id = newId
              client[type][clientindex[type][key]].name += " (Conflicted Copy)"
              resultant[type].push(client[type][clientindex[type][key]])

              # update the index
              resultantindex[type][newId] = resultant[type].length

              # add to fschanges
              fschanges[type].push(["download", resultant[type][resultantindex[type][key]].id])
              fschanges[type].push(["upload", newId])

              # add to name changes
              namechanges[type].push([oldId, newId]) if oldId isnt newId
            else
              # copies the new change in
              resultant[type][resultantindex[type][key]] = client[type][clientindex[type][key]]

              fschanges[type].push(["upload", resultant[type][resultantindex[type][key]].id])
          when "destroy"
            # If the item was after before the delete event, don't do anything
            if Math.round(value[1]/1000) > resultant[type][resultantindex[type][key]].date
              # tell the server to delete it
              fschanges[type].push(["destroy", resultant[type][resultantindex[type][key]].id])

              # destroy the change from the resultant
              resultant[type].splice([clientindex[type][key]], 1)

              # reindex
              resultantindex = indexer(resultant)

    # All the changes from the client should be added at this point
    # Now we detect the differences between the server copy and our client.

    # Basically, find timestamps that are newer on the server and stuff
    # that exists on the server but not the client.

    # We start by cloning the resultant
    original = JSON.parse(JSON.stringify(resultant))
    originalindex = indexer(original)

    # Removing all the stuff that is changed
    for type of fschanges
      for item in fschanges[type]
        original[type].splice(originalindex[type][item[1]], 1)
        originalindex = indexer(original)

    for type of original
      for key, value of original[type]
        # We only need to do this for stuff with dates, not anything else
        if value.date
          if client[type][clientindex[type][value.id]]
            if client[type][clientindex[type][value.id]].date < value.date
              # Server is newer than client, download from server
              fschanges[type].push(["download", value.id])
          else
            # Doesn't exist on client, download from server
            fschanges[type].push(["download", value.id])

    return [resultant, namechanges, fschanges]

# Just in case you need any default values
class Base

Model.Sync =

  extended: ->

    console.log '%c> Setting up sync for %s', 'font-weight: bold', this.name

    @fetch ->
      console.log '%c> Calling fetch', 'background: #eee'
      Sync.defer(this, @loadLocal)

    @change (record, event) ->
      Sync.addToQueue(event, record)
      console.log '%c> Calling change: ' + event, 'background: #eee'
      Sync.defer(this, @saveLocal)

    Sync.connect()

  saveLocal: ->
    result = JSON.stringify(@)

    # Save to IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite")
    store = trans.objectStore "meta"
    request = store.put(result, @className)

  loadLocal: (options = {}) ->

    console.log '%c> Fetching notes', 'color: blue'

    options.clear = true unless options.hasOwnProperty('clear')

    # Load from IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite")
    store = trans.objectStore "meta"
    request = store.get(@className)

    request.onsuccess = (e) =>
      result = e.target.result
      @refresh(result or [], options)

  saveNote: (content) ->
    trans = Sync.db.transaction(["notes"], "readwrite")
    store = trans.objectStore "notes"
    request = store.put(content, @id)

  loadNote: (callback) ->
    trans = Sync.db.transaction(["notes"], "readwrite")
    store = trans.objectStore "notes"
    request = store.get(@id)

    request.onsuccess = (e) =>
      result = e.target.result
      callback(result)

  deleteNote: ->
    trans = Sync.db.transaction(["notes"], "readwrite")
    store = trans.objectStore "notes"
    request = store.delete(@id)

Model.Sync.Methods =
  extended: ->
    @extend Extend
    @include Include

module?.exports = Sync
