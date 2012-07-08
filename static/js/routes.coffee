window.Router = Backbone.Router.extend

  current_view: null

  routes:
    "":               "find"
    "find":           "find"
    "groups/:id":     "group"

  initialize: () ->
    # @find()

  find: () ->
    unless _.isNull @current_view
      @current_view.remove()

    @current_view = new FinderView()    

  group: (id) ->
    group = groups.get id

    if not group
      alert "YOU EEEEDIOT! That group doesn't exist!!1one!"

    unless _.isNull @current_view
      @current_view.remove()

    @current_view = new GroupView model: group
    @trigger "highlight"