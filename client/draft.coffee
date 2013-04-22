Template.draftInProgress.rendered = ->
  Meteor.defer ->
    jsPlumb.ready ->
      jsPlumb.Defaults.Anchors =
        ["RightMiddle", "LeftMiddle"]
      jsPlumb.Defaults.Endpoint =
        "Blank"
      jsPlumb.Defaults.Connector =
        ["Flowchart", 25]
      jsPlumb.Defaults.Overlays =
        ["Arrow"]
      jsPlumb.Defaults.PaintStyle =
        lineWidth: 2,
        strokeStyle: "#000"
      console.log "plumbing!"
      jsPlumb.connect
        source: "future0"
        target: "pick1"
        connector: [ "Flowchart", 25 ],
        anchors: ["TopCenter", "TopCenter"]
      jsPlumb.connect
        source: "future0"
        target: "info1"
        connector: [ "Flowchart", 25 ],
        anchors: ["RightMiddle", "LeftMiddle"]

Template.draftInProgress.events
  'click .btn.pickcard' : ->
    pickCardField = document.getElementById('pickCard')
    cardName = pickCardField.value
    console.log "Picking #{cardName}"
    Meteor.call "pickCard", cardName, Session.get("currentDraftId"), (error, result) ->
      switch error?.error
        when 404
          console.log "Card not found"
        when 505
          console.log "No access"
        when 601
          console.log "Card already picked"
      true
    pickCardField.value = ''
Template.draftInProgress.helpers
  pickOrder: ->
    currentDraft = getCurrentDraft()
    for i in [0..currentDraft.members.length*4] by 1
      pickPosition = getNextPickPosition(i + currentDraft.picks.length , currentDraft.members.length)
      pick = {}
      pick.id = currentDraft.members[pickPosition].id
      pick.email = currentDraft.members[pickPosition].email
      pick.counter = i
      pick.cssclass = if pick.id is Meteor.userId() then "self" else "player#{pickPosition}" 
      pick
  pickHistory: ->
    currentDraft = getCurrentDraft()
    if !currentDraft.picks? or currentDraft.length is 0 
      return [new Pick("", "No picks yet")]
    else
      return currentDraft.picks.reverse()




