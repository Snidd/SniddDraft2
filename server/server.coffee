Meteor.publish 'drafts', ->
	Drafts.find({})

Meteor.publish 'cards', ->
	Cards.find({})

Meteor.publish 'futurepicks', ->
	FuturePicks.find({ userId: this.userId })

#userId: this.userId

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

@FuturePicks.allow
	insert: (userId, futurepick) ->
		if userId is futurepick.userId then return true
		return false
	update: (userId, fp) ->
		if fp.userId is userId then return true
		return false

Meteor.methods
	setImportant: (draftId, cardName, important) ->
		fp = FuturePicks.findOne
      userId: Meteor.userId()
      draftId: draftId
    if !fp? then throw new Meteor.Error 404, "Not found"

    fpid = fp._id

    FuturePicks.update({
        _id: fpid
        "picks.name" : cardName
      },
      {
        "$set" : {
          "picks.$.important" : important
        }
      })
	removeFuturePick: (cardName, draftId) ->
		fps = FuturePicks.findOne
			userId: Meteor.userId()
			draftId: draftId
		fps.picks = fps.picks.filter (p) ->
			p.name isnt cardName
		FuturePicks.update _id: fps._id, fps

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
		pickCard cardName, draftId, Meteor.userId()

pickCard = (cardName, draftId, userId) ->
	draft = Drafts.findOne
		_id: draftId
	if not userInDraft(draft, userId) then throw new Meteor.Error 505, "User not in draft, cant pick"
	card = getCard cardName
	
	if !card? then throw new Meteor.Error 404, "Card not found"
	
	if cardAlreadyPicked(draft, cardName) then throw new Meteor.Error 601, "Card already picked"
	
	pickPosition = getNextPickPosition(draft.picks.length,draft.members.length)
	
	if draft.members[pickPosition].id isnt userId
		fp = FuturePicks.findOne
			userId: userId
			draftId: draftId
		if !fp?
			fp = new FuturePick(userId, draftId)
			result = FuturePicks.insert fp
		if (fp.picks.some (p) -> p.name is cardName)
			throw new Meteor.Error 601, "Card already picked"
		newPick = new FutureCard(cardName, card.manacost)

		FuturePicks.update { _id: fp._id },
			"$push": { "picks" : newPick }
	else
		newPick = new Pick(card, new Member(getMember(userId)), draftId, pickPosition)
		Drafts.update { _id: draftId },
			"$push": { "picks" : newPick }

		pickPosition = getNextPickPosition(draft.picks.length+1,draft.members.length)
		nextPick = getNextFuturePick(draft.members[pickPosition].id, draftId)
		if nextPick? and nextPick.length > 0
			pickCard nextPick, draftId, draft.members[pickPosition].id
	draft	

getNextFuturePick = (userId, draftId) ->
	fp = FuturePicks.findOne
		userId: userId
		draftId: draftId

	draft = Drafts.findOne
		_id: draftId

	if !fp? or fp.picks.length is 0 then return undefined
	
	futurePick = fp.picks[0]

	while cardAlreadyPicked(draft, futurePick.name) 
		fp.picks.shift()
		if futurePick.important then return undefined
		futurePick = fp.picks[0]
		if fp.picks.length is 0 then break

	if cardAlreadyPicked(draft, futurePick.name) then return undefined

	fp.picks.shift()

	FuturePicks.update _id: fp._id, fp

	return futurePick.name


getMember = (userId) ->
	Meteor.users.findOne
		_id: userId

getCard = (cardName) ->
	card = Cards.findOne
		name: cardName

addFuturePick = (cardName, userId) ->
	return true

userInDraft = (draft, userId) ->
	draft.members.some (m) -> m.id is userId

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