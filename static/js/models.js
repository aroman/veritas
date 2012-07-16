// Generated by CoffeeScript 1.3.3
(function() {

  window.Group = Backbone.Model.extend({
    idAttribute: "_id",
    urlRoot: "group",
    initialize: function() {
      this.ioBind('update', this.set);
      return this.set({
        unread: 0
      });
    }
  });

  window.Groups = Backbone.Collection.extend({
    url: "groups",
    model: Group,
    initialize: function() {
      var _this = this;
      return this.ioBind('add', function(group) {
        return _this.add(group);
      });
    },
    comparator: function(group) {
      return group.get("flag") || group.get("name");
    }
  });

}).call(this);
