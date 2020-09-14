/**
 * @author:         Kyle Tan
 * @desc:           controller of security lightning component
 **/
public with sharing class SecurityController {
    
    public class AffiliationsWrapper{
        @AuraEnabled public Id recordId = null; 
        @AuraEnabled public Boolean isActive = false;
        @AuraEnabled public String affType = null;
        @AuraEnabled public String affName = null;
        @AuraEnabled public String affAddress = null;
        @AuraEnabled public Id affContactId = null;
        @AuraEnabled public Id affAccountId = null;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           
     **/
    @AuraEnabled
    public static LightningResponse getAffiliations(Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        LightningResponse response = new LightningResponse();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> oppConIdSet = new Set<Id>();
        List<Affiliation__c> affList = new List<Affiliation__c>();
        List<AffiliationsWrapper> wrapperList = new List<AffiliationsWrapper>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        
        opportunityIdSet.add(opportunityId);
        oppMap = getOpportunityMap(opportunityIdSet);
        if(oppMap.containsKey(opportunityId)) {
            affList = getAffiliationList(oppMap.get(opportunityId));
        }
        oppConIdSet = getOpportunityContacts(opportunityIdSet, opportunityId);
        if((affList != null && affList.size() > 0) && (oppConIdSet != null && oppConIdSet.size() > 0)) {
            wrapperList = buildAffiliationWrapper(affList, oppConIdSet);
        }
        response.returnValue = JSON.serialize(wrapperList);
        errorHandler.save();
        return response;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           compile the opportunities contact roles and return a Set of Ids
     **/
    public static Set<Id> getOpportunityContacts(Set<Id> opportunityIdSet, Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        Set<Id> oppConIdSet = new Set<Id>();
        Map<Id, List<OpportunityContactRole>> oppConRolesMap = new Map<Id, List<OpportunityContactRole>>();
        
        try{
            oppConRolesMap = DatabaseSOQLBank.getOppConRolesMap(opportunityIdSet);
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        if(oppConRolesMap != null && oppConRolesMap.containsKey(opportunityId)) {
            for(OpportunityContactRole tempRec : oppConRolesMap.get(opportunityId)) {
                oppConIdSet.add(tempRec.ContactId);
            }
        }
        errorHandler.save();
        return oppConIdSet;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           populate AffiliationsWrapper from the Affliations of the related Account
     **/
    public static List<AffiliationsWrapper> buildAffiliationWrapper(List<Affiliation__c> affList, Set<Id> oppConIdSet) {
        List<AffiliationsWrapper> wrapperList = new List<AffiliationsWrapper>();
        
        if(affList != null && affList.size() > 0) {
            for(Affiliation__c affRec :affList){
                if(affRec.Contact__c != null && Constants.CURRENT.equalsIgnoreCase(affRec.Status__c) && (Constants.COMP_PERSONAL_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.COMP_PARENT_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.PERSONAL_GUARANTEES_FRANCHISEE.equalsIgnoreCase(affRec.Type__c))) {
                    AffiliationsWrapper wrapper = new AffiliationsWrapper();
                    Address tempAddress = null;
                    wrapper.recordId = affRec.Id;
                    wrapper.affType = affRec.Type__c;
                    wrapper.affContactId = affRec.Contact__c;
                    wrapper.affAccountId = affRec.PrimaryAffiliationAccount__c;
                    if(oppConIdSet.size() > 0) {
                        if(oppConIdSet.contains(affRec.Contact__c)) {
                            wrapper.isActive = true;
                        }
                    }
                    if(Constants.COMP_PERSONAL_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.COMP_PARENT_GUARANTEES.equalsIgnoreCase(affRec.Type__c)) {
                        wrapper.affName = affRec.PrimaryAffiliationAccount__r.TradingName__c;
                        tempAddress = affRec.PrimaryAffiliationAccount__r.ShippingAddress;
                        if(tempAddress.getStreet() != null) {
                            wrapper.affAddress = tempAddress.getStreet();
                        }
                    } else if(Constants.PERSONAL_GUARANTEES_FRANCHISEE.equalsIgnoreCase(affRec.Type__c)) {
                        if(affRec.Contact__r.Name != null) {
                            wrapper.affName = affRec.Contact__r.Name;
                        }
                        if(affRec.Contact__r.MailingAddress != null) {
                            tempAddress = affRec.Contact__r.MailingAddress;
                        }
                        if(tempAddress.getStreet() != null) {
                            wrapper.affAddress = tempAddress.getStreet();
                        }
                    }
                    wrapperList.add(wrapper);
                }
            }
        }
        return wrapperList;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           retrieves the Affiliations of the related Account
     **/
    public static List<Affiliation__c> getAffiliationList(Opportunity oppRec) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        Map<Id, List <Affiliation__c>> affiliationMap = new Map<Id, List <Affiliation__c>>();
        Set<Id> accountIdSet = new Set<Id>();
        
        if(oppRec != null) {
            accountIdSet.add(oppRec.AccountId);
            try{
                affiliationMap = DatabaseSOQLBank.getAffiliationMap(accountIdSet);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        return affiliationMap.get(oppRec.AccountId);
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           queries opportunity details from opportunity Id
     **/
    public static Map<Id, Opportunity> getOpportunityMap(Set<Id> oppIdSet) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        
        try{
            oppMap = DatabaseSOQLBank.getOpportunityMap(oppIdSet);
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        return oppMap;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           creates and deletes contact roles based on the status of the affiliation
     **/
    @AuraEnabled
    public static LightningResponse saveAffiliationList(Id opportunityId, String updatedAffListJSON) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        LightningResponse response = new LightningResponse();
        Integer guarantorsNum = 0;
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> oppConIdSet = new Set<Id>();
        List<AffiliationsWrapper> updatedListWrapper = new List<AffiliationsWrapper>();
        List<Affiliation__c> affList = new List<Affiliation__c>();
        List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
        List<OpportunityContactRole> oppConRolesToDelete = new List<OpportunityContactRole>();
        Map<Id, List<OpportunityContactRole>> oppConRolesMap = new  Map<Id, List<OpportunityContactRole>>();
        Map<Id, OpportunityContactRole> oppConRolesMapTemp = new Map<Id, OpportunityContactRole>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        
        opportunityIdSet.add(opportunityId);
        oppMap = getOpportunityMap(opportunityIdSet);
        if(oppMap.containsKey(opportunityId)) {
            affList = getAffiliationList(oppMap.get(opportunityId));
        }
        try{
            oppConRolesMap = DatabaseSOQLBank.getOppConRolesMap(opportunityIdSet);
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        if(oppConRolesMap != null && oppConRolesMap.containsKey(opportunityId)) {
            for(OpportunityContactRole tempRec : oppConRolesMap.get(opportunityId)) {
                oppConRolesMapTemp.put(tempRec.ContactId, tempRec);
                oppConIdSet.add(tempRec.ContactId);
            }
        }
        updatedListWrapper = (List<AffiliationsWrapper>) JSON.deserialize(updatedAffListJSON, List<AffiliationsWrapper>.class);
        for(AffiliationsWrapper wrapperTemp : updatedListWrapper) {
            if(!oppConIdSet.contains(wrapperTemp.affContactId) && 
               wrapperTemp.isActive &&
               wrapperTemp.affContactId != null) {
                //create contact role
                guarantorsNum++;
                oppContactRoleList.add(createOpportunityContactRole(wrapperTemp.affType, wrapperTemp.affContactId, opportunityId));
            } else if(oppConIdSet.contains(wrapperTemp.affContactId) &&
                      !wrapperTemp.isActive){
                //delete contact role
                if(oppConRolesMapTemp.containsKey(wrapperTemp.affContactId)) {
                    if(oppConRolesMapTemp.get(wrapperTemp.affContactId).ContactId == wrapperTemp.affContactId) {
                        guarantorsNum--;
                        oppConRolesToDelete.add(oppConRolesMapTemp.get(wrapperTemp.affContactId));
                    }
                }
            }
        }
        
        /*system.debug('guarantorsNum: '+guarantorsNum);
        
        if(oppMap.get(opportunityId).NumberofGuarantors__c == null) {
            oppMap.get(opportunityId).NumberofGuarantors__c = 0;
        }
        if(guarantorsNum != 0 && guarantorsNum != null && oppMap.get(opportunityId).NumberofGuarantors__c != null) {
            oppMap.get(opportunityId).NumberofGuarantors__c += guarantorsNum;
        }
        
        system.debug('NumberofGuarantors: '+oppMap.get(opportunityId).NumberofGuarantors__c );
        */
        if(oppContactRoleList != null && oppContactRoleList.size() > 0) {
            try{
                database.insert(oppContactRoleList);
            } catch(Exception e) {
                response.status = Constants.FAILED;
                response.message = e.getMessage();
                errorHandler.createError(e);
            }
        }
        if(oppConRolesToDelete != null && oppConRolesToDelete.size() > 0) {
            try{
                database.delete(oppConRolesToDelete);
            } catch(Exception e) {
                response.status = Constants.FAILED;
                response.message = e.getMessage();
                errorHandler.createError(e);
            }
        }
        
        Set<String> rolesSet = new Set<String>{Constants.COMP_PERSONAL_GUARANTEES, Constants.COMP_PARENT_GUARANTEES, Constants.PERSONAL_GUARANTEES_FRANCHISEE};
            Map<Id, List<OpportunityContactRole>> oppContactRolesMap = DatabaseSOQLBank.getOppConRolesMap(oppMap.keySet(), rolesSet);
        
        for(Id oppId : oppMap.keySet()) {
            Opportunity opp = oppMap.get(oppId);
            List<String> guarantors = new List<String>();
            
            if (oppContactRolesMap.containsKey(oppId)) {
                for (OpportunityContactRole conRole : oppContactRolesMap.get(oppId)) {
                    guarantors.add(conRole.Contact.Name);
                }
            }
            opp.Guarantors__c = String.join(guarantors, ', ');
        }
        

        try{
            database.update(oppMap.get(opportunityId));
        } catch(Exception e) {
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        
        errorHandler.save();
        return response;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           method that is used to populate the opportunity contact role
     **/
    public static OpportunityContactRole createOpportunityContactRole(String conRole, Id conId, Id oppId){
        OpportunityContactRole oppConRole = new OpportunityContactRole(
            Role = conRole,
            Contactid = conId,
            OpportunityId = oppId
        );
        return oppConRole;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           verify if user has edit access on the opportunity record
     **/
    @AuraEnabled
    public static LightningResponse userHasEditAccess(Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        LightningResponse response = new LightningResponse();
        try{
            response.returnValue = JSON.serialize(OpportunityLineItemController.userHasEditAccess(opportunityId));
        } catch(Exception e) {
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        return response;
    }
    
    @AuraEnabled
    public static void createRCAOppClause(Opportunity opp){
        Boolean isSecuritySame = false;
        OpportunityClause__c existingOppClause;
        Set<String> subTypeSet;
        Set<String> partnershipSegmentationSet;
        List<ClauseLibrary__c> clauseLibraryList;
        List<OpportunityClause__c> newOppClauseList = new List<OpportunityClause__c>();
        Map<String,Schema.RecordTypeInfo> oppRecordTypeMap;
        Map<String,Schema.RecordTypeInfo> oppClauseRecordTypeMap;
        Map<String, List<ClauseLibrary__c>> subTypeClauseLibraryListMap = new Map<String, List<ClauseLibrary__c>>();
        
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        
        oppRecordTypeMap = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OPPORTUNITY);
        oppClauseRecordTypeMap = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OPPORTUNITY_CLAUSE_API);
        
        subTypeSet = new Set<String>{
            Constants.NATIONAL_CHANGE_IN_SECURITY
        };
        
        partnershipSegmentationSet = new Set<String>{
            Constants.GROWTH_PARTNER,
            Constants.STRATEGIC_PARTNER
        };
        
        if(opp.NationalAgreement__c != null 
            && Constants.OPP_RETAIL_LEASING_API_NAME.equalsIgnoreCase(opp.RecordType.DeveloperName)
            && (partnershipSegmentationSet.contains(opp.Account.PartnershipSegmentation__c) 
                || partnershipSegmentationSet.contains(opp.NationalAgreement__r.Account__r.PartnershipSegmentation__c))){
            try{
                existingOppClause = [SELECT Id, Name 
                                     FROM OpportunityClause__c 
                                     WHERE SubType__c =: Constants.NATIONAL_CHANGE_IN_SECURITY
                                        AND Opportunity__c =: opp.Id
                                     LIMIT 1];
            } catch(Exception e){
                existingOppClause = null;
            }
            
            system.debug('opp : ' + opp);
            system.debug('existingOppClause : ' + existingOppClause);
			
			Decimal nationalSecurityDays = (opp.NationalAgreement__r.RequiredSecurityDepositDays__c == null)? 0 : opp.NationalAgreement__r.RequiredSecurityDepositDays__c;
			Decimal nationalSecurityWeeks = (opp.NationalAgreement__r.RequiredSecurityDepositWeeks__c == null)? 0 : opp.NationalAgreement__r.RequiredSecurityDepositWeeks__c;
			Decimal nationalSecurityMonths = (opp.NationalAgreement__r.RequiredSecurityDepositMonths__c == null)? 0 : opp.NationalAgreement__r.RequiredSecurityDepositMonths__c;
			Decimal securityDays = (opp.SecurityDepositDays__c == null)? 0 : opp.SecurityDepositDays__c;
			Decimal securityWeeks = (opp.SecurityDepositWeeks__c == null)? 0 : opp.SecurityDepositWeeks__c;
			Decimal securityMonths = (opp.SecurityDepositMonths__c == null)? 0 : opp.SecurityDepositMonths__c;
			
			if(securityDays == nationalSecurityDays && securityWeeks == nationalSecurityWeeks 
			&& securityMonths == nationalSecurityMonths){
				isSecuritySame = true;
			}
        
            system.debug('isSecuritySame : ' + isSecuritySame);
            
            if(existingOppClause == null || (existingOppClause != null && existingOppClause.Id == null)){
                try{
                    subTypeClauseLibraryListMap = DatabaseSOQLBank.getHighRiskClauseLibraryBySubType(subTypeSet);
                } catch(Exception e){
                    subTypeClauseLibraryListMap = null;
                }
                
                system.debug('subTypeClauseLibraryListMap_wizard : ' + subTypeClauseLibraryListMap);
                
                if(!isSecuritySame && subTypeClauseLibraryListMap != null 
                    && subTypeClauseLibraryListMap.containsKey(Constants.NATIONAL_CHANGE_IN_SECURITY) 
                    && oppClauseRecordTypeMap.containsKey(Constants.OC_LEASING_CLAUSE)){
                    clauseLibraryList = subTypeClauseLibraryListMap.get(Constants.NATIONAL_CHANGE_IN_SECURITY);
                    newOppClauseList = OpportunityBL.createOpportunityClause(
                        oppClauseRecordTypeMap.get(Constants.OC_LEASING_CLAUSE).getRecordTypeId(), 
                        opp, 
                        clauseLibraryList
                    );
                }
            } else {
                if(isSecuritySame){
                    try{
                        Database.delete(existingOppClause);
                    } catch(Exception e){
                         errorHandler.createError(e);
                    }
                }
            }
            
            system.debug('newOppClauseList : ' + newOppClauseList);
            
            if(newOppClauseList != null && newOppClauseList.size() > 0){
                try{
                    Database.insert(newOppClauseList);
                } catch(Exception e){
                    errorHandler.createError(e);
                }
            }
        
        }
        
        errorHandler.save();
    }
}