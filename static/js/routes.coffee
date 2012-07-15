window.Router = Backbone.Router.extend

  current_view: null

  routes:
    "groups/:id":     "group"

  group: (id) ->
    $('#welcome').hide()
    group = groups.get id

    if not group
      alert "YOU EEEEDIOT! That group doesn't exist!!1one!"

    unless _.isNull @current_view
      @current_view.remove()

    @current_view = new GroupView model: group
    @trigger "highlight"