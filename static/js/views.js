// Generated by CoffeeScript 1.3.3
(function() {
  var linkify,
    _this = this,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  linkify = function(text) {
    var replacePattern1, replacePattern2, replacePattern3, replacedText;
    replacePattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim;
    replacedText = text.replace(replacePattern1, '<a href="$1" target="_blank">$1</a>');
    replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim;
    replacedText = replacedText.replace(replacePattern2, '$1<a href="http://$2" target="_blank">$2</a>');
    replacePattern3 = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,6})/gim;
    replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>');
    return replacedText;
  };

  Handlebars.registerHelper("render_message", function(o) {
    return "<p>\n  <a href=\"/people/" + o.person_id + "\" style=\"color:" + o.color + "\"> " + o.first + "</a>: " + (linkify(o.body)) + "\n</p>";
  });

  window.ChooseView = Backbone.View.extend({
    el: "#choose",
    selected: [],
    events: {
      "keyup #thebox": "search",
      "click .join-group": "joinGroup",
      "click .leave-group": "leaveGroup",
      "click #go": "go"
    },
    initialize: function() {
      return this.render();
    },
    render: function() {
      var _this = this;
      this.$el.show();
      this.$el.html(Handlebars.templates.finder({
        selected: this.selected
      }));
      return _.delay(function() {
        return _this.$("#thebox").focus();
      }, 10);
    },
    go: function(e) {
      var ack,
        _this = this;
      $(e.target).button("loading");
      this.$(":input").prop('disabled', true);
      ack = function(err) {
        if (err) {
          $(e.target).button('reset');
          _this.$(":input").prop('disabled', false);
          return _this.$("#error").show();
        } else {
          return window.location.replace("" + location.protocol + "//" + location.host + "/lounge");
        }
      };
      return socket.emit("join groups", _.pluck(this.selected, "_id"), ack);
    },
    joinGroup: function(e) {
      var course, id, index, _i, _len;
      id = $(e.target).data("id");
      this.selected.push({
        _id: id,
        name: $(e.target).text()
      });
      for (index = _i = 0, _len = harvard_courses.length; _i < _len; index = ++_i) {
        course = harvard_courses[index];
        if (course._id === id) {
          harvard_courses[index].selected = true;
          break;
        }
      }
      return this.render();
    },
    leaveGroup: function(e) {
      var course, group, id, index, _i, _len;
      id = $(e.target).data("id");
      group = _.find(this.selected, function(group) {
        return group._id === id;
      });
      this.selected.splice(_.indexOf(this.selected, group), 1);
      for (index = _i = 0, _len = harvard_courses.length; _i < _len; index = ++_i) {
        course = harvard_courses[index];
        if (course._id === id) {
          delete harvard_courses[index].selected;
          break;
        }
      }
      return this.render();
    },
    showGroups: function(models) {
      return this.$("#results").html(Handlebars.templates.foobar({
        groups: models
      }));
    },
    search: function(e) {
      var fragment, matches;
      fragment = this.$("#thebox").val();
      if (fragment.length) {
        matches = _.filter(harvard_courses, function(course) {
          return course.name.toLowerCase().indexOf(fragment.toLowerCase()) !== -1;
        });
        if (matches.length > 0) {
          this.showGroups(matches);
          return this.$("#thebox").parent().removeClass("error");
        } else {
          this.$("#results").html(Handlebars.templates.no_groups({
            name: fragment
          }));
          return this.$("#thebox").parent().addClass("error");
        }
      } else {
        return this.render();
      }
    },
    remove: function() {
      this.$el.hide();
      this.$el.children().remove();
      return this;
    }
  });

  window.GroupView = Backbone.View.extend({
    el: "#group",
    color_bank: ["#C91371", "#6477CA", "#869A80", "#F79B06", "#CE9F9F", "#1EA3D2", "#A2C085", "#87BB06", "#BD1FFC", "#3FCECB", "#F8D19E", "#48EE59", "#A8E947", "#11A0E1", "#DAD2AD", "#FAC528", "#D92A53", "#EED516", "#F3322A", "#579C94"],
    colors: {},
    events: {
      "keyup #chat-input": "addMessage"
    },
    initialize: function() {
      return this.render();
    },
    render: function() {
      var _this = this;
      this.$el.show();
      this.$('.inner').html(Handlebars.templates.group(this.colorize(this.model.toJSON())));
      if (this.model.get('messages').length === 0) {
        this.$("#messages").html("<div id=\"emptybit\" class=\"centex\">\n  <i>No messages yet :'(\n</div>");
      }
      _.delay(function() {
        return _this.$("#chat-input").focus();
      }, 10);
      this.scrollBottom();
      this.model.set({
        unread: 0
      });
      return app.updateGroupList();
    },
    scrollBottom: function() {
      var cache;
      cache = this.$("#messages");
      return cache.scrollTop(cache[0].scrollHeight);
    },
    getColor: function(person_id) {
      if (!_.has(this.colors, person_id)) {
        this.colors[person_id] = this.color_bank[Math.floor(Math.random() * this.color_bank.length)];
      }
      return this.colors[person_id];
    },
    colorize: function(group) {
      var colorized,
        _this = this;
      colorized = [];
      _.each(group.messages, function(message) {
        message.color = _this.getColor(message.person_id);
        return colorized.push(message);
      });
      group.messages = colorized;
      return group;
    },
    pushMessage: function(message) {
      this.$("#emptybit").hide();
      message.color = this.getColor(message.person_id);
      this.$("#messages").append(Handlebars.helpers.render_message(message));
      return this.scrollBottom();
    },
    addMessage: function(e) {
      var body,
        _this = this;
      if (e.keyCode === 13) {
        body = this.$(e.target).val();
        if (!body) {
          return;
        }
        this.$(e.target).prop("disabled", true);
        return socket.emit("group:message", this.model.id, body, function(err) {
          _this.$(e.target).prop("disabled", false);
          if (err) {
            if (err === "length") {
              return alert("Message too large (> 1000 characters) to post.");
            } else {
              return alert("Message failed for an unknown reason. Yell at Avi.");
            }
          } else {
            _.delay(function() {
              return _this.$("#chat-input").focus();
            }, 10);
            return _this.$(e.target).val('');
          }
        });
      }
    },
    remove: function() {
      this.$el.hide();
      this.$el.children().empty();
      this.undelegateEvents();
      return this;
    }
  });

  window.AppView = Backbone.View.extend({
    el: "body",
    base_title: "The Lounge",
    count: 0,
    focus: true,
    events: {
      "click a[data-route]": "routeInternal"
    },
    initialize: function() {
      var _this = this;
      this.updateGroupList();
      router.on('highlight', this.highlightSidebar, this);
      groups.on("add remove", this.updateGroupList, this);
      socket.emit("get online", function(people) {
        return _this.updatePersonList(people);
      });
      socket.on("online", function(people) {
        return _this.updatePersonList(people);
      });
      socket.on("message", function(data) {
        var group;
        group = groups.get(data.group);
        group.get('messages').push(data.message);
        if (router.current_view && router.current_view.model.id === group.id) {
          return router.current_view.pushMessage(data.message);
        } else {
          group.set({
            unread: group.get('unread') + 1
          });
          _this.count += 1;
          _this.updateGroupList();
          return _this.flashTitle();
        }
      });
      $(window).resize(_.throttle(function() {
        if (router.current_view) {
          return router.current_view.scrollBottom();
        }
      }, 100));
      $(window).focus(function() {
        _this.focus = true;
        return _this.count = 0;
      });
      return $(window).focusout(function() {
        return _this.focus = false;
      });
    },
    flashTitle: function() {
      if (!this.focus) {
        return document.title = "(" + this.count + ") " + this.base_title;
      }
    },
    routeInternal: function(e) {
      var href, protocol, target;
      target = $(e.target);
      href = target.attr("href");
      protocol = window.location.protocol + "//";
      if (href && href[{
        0: protocol.length
      }] !== protocol && __indexOf.call(href, "javascript:") < 0) {
        e.preventDefault();
        return router.navigate(href, true);
      }
    },
    updateGroupList: function() {
      this.$("#groups").html(Handlebars.templates.sidebar_groups({
        groups: groups.toJSON()
      }));
      return this.highlightSidebar();
    },
    updatePersonList: function(people) {
      return this.$("#people").html(Handlebars.templates.sidebar_people({
        people: people
      }));
    },
    highlightSidebar: function() {
      this.$('li.active:not(.nav-link)').removeClass('active');
      return this.$("a[href='/" + Backbone.history.fragment + "']").parent().addClass('active');
    }
  });

}).call(this);
