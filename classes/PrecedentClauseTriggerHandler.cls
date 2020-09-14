/**
* Class PrecedentClauseTriggerHandler
*
* Trigger Handler for the PrecedentClause__c SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class PrecedentClauseTriggerHandler extends TriggerHandler implements ITrigger{
    private Map<Id, List<Opportunity>> opportunityFromAccountMap = new Map<Id, List<Opportunity>>();
    private Map<Id, List<OpportunityClause__c>> opportunityClauseMap = new Map<Id, List<OpportunityClause__c>>();
    private List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
    private Map<String, Schema.RecordTypeInfo> opportunityClauseRecordTypeMapByName = new Map<String, Schema.RecordTypeInfo>();
    //RPP-10989
    private Map<Id, List<Opportunity>> parentAccIdVsOppsMap = new Map<Id, List<Opportunity>>();
    private List<Opportunity> oppListToUpdate = new List<Opportunity>();
     // Constructor
    public PrecedentClauseTriggerHandler()
    {
        opportunityClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OPPORTUNITY_CLAUSE_API);
    }
    
    public void bulkBefore()
    {

        if(Trigger.isInsert || Trigger.isUpdate) {
        }
        
        if(Trigger.isInsert) {
        }
        
        if(Trigger.isUpdate) {
        }
        
    }
    
    public void bulkAfter()
    {
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c();
        Set<Id> precedentClauseAccountIdSet = new Set<Id>();
        if(Trigger.isInsert || Trigger.isUpdate) {
            for(SObject precedentClauseSObject : Trigger.new) {
                precedentClauseRecord = (PrecedentClause__c) precedentClauseSObject;
                precedentClauseAccountIdSet.add(precedentClauseRecord.Account__c);
            }
            
            //RPP-10989
            parentAccIdVsOppsMap = PrecedentClauseBL.buildOppFromAccMap(precedentClauseAccountIdSet);
        }
        
        if(Trigger.isInsert) {
            //START -- RPP-2536 Kyle Tan 5/10/2018
            Set<Id> childAccountIdSet = new Set<Id>();
            opportunityFromAccountMap = PrecedentClauseBL.buildopportunityFromAccountMap(precedentClauseAccountIdSet);
            //END -- RPP-2536 Kyle Tan 5/10/2018
        }
        
        if(Trigger.isUpdate) {
            Set<Id> precedentClauseIdSet = new Set<Id>();
            
            for(SObject newPrecedentClause : Trigger.new) {
                precedentClauseRecord = (PrecedentClause__c) newPrecedentClause;
                if(precedentClauseRecord.Status__c == CONSTANTS.ACTIVE) {
                    precedentClauseIdSet.add(precedentClauseRecord.Id);
                }
            }
            //START -- RPP-2536 Kyle Tan 5/11/2018
            opportunityClauseMap = PrecedentClauseBL.buildOpportunityClauseMap(precedentClauseIdSet);
            //END -- RPP-2536 Kyle Tan 5/11/2018
        }
        
    }
    
    public void beforeInsert(SObject so)
    {
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }
    
    public void beforeDelete(SObject so)
    {
    }
    
    public void afterInsert(SObject so)
    {
        //START -- RPP-2536 Kyle Tan 5/10/2018
        PrecedentClause__c newPrecedentClauseRecord = (PrecedentClause__c) so;
        
        if(newPrecedentClauseRecord.Status__c == CONSTANTS.ACTIVE) {
            if(opportunityFromAccountMap.containsKey(newPrecedentClauseRecord.Account__c)) {
                for(Opportunity opportunityRecord : opportunityFromAccountMap.get(newPrecedentClauseRecord.Account__c)) {
                    opportunityClauseList.add(OpportunityBL.createOpportunityClause(opportunityRecord, 
                                                                                    newPrecedentClauseRecord, 
                                                                                    opportunityClauseRecordTypeMapByName.get(CONSTANTS.PRECEDENT_CLAUSE).getRecordTypeId()));
                }
            }
        }
        //END -- RPP-2536 Kyle Tan 5/10/2018
        
        if(newPrecedentClauseRecord.Nil_Holdover_Increase__c && newPrecedentClauseRecord.Status__c == Constants.ACTIVE){
            if(parentAccIdVsOppsMap.containsKey(newPrecedentClauseRecord.Account__c)){
                for(Opportunity opp : parentAccIdVsOppsMap.get(newPrecedentClauseRecord.Account__c)){
                    opp.Nil_Holdover_Increase__c = newPrecedentClauseRecord.Nil_Holdover_Increase__c;
                    oppListToUpdate.add(opp);
                }
            }
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
        PrecedentClause__c newPrecClauseRec = (PrecedentClause__c) so;
        PrecedentClause__c oldPrecClauseRec = (PrecedentClause__c) oldSo;
        
        //RPP-10989 - START
        if(newPrecClauseRec.Nil_Holdover_Increase__c != oldPrecClauseRec.Nil_Holdover_Increase__c
          && newPrecClauseRec.Status__c == Constants.ACTIVE){
              System.debug('newPrecClauseRec.Account__c === '+newPrecClauseRec.Account__c);
              System.debug('parentAccIdVsOppsMap.keySet() === '+parentAccIdVsOppsMap.keySet());
            for(Opportunity opp : parentAccIdVsOppsMap.get(newPrecClauseRec.Account__c)){
                opp.Nil_Holdover_Increase__c = newPrecClauseRec.Nil_Holdover_Increase__c;
                oppListToUpdate.add(opp);
            }
        }
        //RPP-10989 - END
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    public void andFinally()
    {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PrecedentClauseTriggerHandler.class.getName());
        //START -- RPP-2536 Kyle Tan 5/10/2018
        try{
            database.insert(opportunityClauseList);
            if(!oppListToUpdate.isEmpty()){
                database.update(oppListToUpdate);
            }
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        errorHandler.save();
        //END -- RPP-2536 Kyle Tan 5/10/2018
    }

}