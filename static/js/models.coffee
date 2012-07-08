window.Group = Backbone.Model.extend
  idAttribute: "_id"
  urlRoot: "group"

  initialize: () ->
    @ioBind 'update', this.set
    # We need to default this
    # since the field doesn't
    # exist server-side.
    @set unread: 0


window.Groups = Backbone.Collection.extend

  url: "groups"
  model: Group

  initialize: () ->
    @ioBind 'add', (group) =>
      @add group

  comparator: (group) ->
    group.get "name"