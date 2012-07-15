// Generated by CoffeeScript 1.3.3
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
      this.$el.show();
      this.$el.html(Handlebars.templates.finder({
        selected: this.selected
      }));
      return this.$("#thebox").focus();
    },
    go: function(e) {
      var ack,
        _this = this;
      $(e.target).button("loading");
      this.$(":input").prop('disabled', true);
      ack = function(err) {
        console.log("ack");
        if (err) {
          $(e.target).button('reset');
          _this.$(":input").prop('disabled', false);
          console.log("fail");
          return _this.$("#error").show();
        } else {
          return window.location.replace("" + location.origin + "/lounge");
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
        matches = harvard_courses.filter(function(course) {
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
      this.$el.show();
      this.$('.inner').html(Handlebars.templates.group(this.colorize(this.model.toJSON())));
      this.$("#messages").scrollTop(1234567890);
      this.$("#chat-input").focus();
      this.model.set({
        unread: 0
      });
      return app.updateGroupList();
    },
    getColor: function(username) {
      if (!_.has(this.colors, username)) {
        this.colors[username] = this.color_bank[Math.floor(Math.random() * this.color_bank.length)];
      }
      return this.colors[username];
    },
    colorize: function(group) {
      var colorized,
        _this = this;
      colorized = [];
      _.each(group.messages, function(message) {
        message.color = _this.getColor(message.username);
        return colorized.push(message);
      });
      group.messages = colorized;
      return group;
    },
    pushMessage: function(message) {
      var str;
      str = '<p><span style="color:' + this.getColor(message.username) + '">' + message.username + ': </span>' + message.body + '</p>';
      this.$("#messages").append(str);
      return this.$("#messages").scrollTop(1234567890);
    },
    addMessage: function(e) {
      var message,
        _this = this;
      if (e.keyCode === 13) {
        message = this.$(e.target).val();
        this.$(e.target).val('');
        if (message) {
          return socket.emit("group:message", this.model.id, message, function(err, res) {
            if (err) {
              return alert("Oh snap. Something broke. You should yell at Avi.");
            } else {
              return _this.render;
            }
          });
        }
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
    username: null,
    events: {
      "click a[data-route]": "routeInternal"
    },
    initialize: function() {
      var _this = this;
      this.updateGroupList();
      router.on('highlight', this.highlightSidebar, this);
      groups.on("add remove", this.updateGroupList, this);
      socket.on("online", function(people) {
        console.log(people);
        return _this.updatePersonList(people);
      });
      return socket.on("message", function(data) {
        var group;
        group = groups.get(data.group);
        group.get('messages').push(data.message);
        if (router.current_view && router.current_view.model.id === group.id) {
          console.log("We're currently viewing this group");
          return router.current_view.pushMessage(data.message);
        } else {
          console.log("Not currently viewing");
          group.set({
            unread: group.get('unread') + 1
          });
          return _this.updateGroupList();
        }
      });
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
