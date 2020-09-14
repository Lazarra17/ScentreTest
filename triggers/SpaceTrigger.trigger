trigger SpaceTrigger on Space__c (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(SpaceTriggerHandler.class);
}