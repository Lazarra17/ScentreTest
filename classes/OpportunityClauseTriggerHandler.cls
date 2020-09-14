/**
* Class OpportunityClauseTriggerHandler
*
* Trigger Handler for the OpportunityClause__c SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*
*
*/
public without sharing class OpportunityClauseTriggerHandler extends TriggerHandler implements ITrigger {
    
    public List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();

    public OpportunityClauseTriggerHandler(){}
    
        /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){  
        //RPP - 10985
        if(trigger.isinsert || trigger.isUpdate){
            clauseLibList = DatabaseSOQLBank.getLevyClause();
        }
    }
    
    public void bulkAfter(){
        
        // After Insert, Update, and Delete

        Set<Id> oppIdSet = new Set<Id>();
        
        List<OpportunityClause__c> oppClauseList = (List<OpportunityClause__c>) (Trigger.isDelete ? Trigger.old : Trigger.new);
        
        for (OpportunityClause__c oppClause : oppClauseList) {
            
            OpportunityClause__c oldOppClause = Trigger.isUpdate ? (OpportunityClause__c) Trigger.oldMap.get(oppClause.Id) : null;
            
            
            if((Trigger.isUpdate && (oldOppClause.RiskApplies__c != oppClause.RiskApplies__c || oldOppClause.Approved__c != oppClause.Approved__c)) || 
               ((Trigger.isDelete || Trigger.isInsert) && oppClause.RiskApplies__c && !oppClause.Approved__c)) {
                oppIdSet.add(oppClause.Opportunity__c);
            }
        }
        
        if (oppIdSet.size() > 0) {
            OpportunityClauseBL.updateOpportunityClauseSummary(oppIdSet);    
        }
        
        
        
    }

    public void beforeInsert(SObject so) {
        //RPP - 10985
        OpportunityClause__c oppClause = (OpportunityClause__c) so;
        
        if((oppClause.Name == Constants.OPPORTUNITY_CLAUSE_NO_PROMOTION_FUND_APPLICABLE
            ||oppClause.Name == Constants.OPPORTUNITY_CLAUSE_CHANGE_IN_PROMOTION_LEVY) 
           && oppClause.RiskApplies__c == TRUE
           && (!clauseLibList.isEmpty())){
               oppClause.ReferencedClause__c = clauseLibList[0].Id;
           }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
    }
    
    public void beforeDelete(SObject so) {
    }
    
    public void afterInsert(SObject so) {
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
        
    }
    
    public void afterDelete(SObject so) {
    }
    
    /**
* andFinally
*
* This method is called once all records have been processed by the trigger. Use this
* method to accomplish any final operations such as creation or updates of other records.
*/
    
    public void andFinally() {
    }    
        
}