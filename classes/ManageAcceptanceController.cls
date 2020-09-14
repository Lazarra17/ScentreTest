/**
 * @author:			Kyle Tan
 * @desc:			APEX Controller for the Manage Acceptance Lightning Component
 **/
public with sharing class ManageAcceptanceController {
    
    public class OpportunityClauseWrapper{
        @AuraEnabled public List<ClauseLibrary__c> availableClauseList = new List<ClauseLibrary__c>();
        @AuraEnabled public List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
    }

    /**
     * @author:			Kyle Tan
     * @desc:			retrieves the list of available clauses from the ClauseLibrary__c and the Opportunity Clauses
     * 					of the opportunity
     **/
    @AuraEnabled
    public static LightningResponse buildOpportunityClauseWrapper(Id opportunityId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ManageAcceptanceController.class.getName());
        LightningResponse responseObject = new LightningResponse();
        OpportunityClauseWrapper wrapperObject = new OpportunityClauseWrapper();
        List<OpportunityClause__c> selectedOppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibraryList = new List<ClauseLibrary__c>();
        List<ClauseLibrary__c> filteredClauseLibraryList = new List<ClauseLibrary__c>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> selectedClauseIdSet = new Set<Id>();
        Set<String> picklistValues = new Set<String>();
        
        picklistValues.add(Constants.CLAUSE_TYPE_ACCEPTANCE);
        picklistValues.add(Constants.CLAUSE_TYPE_COUNTER_OFFER);
        
        opportunityIdSet.add(opportunityId);
        try{
            selectedOppClauseList = DatabaseSOQLBank.getOpportunityClauseListForStandardResponse(opportunityIdSet);
        } catch(Exception e) {
            selectedOppClauseList = null;
        }
        if(selectedOppClauseList != null && selectedOppClauseList.size() > 0) {
            for(OpportunityClause__c tempOppClauseRec :selectedOppClauseList) {
                if(tempOppClauseRec.ReferencedClause__c != null ) {
                    selectedClauseIdSet.add(tempOppClauseRec.ReferencedClause__c);
                }
            }
        }
        try{
            filteredClauseLibraryList = DatabaseSOQLBank.getFilteredClauseLibraryList(selectedClauseIdSet);
        } catch(Exception e) {
            filteredClauseLibraryList = null;
        }
        if(filteredClauseLibraryList != null && filteredClauseLibraryList.size() > 0) {
            for(ClauseLibrary__c clauseLibraryRec : filteredClauseLibraryList) {
                if(picklistValues.contains(clauseLibraryRec.Type__c) && Constants.CL_STANDARD_RESPONSES.equalsIgnoreCase(clauseLibraryRec.RecordType.DeveloperName)) {
                    clauseLibraryList.add(clauseLibraryRec);
                }
            }
        }
        if(clauseLibraryList != null && clauseLibraryList.size() > 0) {
            wrapperObject.availableClauseList = clauseLibraryList;
        }
        if(selectedOppClauseList != null && selectedOppClauseList.size() > 0) {
            wrapperObject.opportunityClauseList = selectedOppClauseList;
        }
        if(wrapperObject != null) {
            responseObject.returnValue = JSON.serialize(wrapperObject);
        }
        errorHandler.save();
        return responseObject;
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			method verifies if the user is able to edit the opportunity
     **/
    @AuraEnabled
    public static Boolean verifyOpportunity(Id opportunityId) {
        return ClauseSelectionController.enableClauseEditUpdate(opportunityId);
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			retrieves the picklist values for the Clause Type picklist in the lightning component
     **/
    @AuraEnabled
    public static LightningResponse getClauseTypePicklistValues() {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ManageAcceptanceController.class.getName());
        LightningResponse responseObject = new LightningResponse();
        Set<String> picklistValues = new Set<String>();
        Schema.DescribeFieldResult fieldResult = ClauseLibrary__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> fieldVal = new List<Schema.PicklistEntry>();
        List<String> typeOptions = new List<String>();
        
        picklistValues.add(Constants.CLAUSE_TYPE_ACCEPTANCE);
        picklistValues.add(Constants.CLAUSE_TYPE_COUNTER_OFFER);
        
        try{
            fieldVal = fieldResult.getPicklistValues();
        } catch(Exception e) {
            fieldVal = null;
        }
        
        if(fieldVal != null && fieldVal.size() > 0) {
            for(Schema.PicklistEntry field: fieldVal) {
                if(picklistValues.contains(field.getLabel())) {
                    typeOptions.add(field.getLabel());
                }
            }
            responseObject.returnValue = JSON.serialize(typeOptions);
        }
        return responseObject;
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			retrieves the picklist values for the Document Location picklist in the lightning component
     **/
    @AuraEnabled
    public static LightningResponse getDocLocPicklistValues() {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ManageAcceptanceController.class.getName());
        LightningResponse responseObject = new LightningResponse();
        Schema.DescribeFieldResult fieldResult = ClauseLibrary__c.DocumentLocation__c.getDescribe();
        List<Schema.PicklistEntry> fieldVal = new List<Schema.PicklistEntry>();
        List<String> typeOptions = new List<String>();
        
        try{
            fieldVal = fieldResult.getPicklistValues();
        } catch(Exception e) {
            fieldVal = null;
        }
        if(fieldVal != null && fieldVal.size() > 0) {
            for (Schema.PicklistEntry field: fieldVal) {
                typeOptions.add(field.getLabel());
            }
            responseObject.returnValue = JSON.serialize(typeOptions);
        }
        return responseObject;
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			retrieves the picklist values for the Applicable State picklist in the lightning component
     **/
    @AuraEnabled
    public static LightningResponse getApplicationStatePicklistValues() {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ManageAcceptanceController.class.getName());
        LightningResponse responseObject = new LightningResponse();
        Schema.DescribeFieldResult fieldResult = ClauseLibrary__c.ApplicableState__c.getDescribe();
        List<Schema.PicklistEntry> fieldVal = new List<Schema.PicklistEntry>();
        List<String> typeOptions = new List<String>();
        
        try{
            fieldVal = fieldResult.getPicklistValues();
        } catch(Exception e) {
            fieldVal = null;
        }
        if(fieldVal != null && fieldVal.size() > 0) {
            for (Schema.PicklistEntry field: fieldVal) {
                typeOptions.add(field.getLabel());
            }
            responseObject.returnValue = JSON.serialize(typeOptions);
        }
        return responseObject;
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			method used to create the selected clauses into opportunity clauses
     **/
    @AuraEnabled
    public static LightningResponse createOpportunityClause(String clauseLibraryStringList, Id opportunityId) {
        return ClauseSelectionController.saveClause(clauseLibraryStringList, opportunityId);
    }
    
    /**
     * @author:			Kyle Tan
     * @desc:			deletes the selected opportunity clause
     **/
    @AuraEnabled
    public static LightningResponse deleteOpportunityClause(Id opportunityClauseId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ManageAcceptanceController.class.getName());
        LightningResponse responseObject = new LightningResponse();
        try{
            database.delete(opportunityClauseId);
        } catch(Exception e) {
            responseObject.status = Constants.FAILED;
            responseObject.message = e.getMessage();
            errorHandler.createError(e);
        }
        errorHandler.save();
        return responseObject;
    }
}