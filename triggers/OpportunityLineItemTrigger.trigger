trigger OpportunityLineItemTrigger on OpportunityLineItem (after delete, after insert, after update, before delete, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(OpportunityLineItemTriggerHandler.class);
}