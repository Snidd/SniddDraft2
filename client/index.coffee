getMyDrafts = ->
	email = getCurrentUserEmail()
	return Drafts.find 
		"members.email": email
		started: true
		finished: false

Template.index.helpers
	mydrafts: ->
		if Meteor.userId()
			return getMyDrafts()
		else
			return false
	isActive: (draft) ->
		if draft._id is Session.get("currentDraftId")
			return "active"
		else
			return ""
	waitingforme: ->
		if Meteor.userId()
			drafts = getMyDrafts().fetch()
			drafts = drafts.filter (draft) ->
				getCurrentUserEmail() is draft.members[getNextPickPosition(draft.picks.length, draft.members.length)].email
			return drafts;
		else
			return false
	notstarted: ->
		if Meteor.userId()
			notStarted = Drafts.find({owner: Meteor.userId(), started: false}).fetch()
			if notStarted.length is 0 then return false
			return notStarted
		else
			return false