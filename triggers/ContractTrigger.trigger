trigger ContractTrigger on Contract__c ( after delete, after insert, after update, before delete, before insert, before update ) {
    TriggerFactory.createAndExecuteHandler(ContractTriggerHandler.class);
}