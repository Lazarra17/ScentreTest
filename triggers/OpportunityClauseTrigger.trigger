trigger OpportunityClauseTrigger on OpportunityClause__c (after delete, after insert, after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(OpportunityClauseTriggerHandler.class);
}