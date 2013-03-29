(function() {
  var Splitter, buffer, fs, gui, handlebars, home_dir, ncp, node, path, reserved_chars, storage_dir, util,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  gui = global.gui = require('nw.gui');

  fs = require('fs');

  buffer = require('buffer');

  path = require('path');

  ncp = require('ncp').ncp;

  util = require('util');

  handlebars = require('handlebars');

  global.document = document;

  Splitter = require('./javascript/lib/splitter');

  node = true;

  home_dir = process.env.HOME;

  reserved_chars = [186, 191, 220, 222, 106, 56];

  if (process.platform === "darwin") {
    storage_dir = path.join(home_dir, "/Library/Application Support/Noted/");
  } else if (process.platform === "win32") {
    storage_dir = path.join(process.env.LOCALAPPDATA, "/Noted");
  } else if (process.platform === "linux") {
    storage_dir = path.join(home_dir, "/.config/Noted/");
  }

  window.noted = {
    selectedList: "all",
    selectedNote: "",
    setupPanel: function() {
      var win;
      win = gui.Window.get();
      win.show();
      win.showDevTools();
      $('#close').click(function() {
        return win.close();
      });
      $('#minimize').click(function() {
        return win.minimize();
      });
      $('#maximize').click(function() {
        return win.maximize();
      });
      return $('#panel').mouseenter(function() {
        return $('#panel').addClass('drag');
      }).mouseleave(function() {
        return $('#panel').removeClass('drag');
      });
    },
    setupUI: function() {
      Splitter.init({
        parent: $("#parent")[0],
        panels: {
          left: {
            el: $("#notebooks")[0],
            min: 150,
            width: 200,
            max: 450
          },
          center: {
            el: $("#notes")[0],
            min: 250,
            width: 300,
            max: 850
          },
          right: {
            el: $("#content")[0],
            min: 450,
            width: 550,
            max: Infinity
          }
        }
      });
      $("#content .edit").click(window.noted.editMode);
      $("body").on("click", "#notebooks li", function() {
        $(this).parent().find(".selected").removeClass("selected");
        $(this).addClass("selected");
        window.noted.loadNotes($(this).text());
        return window.noted.deselect();
      });
      $("body").on("contextmenu", "#notebooks li", function() {
        var name;
        name = $(this).text();
        console.log(name);
        window.noted.editor.remove('file');
        return fs.unlink(path.join(storage_dir, "Notebooks", name, '*'), function(err) {
          return fs.rmdir(path.join(storage_dir, "Notebooks", name), function(err) {
            if (err) throw err;
            window.noted.deselect();
            return window.noted.listNotebooks();
          });
        });
      });
      $('body').on("keydown", "#notebooks input", function(e) {
        var name, regexp;
        name = $('#notebooks input').val();
        if (e.keyCode === 13) {
          e.preventDefault();
          while (fs.existsSync(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt')) === true) {
            regexp = /\(\s*(\d+)\s*\)$/;
            if (regexp.exec(name) === null) {
              name = name + " (1)";
            } else {
              name = name.replace(" (" + regexp.exec(name)[1] + ")", " (" + (parseInt(regexp.exec(name)[1]) + 1) + ")");
            }
          }
          fs.mkdir(path.join(storage_dir, "Notebooks", name));
          window.noted.listNotebooks();
          return $('#notebooks input').val("").blur();
        }
      });
      $("body").on("click", "#notes li", function() {
        this.el = $(this);
        $("#notes .selected").removeClass("selected");
        this.el.addClass("selected");
        return window.noted.loadNote(this.el);
      });
      $("body").on("keydown", ".headerwrap .left h1", function(e) {
        var name, regexp, _ref;
        console.log(e.keyCode);
        if (e.keyCode === 13) {
          e.preventDefault();
          name = $(this).text();
          while (fs.existsSync(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt')) === true) {
            regexp = /\(\s*(\d+)\s*\)$/;
            if (regexp.exec(name) === null) {
              name = name + " (1)";
            } else {
              name = name.replace(" (" + regexp.exec(name)[1] + ")", " (" + (parseInt(regexp.exec(name)[1]) + 1) + ")");
            }
            fs.rename(path.join(storage_dir, "Notebooks", window.noted.selectedList, window.noted.selectedNote + '.txt'), path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt'));
            window.noted.selectedNote = name;
          }
          window.noted.loadNotes(window.noted.selectedList);
          return $(this).blur();
        } else if (_ref = e.keyCode, __indexOf.call(reserved_chars, _ref) >= 0) {
          return e.preventDefault();
        }
      });
      $("body").on("keyup", ".headerwrap .left h1", function(e) {
        var name;
        name = $(this).text();
        while (fs.existsSync(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt')) === true) {
          name = name + "_";
        }
        $("#notes [data-id='" + window.noted.selectedNote + "']").attr("data-id", name).find("h2").text($(this).text());
        if ($(this).text() !== "") {
          console.log("renaming note");
          console.log(path.join(storage_dir, "Notebooks", window.noted.selectedList, window.noted.selectedNote + '.txt'));
          console.log(path.join(storage_dir, "Notebooks", window.noted.selectedList, $(this).text() + '.txt'));
          fs.rename(path.join(storage_dir, "Notebooks", window.noted.selectedList, window.noted.selectedNote + '.txt'), path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt'));
          return window.noted.selectedNote = name;
        }
      });
      window.noted.editor = new EpicEditor({
        container: 'contentbody',
        file: {
          name: 'epiceditor',
          defaultContent: '',
          autoSave: 2500
        },
        theme: {
          base: '/themes/base/epiceditor.css',
          preview: '/themes/preview/style.css',
          editor: '/themes/editor/style.css'
        }
      });
      window.noted.editor.load();
      window.noted.editor.on("save", function(e) {
        var list, notePath;
        list = $("#notes li[data-id='" + window.noted.selectedNote + "']").attr("data-list");
        if (window.noted.selectedNote !== "") {
          notePath = path.join(storage_dir, "Notebooks", list, window.noted.selectedNote + '.txt');
          if (e.content !== fs.readFileSync(notePath).toString()) {
            return fs.writeFile(notePath, e.content);
          }
        }
      });
      $('#new').click(function() {
        var name, regexp;
        name = "Untitled Note";
        if (window.noted.selectedList !== "All Notes" && window.noted.editor.eeState.edit === false) {
          while (fs.existsSync(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt')) === true) {
            regexp = /\(\s*(\d+)\s*\)$/;
            if (regexp.exec(name) === null) {
              name = name + " (1)";
            } else {
              name = name.replace(" (" + regexp.exec(name)[1] + ")", " (" + (parseInt(regexp.exec(name)[1]) + 1) + ")");
              console.log(regexp.exec(name)[1]);
            }
          }
          return fs.writeFile(path.join(storage_dir, "Notebooks", window.noted.selectedList, name + '.txt'), "Add some content!", function() {
            return window.noted.loadNotes(window.noted.selectedList, "", function() {
              console.log("hello");
              return $("#notes ul li:first").addClass("edit").trigger("click");
            });
          });
        }
      });
      $('#del').click(function() {
        return $(".modal.delete").modal();
      });
      $(".modal.delete .true").click(function() {
        $(".modal.delete").modal("hide");
        window.noted.editor.remove('file');
        if (window.noted.selectedNote !== "") {
          return fs.unlink(path.join(storage_dir, "Notebooks", $("#notes li[data-id='" + window.noted.selectedNote + "']").attr("data-list"), window.noted.selectedNote + '.txt'), function(err) {
            if (err) throw err;
            window.noted.deselect();
            return window.noted.loadNotes(window.noted.selectedList);
          });
        }
      });
      return $(".modal.delete .false").click(function() {
        return $(".modal.delete").modal("hide");
      });
    },
    editMode: function(mode) {
      var el;
      el = $("#content .edit");
      if (mode === "preview" || window.noted.editor.eeState.edit === true && mode !== "editor") {
        el.text("edit");
        $('#content .left h1').attr('contenteditable', 'false');
        $('#contentbody');
        window.noted.editor.save();
        return window.noted.editor.preview();
      } else {
        el.text("save");
        $('.headerwrap .left h1').attr('contenteditable', 'true');
        return window.noted.editor.edit();
      }
    },
    render: function() {
      return window.noted.listNotebooks();
    },
    listNotebooks: function() {
      var htmlstr, template;
      template = handlebars.compile($("#notebook-template").html());
      htmlstr = template({
        name: "All Notes",
        "class": "all"
      });
      return fs.readdir(path.join(storage_dir, "Notebooks"), function(err, data) {
        var i;
        i = 0;
        while (i < data.length) {
          if (fs.statSync(path.join(storage_dir, "Notebooks", data[i])).isDirectory()) {
            htmlstr += template({
              name: data[i]
            });
          }
          i++;
        }
        $("#notebooks ul").html(htmlstr);
        return $("#notebooks [data-id='" + window.noted.selectedList + "'], #notebooks ." + window.noted.selectedList).trigger("click");
      });
    },
    loadNotes: function(list, type, callback) {
      var data, fd, htmlstr, i, info, lastIndex, name, note, num, order, template, time, _i, _len;
      window.noted.selectedList = list;
      template = handlebars.compile($("#note-template").html());
      htmlstr = "";
      if (list === "All Notes") {
        htmlstr = "I broke all notes because of the shitty implementation";
      } else {
        data = fs.readdirSync(path.join(storage_dir, "Notebooks", list));
        order = [];
        i = 0;
        while (i < data.length) {
          if (data[i].substr(data[i].length - 4, data[i].length) === ".txt") {
            name = data[i].substr(0, data[i].length - 4);
            time = new Date(fs.statSync(path.join(storage_dir, "Notebooks", list, name + '.txt'))['mtime']);
            fd = fs.openSync(path.join(storage_dir, "Notebooks", list, name + '.txt'), 'r');
            buffer = new Buffer(100);
            num = fs.readSync(fd, buffer, 0, 100, 0);
            info = $(marked(buffer.toString("utf-8", 0, num))).text();
            fs.close(fd);
            if (info.length > 90) {
              lastIndex = info.lastIndexOf(" ");
              info = info.substring(0, lastIndex) + "&hellip;";
            }
            order.push({
              id: i,
              time: time,
              name: name,
              info: info
            });
          }
          i++;
        }
        order.sort(function(a, b) {
          return new Date(a.time) - new Date(b.time);
        });
        for (_i = 0, _len = order.length; _i < _len; _i++) {
          note = order[_i];
          htmlstr = template({
            name: note.name,
            list: list,
            year: note.time.getFullYear(),
            month: note.time.getMonth() + 1,
            day: note.time.getDate(),
            excerpt: note.info
          }) + htmlstr;
        }
      }
      $("#notes ul").html(htmlstr);
      if (callback) return callback();
    },
    loadNote: function(selector) {
      window.noted.selectedNote = $(selector).find("h2").text();
      return fs.readFile(path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'), 'utf-8', function(err, data) {
        var noteTime, time;
        if (err) throw err;
        $("#content").removeClass("deselected");
        $('.headerwrap .left h1').text(window.noted.selectedNote);
        noteTime = fs.statSync(path.join(storage_dir, "Notebooks", $(selector).attr("data-list"), window.noted.selectedNote + '.txt'))['mtime'];
        time = new Date(Date.parse(noteTime));
        $('.headerwrap .left time').text(window.noted.timeControls.pad(time.getFullYear()) + "/" + (window.noted.timeControls.pad(time.getMonth() + 1)) + "/" + time.getDate() + " " + window.noted.timeControls.pad(time.getHours()) + ":" + window.noted.timeControls.pad(time.getMinutes()));
        window.noted.editor.importFile('file', data);
        if (selector.hasClass("edit")) {
          window.noted.editMode("editor");
          $("#content .left h1").focus();
          return selector.removeClass("edit");
        } else {
          return window.noted.editMode("preview");
        }
      });
    },
    deselectNote: function() {
      $("#content").addClass("deselected");
      $("#content .left h1, #content .left time").text("");
      window.noted.selectedNote = "";
      window.noted.editor.importFile('file', "");
      return window.noted.editor.preview();
    }
  };

  window.noted.timeControls = {
    pad: function(n) {
      if (n < 10) {
        return "0" + n;
      } else {
        return n;
      }
    }
  };

  $(function() {
    window.noted.setupUI();
    if (node) {
      window.noted.setupPanel();
      return fs.readdir(path.join(storage_dir, "/Notebooks/"), function(err, data) {
        if (err) {
          if (err.code === "ENOENT") {
            return fs.mkdir(path.join(storage_dir, "/Notebooks/"), function() {
              return ncp(path.join(window.location.pathname, "../default_notebooks"), path.join(storage_dir, "/Notebooks/"), function(err) {
                return window.noted.render();
              });
            });
          }
        } else {
          return window.noted.render();
        }
      });
    }
  });

}).call(this);
