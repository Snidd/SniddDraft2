Meteor.publish 'drafts', ->
	Drafts.find({})

Meteor.publish 'cards', ->
	Cards.find({})

@Drafts.allow
	insert: (userId, draft) ->
		userId and draft.owner is userId
	update: (userId, draft, fields, modified) ->
		if typeIsArray(draft) is true then return false
		if userId isnt draft.owner then return false
		allowed = ["name", "public"]
		if _.difference(fields, allowed).length > 0 then return false
		true

@Cards.allow
	insert: (userId, card) ->
		if getCurrentUserEmail() is "m.kjellberg@gmail.com" then return true
		return false
	update: (userId, card) ->
		if getCurrentUserEmail() is "m.kjellberg@gmail.com" then return true
		return false
	remove: (userId, card) ->
		if getCurrentUserEmail() is "m.kjellberg@gmail.com" then return true
		return false

Meteor.methods
	addMemberToDraft: (draftId, emailAddress) ->
		#do stuff here to add member to draft
		draft = Drafts.findOne
			_id: draftId
		if draft.owner isnt Meteor.userId()
			throw new Meteor.Error 505, "No access"
		userId = undefined
		if draft.started then throw new Meteor.Error 500, "Cannot add member to started draft"
		emailExists = false
		for member in draft.members when member.email is emailAddress
			throw new Meteor.Error 405, "Cannot add member twice"
		for user in Meteor.users.find({}).fetch()
			for email in user.emails
				if email.address is emailAddress then userId = user._id
			if userId isnt undefined then break
		if userId is undefined then throw new Meteor.Error 404, "Email address not found"
		draft.members.push
			id: userId
			email: emailAddress
		Drafts.update _id:draftId, draft
		draft
	removeEmailFromDraft: (draftId, emailAddress) ->
		draft = Drafts.findOne
			_id: draftId
		if draft.owner isnt Meteor.userId()
			throw new Meteor.Error 505, "No access"
		if draft.started
			throw new Meteor.Error 500, "Cannot remove members from started drafts"
		if emailAddress is getCurrentUserEmail()
			throw new Meteor.Error 501, "Cannot remove yourself!"
		newMembers = draft.members.filter	(member) -> member.email isnt emailAddress
		draft.members = newMembers
		Drafts.update _id:draftId, draft
		draft
	startDraft: (draftId) ->
		draft = Drafts.findOne
			_id: draftId
		if draft.owner isnt Meteor.userId()
			throw new Meteor.Error 505, "No access"
		draft.started = true
		draft.members = fisherYates(draft.members)
		draft.picks = []
		Drafts.update _id:draftId, draft
		draft
	removeDraft: (draftId) ->
		draft = Drafts.findOne
			_id: draftId
		if draft.owner isnt Meteor.userId()
			throw new Meteor.Error 505, "No access"
		allowRemove = false
		if not draft.started then allowRemove = true
		if draft.finished then allowRemove = true
		if allowRemove
			Drafts.remove
				_id:draftId
		throw new Meteor.Error 506, "Unable to remove that draft"
	pickCard: (cardName, draftId) ->
		draft = Drafts.findOne
			_id: draftId
		if not currentUserInDraft(draft) then throw new Meteor.Error 505, "No access"
		pickPosition = getNextPickPosition(draft.picks.length,draft.members.length)
		if draft.members[pickPosition].id isnt Meteor.userId()
			return addFuturePick(cardName, userId)
		pick = new Pick(cardName, new Member(Meteor.user()))
		draft.picks.push(pick);
		Drafts.update _id:draftId, draft
		draft

addFuturePick = (cardName, userId) ->
	return true

currentUserInDraft = (draft) ->
	draft.members.some (m) -> m.id is Meteor.userId()

fisherYates = (arr) ->
    i = arr.length;
    if i == 0 then return false
 
    while --i
        j = Math.floor(Random.fraction() * (i+1))
        tempi = arr[i]
        tempj = arr[j]
        arr[i] = tempj
        arr[j] = tempi
    return arr

typeIsArray = ( value ) ->
    value and
        typeof value is 'object' and
        value instanceof Array and
        typeof value.length is 'number' and
        typeof value.splice is 'function' and
        not ( value.propertyIsEnumerable 'length' )

checkEmailExists = (emailAddress) ->
	for user in Meteor.users
		for email in user.emails
			if email is emailAddress then return true
	return false