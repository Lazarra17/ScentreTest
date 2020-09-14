trigger AffiliationTrigger on Affiliation__c (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(AffiliationTriggerHandler.class);
}