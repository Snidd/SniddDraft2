class @Member
	constructor: (meteorUser) ->
		@id = meteorUser._id
		@email = meteorUser.emails[0].address

class @FuturePick
	constructor: (@userId, @draftId) ->
		@picks = []
		@_id = Random.id()

class @FutureCard
	constructor: (@name, @manacost) ->
		@important = false
		@htmlid = Random.id()

class @Pick
	constructor: (@card, @member, @draftId, @playerNumber) ->
		@pickId = Random.id()
		@recent = true
		userIdToPass = @pickId
		draftIdToPass = @draftId
		if Meteor.isServer
			Meteor.setTimeout ->
				pickNoLongerRecent userIdToPass, draftIdToPass
			,10000