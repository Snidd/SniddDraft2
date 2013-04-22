class @Pick
	constructor: (@cardName, @member) ->

class @Member
	constructor: (meteorUser) ->
		@id = meteorUser._id
		@email = meteorUser.emails[0].address