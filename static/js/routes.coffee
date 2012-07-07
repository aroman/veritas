window.Router = Backbone.Router.extend

  current_view: null

  routes:
    "":               "home"
    "groups/:id":     "group"

  initialize: () ->
    @home()

  home: () ->
    unless _.isNull this.current_view
      @current_view.remove()

    @current_view = new FinderView()    

  group: (id) ->
    group = groups.get id

    if not group
      alert "YOU EEEEDIOT! That group doesn't exist!!1one!"

    unless _.isNull this.current_view
      @current_view.remove()

    @current_view = new GroupView model: group