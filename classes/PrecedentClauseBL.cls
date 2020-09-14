/*
*  @author:        Kyle Tan
*  @description:   Contains business logic from precedentClauseTriggerHandler
*/
public without sharing class PrecedentClauseBL {
    
    /*
     *  @author:        Kyle Tan
     *  @parameters:    opportunityClauseRecord         - opportunity clause record to be updated
     *                  precedentClauseRecord           - precedent clause record to take details from
     *  @description:   This method updates the opportunity clause from the precedent clause
     */
    public static OpportunityClause__c updateOpportunityClause (OpportunityClause__c opportunityClauseRecord, PrecedentClause__c precedentClauseRecord) {
        opportunityClauseRecord.Name = precedentClauseRecord.Name;
        opportunityClauseRecord.Type__c = precedentClauseRecord.Type__c;
        opportunityClauseRecord.ClauseDetails__c = precedentClauseRecord.Description__c;
        opportunityClauseRecord.LeasingComment__c = precedentClauseRecord.Comments__c;
        opportunityClauseRecord.EffectiveToDate__c = precedentClauseRecord.EffectiveToDate__c;
        
        return opportunityClauseRecord;
    }

    /*
     *  @author:        Kyle Tan
     *  @parameters:    precedentClauseIdSet         - used to get all opportunity clauses
     *  @description:   This method build the map that contains the opportunity clause as value and its
     *                  related precedent clause as key
     */
     public static Map<Id, List<OpportunityClause__c>> buildOpportunityClauseMap (Set<Id> precedentClauseIdSet) {
        Map<Id, List<OpportunityClause__c>> opportunityClauseMap = new Map<Id, List<OpportunityClause__c>>();
        try{
            for(OpportunityClause__c oppClauseRec : DatabaseSOQLBank.getOpportunityClause(precedentClauseIdSet)) {
                if(opportunityClauseMap.containsKey(oppClauseRec.TechPrecedentClauseId__c)) {
                    opportunityClauseMap.get(oppClauseRec.TechPrecedentClauseId__c).add(oppClauseRec);
                } else {
                     opportunityClauseMap.put(oppClauseRec.TechPrecedentClauseId__c, new List<OpportunityClause__c>{oppClauseRec});
                }
            }
        } catch (Exception e) {
            opportunityClauseMap = null;
        }

        return opportunityClauseMap;
     }
     
    /*
     *  @author:        Kyle Tan
     *  @parameters:    precedentClauseAccountIdSet     - Id set of the accounts in the precedent clause list
     *  @description:   This method builds the map that contains the list of opportunities that are open
     */
    public static Map<Id, List<Opportunity>> buildopportunityFromAccountMap (Set<Id> precedentClauseAccountIdSet) {
        Map<Id, List<Opportunity>> opportunityFromAccountMap = new Map<Id, List<Opportunity>>();
        Set<Id> childAccountIdSet = new Set<Id>();

        try{
            for(Account accountRecord : DatabaseSOQLBank.getAccountByPrecedentClause(precedentClauseAccountIdSet)) {
                for(Account childAccountRecord : accountRecord.ChildAccounts) {
                    childAccountIdSet.add(childAccountRecord.Id);
                }
            }
        } catch(Exception e){
            childAccountIdSet = null;
        }
        
        if(childAccountIdSet != null && childAccountIdSet.size() > 0) {
            for(Opportunity opportunityRecord : DatabaseSOQLBank.getOpportunity(childAccountIdSet)) {
                if(opportunityFromAccountMap.containsKey(opportunityRecord.Account.ParentId)) {
                    opportunityFromAccountMap.get(opportunityRecord.Account.ParentId).add(opportunityRecord);
                } else {
                    opportunityFromAccountMap.put(opportunityRecord.Account.ParentId, new List<Opportunity>{opportunityRecord});
                }
            }
        }

        return opportunityFromAccountMap;
    }
    
    /*
     *  @author:        Shrikant Hase
     *  @ticket:        RPP-10989
     *  @parameters:    precedentClauseAccountIdSet     - Id set of the accounts in the precedent clause list
     *  @description:   This method builds the map that contains the list of opportunities that are open
     */
    public static Map<Id, List<Opportunity>> buildOppFromAccMap (Set<Id> precedentClauseAccountIdSet) {
        System.debug('precedentClauseAccountIdSet === '+precedentClauseAccountIdSet);
        Map<Id, List<Opportunity>> opportunityFromAccountMap = new Map<Id, List<Opportunity>>();
        Set<Id> childAccountIdSet = new Set<Id>();

        try{
            for(Account accountRecord : DatabaseSOQLBank.getAccountByPrecedentClause(precedentClauseAccountIdSet)) {
                for(Account childAccountRecord : accountRecord.ChildAccounts) {
                    childAccountIdSet.add(childAccountRecord.Id);
                }
            }
        } catch(Exception e){
            childAccountIdSet = null;
        }
        
        if(childAccountIdSet != null && childAccountIdSet.size() > 0) {
            for(Opportunity opportunityRecord : DatabaseSOQLBank.getOpportunities(childAccountIdSet)) {
                if(opportunityFromAccountMap.containsKey(opportunityRecord.Account.ParentId)) {
                    opportunityFromAccountMap.get(opportunityRecord.Account.ParentId).add(opportunityRecord);
                } else {
                    opportunityFromAccountMap.put(opportunityRecord.Account.ParentId, new List<Opportunity>{opportunityRecord});
                }
            }
        }
		System.debug('opportunityFromAccountMap === '+opportunityFromAccountMap);
        return opportunityFromAccountMap;
    }
    //RPP-10989 - END
}