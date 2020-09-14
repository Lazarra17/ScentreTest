trigger RelatedOpportunityTrigger on RelatedOpportunity__c (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(RelatedOpportunityTriggerHandler.class);
}