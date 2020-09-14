global class copyPropertyStateOnOpportunityBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Space__c, Property__c, Space__r.Property__r.PropertyState__c FROM Opportunity WHERE Space__c != null'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope){
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        for(Opportunity opp : scope){
            if(opp.Space__c != null && opp.space__r.Property__c != null && opp.space__r.Property__r.PropertyState__c != null)
            {
                opp.Tech_PropertyState__c = opp.Space__r.Property__r.PropertyState__c;
                oppListToUpdate.add(opp);
            }
        }
        update oppListToUpdate;
    }
    
    global void finish(Database.BatchableContext bc){
        
    }   
}