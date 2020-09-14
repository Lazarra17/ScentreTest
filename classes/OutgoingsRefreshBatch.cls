global class OutgoingsRefreshBatch implements Database.Batchable<sObject>, Database.Stateful{
    private Set<Id> opportunityIdSet;
    
    global OutgoingsRefreshBatch(Set<Id> opportunityIdSet){
        this.opportunityIdSet = opportunityIdSet;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(
            [SELECT Id, Name, ProposedRentCommencementDate__c
             	FROM Opportunity 
             	WHERE Id IN: opportunityIdSet]
        );
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> opportunityList){
        Map<Id, List<OpportunityLineItem>> oppIdOppLineItemListMap = new Map<Id, List<OpportunityLineItem>>();
        TriggerHandler.bypass(OpportunityTriggerHandler.class.getName());
        TriggerHandler.bypass(OpportunityLineItemTriggerHandler.class.getName());
        oppIdOppLineItemListMap = OutgoingsRefreshController.refreshOpportunityLineItem(opportunityList);
    }

    global void finish(Database.BatchableContext BC){
        
    }
}