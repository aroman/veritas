window.Group = Backbone.Model.extend
  idAttribute: "_id"
  urlRoot: "group"

  initialize: () ->
    @ioBind 'update', this.set
    socket.on "group/#{@id}:message", (message) =>
      @get('messages').push message
      @trigger "newmessage"

window.Groups = Backbone.Collection.extend

  url: "groups"
  model: Group

  initialize: () ->
    @ioBind 'add', (group) =>
      @add group

  comparator: (group) ->
    group.get "name"