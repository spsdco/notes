(function() {
  var $, Splitter, buffer, fs, gui, handlebars, marked, modal, ncp, path, util,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  global.document = document;

  gui = global.gui = require('nw.gui');

  fs = require('fs');

  buffer = require('buffer');

  path = require('path');

  ncp = require('ncp').ncp;

  util = require('util');

  $ = require('jQuery');

  handlebars = require('handlebars');

  marked = require('marked');

  Splitter = require('./javascript/lib/splitter');

  modal = require('./javascript/lib/modal');

  window.noted = {
    currentList: "all",
    currentNote: "",
    init: function() {
      window.noted.homedir = process.env.HOME;
      window.noted.resvchar = [186, 191, 220, 222, 106, 56];
      window.noted.storagedir = window.noted.osdirs();
      return window.noted.initUI();
    },
    initUI: function() {
      Splitter.init({
        parent: $('#parent')[0],
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
      window.noted.window = gui.Window.get();
      window.noted.window.show();
      window.noted.window.showDevTools();
      window.noted.load.notebooks();
      window.noted.load.notes("All Notes");
      window.noted.editor = ace.edit("contentwrite");
      window.noted.editor.getSession().setUseWrapMode(true);
      window.noted.editor.setHighlightActiveLine(false);
      window.noted.editor.setShowPrintMargin(false);
      window.noted.editor.renderer.setShowGutter(false);
      window.noted.editor.on("change", function() {
        var $this, delay;
        $this = $("#contentwrite");
        delay = 2000;
        clearTimeout($this.data('timer'));
        return $this.data('timer', setTimeout(function() {
          $this.removeData('timer');
          return window.noted.save();
        }, delay));
      });
      $('#panel').mouseenter(function() {
        return $('#panel').addClass('drag');
      }).mouseleave(function() {
        return $('#panel').removeClass('drag');
      });
      $('#panel #decor img, #panel #noteControls img, #panel #search').mouseenter(function() {
        return $('#panel').removeClass('drag');
      }).mouseleave(function() {
        return $('#panel').addClass('drag');
      });
      $('#new').click(function() {
        return window.noted.UIEvents.clickNewNote();
      });
      $('#del').click(function() {
        return window.noted.UIEvents.clickDelNote();
      });
      $(".modal.delete .true").click(function() {
        return window.noted.UIEvents.modalclickDel();
      });
      $(".modal.delete .false").click(function() {
        return $(".modal.delete").modal("hide");
      });
      $('#close').click(function() {
        return window.noted.UIEvents.titlebarClose();
      });
      $('#minimize').click(function() {
        return window.noted.UIEvents.titlebarMinimize();
      });
      $('#maximize').click(function() {
        return window.noted.UIEvents.titlebarMaximize();
      });
      $('body').on("keydown", "#notebooks input", function(e) {
        return window.noted.UIEvents.keydownNotebook(e);
      });
      $('body').on("click", "#notebooks li", function() {
        return window.noted.UIEvents.clickNotebook($(this));
      });
      $("body").on("keydown", ".headerwrap .left h1", function(e) {
        return window.noted.UIEvents.keydownTitle(e, $(this));
      });
      $("body").on("keyup", ".headerwrap .left h1", function() {
        return window.noted.UIEvents.keyupTitle($(this));
      });
      $('body').on("click", "#notes li", function() {
        return window.noted.UIEvents.clickNote($(this));
      });
      return $("#content .edit").click(window.noted.editMode);
    },
    deselect: function() {
      $("#content").addClass("deselected");
      $("#content .left h1, #content .left time").text("");
      return window.noted.currentNote = "";
    },
    editMode: function(mode) {
      var el;
      el = $("#content .edit");
      if (mode === "preview" || window.noted.editor.getReadOnly() === false && mode !== "editor") {
        el.text("edit");
        $('#content .left h1').attr('contenteditable', 'false');
        $("#contentread").html(marked(window.noted.editor.getValue())).show();
        $("#contentwrite").css("visibility", "hidden");
        window.noted.editor.setReadOnly(true);
        return window.noted.save();
      } else {
        el.text("save");
        $('.headerwrap .left h1').attr('contenteditable', 'true');
        $("#contentread").hide();
        $("#contentwrite").css("visibility", "visible");
        return window.noted.editor.setReadOnly(false);
      }
    },
    save: function() {
      var list, notePath;
      list = $("#notes li[data-id='" + window.noted.currentNote + "']").attr("data-list");
      if (window.noted.currentNote !== "") {
        notePath = path.join(window.noted.storagedir, "Notebooks", list, window.noted.currentNote + '.txt');
        return fs.writeFile(notePath, window.noted.editor.getValue());
      }
    },
    load: {
      notebooks: function() {
        var htmlstr, template;
        template = handlebars.compile($("#notebook-template").html());
        htmlstr = template({
          name: "All Notes",
          "class": "all"
        });
        return fs.readdir(path.join(window.noted.storagedir, "Notebooks"), function(err, data) {
          var i;
          i = 0;
          while (i < data.length) {
            if (fs.statSync(path.join(window.noted.storagedir, "Notebooks", data[i])).isDirectory()) {
              htmlstr += template({
                name: data[i]
              });
            }
            i++;
          }
          $("#notebooks ul").html(htmlstr);
          return $("#notebooks [data-id='" + window.noted.currentList + "'], #notebooks ." + window.noted.currentList).trigger("click");
        });
      },
      notes: function(list, type, callback) {
        var data, fd, htmlstr, i, info, lastIndex, name, note, num, order, template, time, _i, _len;
        window.noted.currentList = list;
        template = handlebars.compile($("#note-template").html());
        htmlstr = "";
        if (list === "All Notes") {
          htmlstr = "I broke all notes because of the shitty implementation";
        } else {
          data = fs.readdirSync(path.join(window.noted.storagedir, "Notebooks", list));
          order = [];
          i = 0;
          while (i < data.length) {
            if (data[i].substr(data[i].length - 4, data[i].length) === ".txt") {
              name = data[i].substr(0, data[i].length - 4);
              time = new Date(fs.statSync(path.join(window.noted.storagedir, "Notebooks", list, name + '.txt'))['mtime']);
              fd = fs.openSync(path.join(window.noted.storagedir, "Notebooks", list, name + '.txt'), 'r');
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
      note: function(selector) {
        window.noted.currentNote = $(selector).find("h2").text();
        return fs.readFile(path.join(window.noted.storagedir, "Notebooks", $(selector).attr("data-list"), window.noted.currentNote + '.txt'), 'utf-8', function(err, data) {
          var noteTime, time;
          if (err) throw err;
          $("#content").removeClass("deselected");
          $('.headerwrap .left h1').text(window.noted.currentNote);
          noteTime = fs.statSync(path.join(window.noted.storagedir, "Notebooks", $(selector).attr("data-list"), window.noted.currentNote + '.txt'))['mtime'];
          time = new Date(Date.parse(noteTime));
          $('.headerwrap .left time').text(window.noted.util.pad(time.getFullYear()) + "/" + (window.noted.util.pad(time.getMonth() + 1)) + "/" + time.getDate() + " " + window.noted.util.pad(time.getHours()) + ":" + window.noted.util.pad(time.getMinutes()));
          $("#contentread").html(marked(data)).show();
          window.noted.editor.setValue(data);
          window.noted.editor.setReadOnly(true);
          if (selector.hasClass("edit")) {
            window.noted.editMode("editor");
            $("#content .left h1").focus();
            return selector.removeClass("edit");
          } else {
            return window.noted.editMode("preview");
          }
        });
      }
    },
    osdirs: function() {
      if (process.platform === 'darwin') {
        return path.join(window.noted.homedir, "/Library/Application Support/Noted/");
      } else if (process.platform === 'win32') {
        return path.join(process.env.LOCALAPPDATA, "/Noted/");
      } else if (process.platform === 'linux') {
        return path.join(window.noted.homedir, '/.config/Noted/');
      }
    },
    UIEvents: {
      clickNewNote: function() {
        var name, r;
        name = "Untitled Note";
        if (window.noted.currentList !== "All Notes") {
          while (fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + ".txt"))) {
            r = /\(\s*(\d+)\s*\)$/;
            if (r.exec(name) === null) {
              name = name + " (1)";
            } else {
              name = name.replace(" (" + r.exec(name)[1] + ")", " (" + (parseInt(r.exec(name)[1]) + 1) + ")");
            }
          }
          return fs.writeFile(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt'), "This is your new blank note\n====\nAdd some content!", function() {
            return window.noted.load.notes(window.noted.currentList, "", function() {
              return $("#notes ul li:first").addClass("edit").trigger("click");
            });
          });
        }
      },
      modalclickDel: function() {
        $('.modal.delete').modal("hide");
        if (window.noted.currentNote !== "") {
          return fs.unlink(path.join(window.noted.storagedir, "Notebooks", $("#notes li[data-id='" + window.noted.currentNote + "']").attr("data-list"), window.noted.currentNote + '.txt'), function(err) {
            if (err) throw err;
            window.noted.deselect();
            return window.noted.load.notes(window.noted.currentList);
          });
        }
      },
      clickDelNote: function() {
        return $('.modal.delete').modal();
      },
      titlebarClose: function() {
        return window.noted.window.close();
      },
      titlebarMinimize: function() {
        return window.noted.window.minimize();
      },
      titlebarMaximize: function() {
        return window.noted.window.maximize();
      },
      keydownNotebook: function(e) {
        var name, regexp;
        name = $('#notebooks input').val();
        if (e.keyCode === 13) {
          e.preventDefault();
          while (fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt')) === true) {
            regexp = /\(\s*(\d+)\s*\)$/;
            if (regexp.exec(name) === null) {
              name = name + " (1)";
            } else {
              name = name.replace(" (" + regexp.exec(name)[1] + ")", " (" + (parseInt(regexp.exec(name)[1]) + 1) + ")");
            }
          }
          fs.mkdir(path.join(window.noted.storagedir, "Notebooks", name));
          window.noted.load.notebooks();
          return $('#notebooks input').val("").blur();
        }
      },
      clickNotebook: function(element) {
        element.parent().find(".selected").removeClass("selected");
        element.addClass("selected");
        window.noted.load.notes(element.text());
        return window.noted.deselect();
      },
      keydownTitle: function(e, element) {
        var name, r, _ref;
        if (e.keyCode === 13) {
          e.preventDefault();
          name = element.text();
          while (fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt'))) {
            r = /\(\s*(\d+)\s*\)$/;
            if (r.exec(name) === null) {
              name = name + " (1)";
            } else {
              name = name.replace(" (" + r.exec(name)[1] + ")", " (" + (parseInt(r.exec(name)[1]) + 1) + ")");
            }
            console.log(name);
          }
          fs.rename(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, window.noted.currentNote + '.txt'), path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt'));
          window.noted.currentNote = name;
          window.noted.load.notes(window.noted.currentList);
          return element.blur();
        } else if (_ref = e.keyCode, __indexOf.call(window.noted.reservedchars, _ref) >= 0) {
          return e.preventDefault();
        }
      },
      keyupTitle: function(element) {
        var name;
        name = element.text();
        while (fs.existsSync(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt')) === true) {
          name = name + "_";
        }
        $("#notes [data-id='" + window.noted.currentNote + "']").attr("data-id", name).find("h2").text(element.text());
        if (name !== "") {
          console.log("renaming note");
          console.log(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, window.noted.currentNote + '.txt'));
          console.log(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt'));
          fs.rename(path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, window.noted.currentNote + '.txt'), path.join(window.noted.storagedir, "Notebooks", window.noted.currentList, name + '.txt'));
          return window.noted.currentNote = name;
        }
      },
      clickNote: function(element) {
        $("#notes .selected").removeClass("selected");
        element.addClass("selected");
        return window.noted.load.note(element);
      }
    },
    util: {
      pad: function(n) {
        if (n < 10) {
          return "0" + n;
        } else {
          return n;
        }
      }
    }
  };

  window.noted.init();

}).call(this);
