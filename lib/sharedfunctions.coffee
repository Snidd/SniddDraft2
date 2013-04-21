@getCurrentUserEmail = ->
	user = Meteor.user()
	if user isnt undefined
		for email in user.emails
			return email.address
	return ""