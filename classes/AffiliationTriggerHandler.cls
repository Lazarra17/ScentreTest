/**
* Class AffiliationTriggerHandler
*
* Trigger Handler for the Affiliation__c SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class AffiliationTriggerHandler extends TriggerHandler implements ITrigger {
    // START : KT RPP-4921 7.23.18
    private List<OpportunityContactRole> oppContactRoleListToInsert = new List<OpportunityContactRole>();
    private List<OpportunityContactRole> oppContactRoleListToDelete = new List<OpportunityContactRole>();
    private List<Opportunity> opportunityList = new List<Opportunity>();
    private Map<Id, List<Opportunity>> accountOppMap = new Map<Id, List<Opportunity>>();
    private Map<Id, List<OpportunityContactRole>> oppContactRoleMap = new Map<Id, List<OpportunityContactRole>>();
    // END : KT RPP-4921 7.23.18
    
    // Constructor
    public AffiliationTriggerHandler()
    {
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
        if(Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> opportunityIdSet = new Set<Id>();
            List<OpportunityContactRole> tempOppContactRoleList = new List<OpportunityContactRole>();
            if(!Trigger.isDelete) {
                for(Affiliation__c affRec :(List<Affiliation__c>) Trigger.new) {
                    accountIdSet.add(affRec.Account__c);
                }
            } else {
                for(Affiliation__c affRec :(List<Affiliation__c>) Trigger.old) {
                    accountIdSet.add(affRec.Account__c);
                }
            }
            if(Trigger.isInsert || Trigger.isDelete) {
                // START : KT RPP-4921 7.23.18
                try{
                    accountOppMap = DatabaseSOQLBank.getOpportunitiesOfAccount(accountIdSet);
                } catch(Exception e) {
                    accountOppMap = null;
                }
                // END : KT RPP-4921 7.23.18
                try{
                    tempOppContactRoleList = DatabaseSOQLBank.getOppContactRoleListByAccount(accountIdSet);
                } catch(Exception e) {
                    tempOppContactRoleList = null;
                }
                if(tempOppContactRoleList != null && tempOppContactRoleList.size() > 0) {
                    for(OpportunityContactRole tempOppConRole :tempOppContactRoleList) {
                        if(oppContactRoleMap.containsKey(tempOppConRole.Opportunity.AccountId)) {
                            oppContactRoleMap.get(tempOppConRole.Opportunity.AccountId).add(tempOppConRole);
                        } else {
                            oppContactRoleMap.put(tempOppConRole.Opportunity.AccountId, new List<OpportunityContactRole>{tempOppConRole});
                        }
                    }
                }
            }
            if(Trigger.isDelete) {
            }
            if(Trigger.isUpdate) {
            }
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
     Affiliation__c newAff = (Affiliation__c)so;
     // START : KT RPP-4921 7.23.18
     if(accountOppMap.containsKey(newAff.Account__c)) {
         oppContactRoleListToInsert.addAll(AffiliationBL.createOpportunityConRoles(newAff, accountOppMap.get(newAff.Account__c)));
         //opportunityList.addAll(AffiliationBL.updateNumberofGuarantors(newAff, accountOppMap.get(newAff.Account__c)));
     }
     // END : KT RPP-4921 7.23.18
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
    }
    
    public void afterDelete(SObject so)
    {
        Affiliation__c newAff = (Affiliation__c)so;
        if(oppContactRoleMap.containsKey(newAff.Account__c)) {
            oppContactRoleListToDelete.addAll(AffiliationBL.deleteContactRole(newAff, oppContactRoleMap.get(newAff.Account__c)));
            //opportunityList.addAll(AffiliationBL.reduceNumberOfGuarantors(newAff, oppContactRoleMap.get(newAff.Account__c), accountOppMap.get(newAff.Account__c)));
        }
    }
    
    public void andFinally()
    {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(AffiliationTriggerHandler.class.getName());
        Set<Opportunity> opportunityIdToUpdate = new Set<Opportunity>();
        // START : KT RPP-4921 7.23.18
        if(oppContactRoleListToInsert != null && oppContactRoleListToInsert.size() > 0){
            try{
                database.insert(oppContactRoleListToInsert);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }/*
        if(opportunityList != null && opportunityList.size() > 0) {
            List<Opportunity> oppList = new List<Opportunity>();
            opportunityIdToUpdate.addAll(opportunityList);
            oppList.addAll(opportunityIdToUpdate);
            try{
                database.update(oppList, false);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }*/
        if(oppContactRoleListToDelete != null && oppContactRoleListToDelete.size() > 0) {
            try{
                database.delete(oppContactRoleListToDelete);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        // END : KT RPP-4921 7.23.18
        
        // Start : LF RPP-10238 4.11.2019
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        
        for (Id accId : accountOppMap.keySet()) {
            opportunityMap.putAll(accountOppMap.get(accId));
        }
        
        
        Set<String> rolesSet = new Set<String>{Constants.COMP_PERSONAL_GUARANTEES, Constants.COMP_PARENT_GUARANTEES, Constants.PERSONAL_GUARANTEES_FRANCHISEE};
        Map<Id, List<OpportunityContactRole>> oppContactRolesMap = DatabaseSOQLBank.getOppConRolesMap(opportunityMap.keySet(), rolesSet);
        
        for(Id oppId : opportunityMap.keySet()) {
            Opportunity opp = opportunityMap.get(oppId);
            List<String> guarantors = new List<String>();
            
            if (oppContactRolesMap.containsKey(oppId)) {
                for (OpportunityContactRole conRole : oppContactRolesMap.get(oppId)) {
                    guarantors.add(conRole.Contact.Name);
                }
            }
            opp.Guarantors__c = String.join(guarantors, ', ');
            System.debug('opp.Guarantors__c ' + opp.Guarantors__c);
        }
        
        try {
            Database.update(opportunityMap.values());
        }  catch(Exception e){
                errorHandler.createError(e);
        }
        // End : LF RPP-10238 4.11.2019
         
        errorHandler.save();
    }

}