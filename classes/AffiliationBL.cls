/*
*  @author:        Kyle Tan
*  @description:   Contains business logic from AffiliationTriggerHandler
*/
public without sharing class AffiliationBL {

    public static List<OpportunityContactRole> createOpportunityConRoles(Affiliation__c affRec, List<Opportunity> oppList) {
    List<OpportunityContactRole> oppContactRoleList  = new List<OpportunityContactRole>();
    if(oppList != null && oppList.size() > 0){
        if(affRec.Contact__c != null && Constants.CURRENT.equalsIgnoreCase(affRec.Status__c) && (Constants.COMP_PERSONAL_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.COMP_PARENT_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.PERSONAL_GUARANTEES_FRANCHISEE.equalsIgnoreCase(affRec.Type__c))){
            for(Opportunity oppRec :oppList){
                    oppContactRoleList.add(SecurityController.createOpportunityContactRole(affRec.Type__c, affRec.Contact__c, oppRec.Id));
                }
            }
        }
        return oppContactRoleList;
    }
    
    public static List<Opportunity> updateNumberofGuarantors(Affiliation__c affRec, List<Opportunity> oppList) {
        if(affRec.Contact__c != null && Constants.CURRENT.equalsIgnoreCase(affRec.Status__c) && (Constants.COMP_PERSONAL_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.COMP_PARENT_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.PERSONAL_GUARANTEES_FRANCHISEE.equalsIgnoreCase(affRec.Type__c))) {
            for(Opportunity oppRec :oppList) {
                if(oppRec.NumberofGuarantors__c > 0) {
                    oppRec.NumberofGuarantors__c += 1;
                } else {
                    oppRec.NumberofGuarantors__c = 1;
                }        
            }
        }
        return oppList;
    }
    
    public static List<OpportunityContactRole> deleteContactRole(Affiliation__c affRecord, List<OpportunityContactRole> oppContactRoleList) {
        List<OpportunityContactRole> oppContactRoleListToDelete = new List<OpportunityContactRole>();
        if(oppContactRoleList != null && oppContactRoleList.size() > 0) {
            for(OpportunityContactRole tempOppConRole :oppContactRoleList) {
                if(tempOppConRole.ContactId == affRecord.Contact__c) {
                    oppContactRoleListToDelete.add(tempOppConRole);
                }
            }
        }
        return oppContactRoleListToDelete;
    }
    
    public static List<Opportunity> reduceNumberOfGuarantors(Affiliation__c affRecord, List<OpportunityContactRole> oppConRoleListToDelete, List<Opportunity> opportunityList) {
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Id> opportunityIdList = new List<Id>();
        if(oppConRoleListToDelete != null && oppConRoleListToDelete.size() > 0) {
            for(OpportunityContactRole tempOppConRoleRec :oppConRoleListToDelete) {
                opportunityIdList.add(tempOppConRoleRec.OpportunityId);
            }
            for(Opportunity oppRec :opportunityList) {
                if(opportunityIdList.contains(oppRec.Id)) {
                    if(oppRec.NumberofGuarantors__c > 0) {
                        oppRec.NumberofGuarantors__c -= 1;
                        oppListToUpdate.add(oppRec);
                    }
                }
            }
        }
        return oppListToUpdate;
    }
}