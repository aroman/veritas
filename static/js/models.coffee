window.Group = Backbone.Model.extend
  idAttribute: "_id"
  urlRoot: "group"

  initialize: () ->
    @ioBind 'update', this.set

window.Groups = Backbone.Collection.extend

  url: "groups"
  model: Group

  initialize: () ->
    @ioBind 'add', (group) =>
      @add group