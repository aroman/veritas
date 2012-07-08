window.Router = Backbone.Router.extend

  current_view: null

  routes:
    "find/:kind":     "find"
    "groups/:id":     "group"

  initialize: () ->
    # @find()

  find: (kind) ->
    $('#welcome').hide()

    unless _.isNull @current_view
      @current_view.remove()

    if kind is "groups"
      @current_view = new FindPeopleView()    
    else
      @current_view = new FindGroupsView()

  group: (id) ->
    $('#welcome').hide()
    group = groups.get id

    if not group
      alert "YOU EEEEDIOT! That group doesn't exist!!1one!"

    unless _.isNull @current_view
      @current_view.remove()

    @current_view = new GroupView model: group
    @trigger "highlight"