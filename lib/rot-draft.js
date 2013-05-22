// shared stuff

Drafts = new Meteor.Collection("drafts");
Cards = new Meteor.Collection("cards");
Messages = new Meteor.Collection("messages");
FuturePicks = new Meteor.Collection("futurepicks");

if (Meteor.isClient) {
	Meteor.subscribe("futurepicks");
	Meteor.subscribe("drafts");
}
