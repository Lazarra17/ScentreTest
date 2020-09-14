trigger PropertyTrigger on Property__c (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(PropertyTriggerHandler.class); 
}