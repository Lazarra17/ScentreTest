trigger ContentVersionTrigger on ContentVersion (after delete, after insert, after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(ContentVersionTriggerHandler.class); 
}