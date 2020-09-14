trigger PropertyMapsTrigger on PropertyMaps__c (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(PropertyMapsTriggerHandler.class);
}