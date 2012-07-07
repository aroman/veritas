window.FinderView = Backbone.View.extend
  el: ("#finder")

  events:
    "keyup #thebox": "search"
    "click .create-group": "createGroup"

  initialize: () ->
    @$("#results").html "Start typing <3"

  showGroups: (models) ->
    @$("#results").html Handlebars.templates.foobar(groups: models)

  createGroup: (e) ->
    name = $(e.target).data("name")
    group = new Group name: name
    groups.add group
    group.save()

  search: (e) ->
    fragment = @$("#thebox").val()
    if fragment
      matches = groups.filter (group) ->
        ~group.get('name').indexOf fragment
      if matches.length > 0
        @showGroups matches
      else
        @$("#results").html Handlebars.templates.no_groups(name: fragment)
    else
      @$("#results").html "Start typing <3"

window.AppView = Backbone.View.extend
  el: $("body")

  initialize: () ->
    @finder = new FinderView()
    @updateGroupList()
    groups.on "add remove", @updateGroupList, this
    socket.on "online", (people) =>
      @updatePersonList people

  updateGroupList: () ->
    @$("#groups").html Handlebars.templates.sidebar_groups(groups: groups.toJSON())

  updatePersonList: (people) ->
    @$("#people").html Handlebars.templates.sidebar_people(people: people)