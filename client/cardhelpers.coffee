#if getCurrentUserEmail() is "m.kjellberg@gmail.com" 

Template.cards.helpers
	cards: ->
		return Cards.find({}).fetch()

Template.cards.rendered = ->
	Meteor.defer ->
		Meteor.subscribe "cards"

Template.cards.events
	'click .addcards' : (event) ->
		textValue = document.getElementById('xmlinput').value
		xmlObject = parseXml textValue
		cards = xmlObject.getElementsByTagName('card')
		for card in cards
			newCard = {}
			for child in card.childNodes
				switch child.nodeName
					when "id" then newCard.mtgid = child.textContent
					when "name" then newCard.name = child.textContent
					when "type" then newCard.type = child.textContent
					when "manacost" then newCard.manacost = child.textContent
					when "set" then newCard.sets = [child.textContent]
			old = Cards.findOne
				name: newCard.name
			if old is undefined
				Cards.insert newCard
				console.log "Card: #{newCard.name} added!"
			else
				newSet = newCard.sets[0]
				setAlreadyExists = old.sets.some (s) -> s is newSet
				if not setAlreadyExists
					old.sets.push newSet
					Cards.update _id:old._id, {"$set":{ "sets" : old.sets}}
					console.log "Added set: #{newSet}"
				console.log "Card: #{newCard.name} already exists"
		return false
	'submit #scanSetForm' : (event) ->
		setAbb = document.getElementById('setAbbrevation').value
		setName = document.getElementById('setName').value
		console.log "Adding #{setName} (#{setAbb})"
		Meteor.call "addSet", setName, setAbb
		false

parseXml = (xmlStr) ->
	return (new window.DOMParser()).parseFromString(xmlStr, "text/xml")