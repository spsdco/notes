(function() {

  // Variables
  var parent;
  var panels = {};
  var splitters = {};
  var parentOffset = 0;
  var width = 0;
  var active = false;
  var offset = {};
  var minWidth = 0;
  var last = {
    pos: 0,
    width: 0
  };


  // Class Panel
  var Panel = function(id, options) {
    this.id = id;
    this.el = options.el;
    this.min = options.min || 0;
    this.max = options.max || Infinity;
    this.width = options.width || 0;

    switch (this.id) {
      case "left":
        this.pos = 0;
        break;
      case "center":
        this.pos = panels.left.width;
        break;
      case "right":
        this.pos = panels.left.width + panels.center.width;
        break;
    }

    if (this.id !== "right") { this.el.style.width = this.width + "px"; }
    this.el.style.left = this.pos + "px";

  };

  Panel.prototype = {
    move: function(position, relative) {
      if (relative) { this.pos += position; }
      else { this.pos = position; }
      this.el.style.left = this.pos + "px";
    },
    resize: function(width, relative) {
      if (relative) { this.width += width; }
      else { this.width = width; }
      if (this.width < this.min) { this.width = this.min; }
      else if (this.width > this.max) { this.width = this.max; }
      this.el.style.width = this.width + "px";
    }
  };


  // Class Splitter
  var Splitter = function(id) {
    this.id = id;
    this.el = doc.createElement("div")
    this.pos = 0;

    if (this.id === "left") {
      this.left = panels.left;
      this.right = panels.center;
    }
    else if (this.id === "right") {
      this.left = panels.center;
      this.right = panels.right;
    }

    this.el.className = "splitter split-" + this.id;
    this.el.style.left = this.right.pos + "px";
    this.left.el.insertAdjacentElement('afterend', this.el);
    this.pos = this.el.offsetLeft;
    this.el.obj = this;
    this.el.onmousedown = events.mousedown;

  };

  Splitter.prototype = {
    move: Panel.prototype.move,
    resize: function(pos) {
      var resizeWindow = true;

      // Left min
      if (pos < this.left.min + offset.left) {
        pos = this.left.min + offset.left;
      }

      // Left max
      else if (pos > this.left.max + offset.left) {
        pos = this.left.max + offset.left;
      }

      if (this.id === "right") {
        resizeWindow = false;

        // Right min
        if (offset.right - pos < this.right.min) {
          resizeWindow = true;
        }

        // Right max
        else if (offset.right - pos > this.right.max) {
          pos = offset.right - this.right.max;
        }
      }

      // Calculate diff
      var diff = pos - last.pos;
      if (diff === 0) {
        this.pos = pos;
        return true;
      }

      // Right Splitter
      if (this.id === "right") {
        panels.center.resize(pos - offset.left);
        panels.right.move(pos);
        splitters.right.move(pos);
      }

      // Left splitter
      else if (this.id === "left") {
        splitters.left.move(pos);
        splitters.right.move(pos + panels.center.width);
        panels.left.resize(pos - offset.left);
        panels.center.move(pos);
        panels.right.move(splitters.right.pos);
        minWidth = pos + panels.center.min + panels.right.min;
      }

      // Resize window frame
      if (mode === "node" && resizeWindow) {
        width += diff;
        offset.right = win.width = width;
      }

      // Save position
      this.pos = last.pos = pos;
    }
  };


  /*
    Node Webkit Support
    -------------------
    global.document = document
    global.window = window
  */
  var win, doc, mode;
  if (typeof(process) !== "undefined") {
    mode = "node";
    win = global.gui.Window.get();
    doc = global.document;
  }
  else {
    mode = "browser";
    win = window;
    doc = document;
  }


  // Calculate position of cursor on parent.
  var getPos = function(clientX) {
    var pos = clientX - parentOffset;
    if (pos < 0) {
      pos = 0;
    }
    else if (pos > width) {
      pos = width;
    }
    return pos;
  };


  // Events
  var events = {

    mousedown: function(event) {
      active = this.obj;
      offset = {
        left: 0,
        right: width
      };
      if (active.id === "right") {
        offset.left = splitters.left.pos;
      }
      else if (active.id === "left") {
        offset.right = splitters.right.pos;
      }
      last.pos = getPos(event.clientX);
      doc.body.className = "resizing";
    },

    mousemove: function(event) {
      if (active) {
        var pos = getPos(event.clientX);
        active.resize(pos);
      }
    },

    mouseup: function() {

      if (mode == "node" && active.id === "left") {
        win.setMinimumSize(panels.left.max + panels.center.min + panels.right.min, 0);
      }

      doc.body.className = "";
      active = false;
    },

    resize: function() {

      // Only run if triggered by user
      if (!active) {

        // Get new width and check if it hase changed
        width = parent.offsetWidth;
        var diff = width - last.width;
        if (diff === 0 || width < minWidth) { return false; }

        // If window is shrinking
        if (diff < 0) {
          // Check right panel for min width
          if (panels.right.el.offsetWidth <= panels.right.min) {
            panels.center.resize(diff, true);
            panels.right.move(diff, true);
            splitters.right.move(diff, true);
          }
        }

        last.width = width;
      }
    }
  };

  var init = function(options) {

    // Get options
    parent = options.parent;

    // Create Panels
    panels.left = new Panel("left", options.panels.left);
    panels.center = new Panel("center", options.panels.center);
    panels.right = new Panel("right", options.panels.right);

    // Create Splitters
    splitters.left = new Splitter("left");
    splitters.right = new Splitter("right");

    // Get width of parent
    width = parent.offsetWidth;
    minWidth = panels.left.min + panels.center.min + panels.right.min;

    // Bind events
    doc.onmousemove = events.mousemove;
    doc.onmouseup = events.mouseup;
    window.onresize = events.resize;

  };

  var exports = {
    init: init,
    panels: panels,
    splitters: splitters
  };

  if (typeof(module) !== "undefined") {
    module.exports = exports;
  }
  else {
    window.Splitter = exports;
  }

}());
