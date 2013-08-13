Spine = @Spine or require('spine')
Model = Spine.Model

# Connection states
OFFLINE = 0
IN_PROGRESS = 1
ONLINE = 2


Sync =

  # Hold pending actions
  pending: []

  # Run pending actions
  _clearPending: ->
    for [fn, that, args], i in @pending by - 1
      fn.apply(that, args)
      @pending.length--

  # If connection is not ready, then we will wait until it is
  defer: (self, fn, args...) ->
    if @state is ONLINE
      fn(args...)
    else
      @pending.push [fn, self,  args]
      console.log @pending

  state: OFFLINE

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

Model.Sync =

  extended: ->

    @fetch Sync.defer(this, @loadLocal)
    @change Sync.defer(this, @saveLocal)

    Sync.connect()

  saveLocal: ->
    result = JSON.stringify(@)

    # Save to IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite")
    store = trans.objectStore("meta")
    request = store.put(result, @className)

  loadLocal: (options = {}) ->

    console.log 'loading all'

    options.clear = true unless options.hasOwnProperty('clear')

    # Load from IndexedDB
    trans = Sync.db.transaction(["meta"], "readwrite");
    store = trans.objectStore("meta");
    request = store.get(@className)

    request.onsuccess = (e) =>
      result = e.target.result
      @refresh(result or [], options)


Model.Sync.Methods =
  extended: ->
    @extend Extend
    @include Include

module?.exports = Sync
