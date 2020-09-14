trigger AccountContactRelationTrigger on AccountContactRelation (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(ACRTriggerHandler.class);
}