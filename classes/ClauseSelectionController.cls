public with sharing class ClauseSelectionController {
    @AuraEnabled
    public static clauseAndOptionWrapper getClauses(id oppId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ClauseSelectionController.class.getName());
        List<OpportunityClause__c> selectedClauses;
        try{
            selectedClauses  = [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c, ReferencedClause__r.HighRiskClause__c, RecordType.Name, RiskApplies__c, ReasonRecommendation__c FROM OpportunityClause__c WHERE Opportunity__c =: oppId AND RecordType.DeveloperName = :Constants.OC_LEASING_CLAUSE ORDER BY ReferencedClause__r.Name];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        
        List<OpportunityClause__c> precedentSelectedClauses;
        try{
            precedentSelectedClauses = [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c, ReferencedClause__r.HighRiskClause__c, RecordType.Name, RiskApplies__c, ReasonRecommendation__c FROM OpportunityClause__c WHERE Opportunity__c =: oppId AND RecordType.DeveloperName = :Constants.OC_PRECEDENT_CLAUSE ORDER BY ReferencedClause__r.Name];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        
        Set<Id> clauseIds = new Set<Id>();
        for(OpportunityClause__c oppClauseVar : selectedClauses) {
            clauseIds.add(oppClauseVar.ReferencedClause__c);
        }
        for(OpportunityClause__c oppClauseVar : precedentSelectedClauses) {
            clauseIds.add(oppClauseVar.ReferencedClause__c);
        }
        List<ClauseLibrary__c> availableOppClause;
        try{
            availableOppClause = [SELECT Id, Name, Type__c, ActivatedDate__c, ClauseDetails__c, RiskApplies__c, ReasonRecommendation__c, HighRiskClause__c, SubType__c FROM ClauseLibrary__c WHERE Id not in: clauseIds AND Status__c = :Constants.ACTIVE AND RecordType.DeveloperName = :Constants.CL_RETAIL_CLAUSES ORDER BY Name];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        
        List<clauseWrapper> clauseWrap = new List<clauseWrapper>();
        For (ClauseLibrary__c clauseVar : availableOppClause){
            clauseWrap.add( new clauseWrapper(clauseVar, false));
        }
        
        List<String> typeOptions = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = ClauseLibrary__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> fieldVal = fieldResult.getPicklistValues();
        Set<String> picklistValues = new Set<String>();
        
        picklistValues.add(Constants.CLAUSE_TYPE_ACCEPTANCE);
        picklistValues.add(Constants.CLAUSE_TYPE_COUNTER_OFFER);
        
        for (Schema.PicklistEntry field: fieldVal) {
            if(!picklistValues.contains(field.getLabel())) {
                typeOptions.add(field.getLabel());
            }
        }
        
        return (new clauseAndOptionWrapper(clauseWrap, typeOptions, selectedClauses, precedentSelectedClauses));
    }
    
    @AuraEnabled
    //public static list<OpportunityClause__c> saveClause(String oppClauseSOQL, Id oppId) {
    public static LightningResponse saveClause(String oppClauseJSON, Id oppId){
        Map<String, Schema.RecordTypeInfo> oppClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
        LightningResponse res = new LightningResponse();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ClauseSelectionController.class.getName());
        List<ClauseLibrary__c> selectedClauseList = new List<ClauseLibrary__c>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        
        try{
            //selectedClause = database.query(oppClauseSOQL);
            selectedClauseList = (List<ClauseLibrary__c>) JSON.deserialize(oppClauseJSON, List<ClauseLibrary__c>.class);
        } catch (Exception e) {
            selectedClauseList = null;
            res.status = Constants.FAILED;
            res.message = e.getMessage();    
            errorHandler.createError(e);
        } 
        
        if(selectedClauseList!=null && !selectedClauseList.isEmpty()){
            for(ClauseLibrary__c clauseVar : selectedClauseList){
                OpportunityClause__c oppVar = new OpportunityClause__c();
                oppVar.Name = clauseVar.Name;
                oppVar.ClauseDetails__c = clauseVar.ClauseDetails__c;
                oppVar.EffectiveFromDate__c = clauseVar.ActivatedDate__c;
                oppVar.Opportunity__c = oppId;
                oppVar.Type__c = clauseVar.Type__c;
                oppVar.ReferencedClause__c = clauseVar.Id;
                oppVar.RiskApplies__c = clauseVar.RiskApplies__c;
                oppVar.ReasonRecommendation__c = clauseVar.ReasonRecommendation__c;
                oppVar.SubType__c = clauseVar.SubType__c;
                if(Constants.CL_STANDARD_RESPONSES.equalsIgnoreCase(clauseVar.RecordType.DeveloperName)) {
                    oppVar.RecordTypeId = oppClauseRecordTypeMapByName.get(Constants.OC_STANDARD_RESPONSE_CLAUSE_NAME).getRecordTypeId();
                } else if(Constants.CL_RETAIL_CLAUSES.equalsIgnoreCase(clauseVar.RecordType.DeveloperName)) {
                    oppVar.RecordTypeId = oppClauseRecordTypeMapByName.get(Constants.LEASING_CLAUSE).getRecordTypeId();
                }
                oppClauseList.add(oppVar);
            }
            
            try{
                Database.insert(oppClauseList);
                
                oppClauseList = [SELECT Id, Name, ClauseDetails__c, ReferencedClause__c, ReferencedClause__r.HighRiskClause__c, RecordType.Name, RiskApplies__c, ReasonRecommendation__c, SubType__c 
                                 FROM OpportunityClause__c
                                 WHERE Id IN: oppClauseList];
                
                res.returnValue = JSON.serialize(oppClauseList);
            } catch(Exception e){
                res.status = Constants.FAILED;
            	res.message = e.getMessage();
             	errorHandler.createError(e);
            }
        }
        
        errorHandler.save();
        return res;
    }
    
    @AuraEnabled
    public static OpportunityClause__c getUpdatedClause(Id oppClause) {
        return [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c,RecordType.Name,RiskApplies__c, SubType__c FROM OpportunityClause__c WHERE Id =: oppClause Limit 1];
    }
    @AuraEnabled
    public static clauseAndOptionWrapper deleteClause(id oppClause,Id clauseIds) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ClauseSelectionController.class.getName());
        OpportunityClause__c selectedClauses;
        try{
            selectedClauses = [SELECT Id,Opportunity__c FROM OpportunityClause__c WHERE Id =: oppClause Limit 1];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        
        Id opptyID=selectedClauses.Opportunity__c;
        delete selectedClauses;
        return getClauses(opptyID);
    }
    
    public class clauseWrapper {
        @AuraEnabled public ClauseLibrary__c clauseAvailable = new ClauseLibrary__c();
        @AuraEnabled public Boolean isSelected;
        public clauseWrapper (ClauseLibrary__c clauseAvailable, Boolean isSelected) {
            this.clauseAvailable = clauseAvailable;
            this.isSelected = isSelected;
        }
    }
    
    public class clauseAndOptionWrapper {
        @AuraEnabled public List<clauseWrapper> clauseWrap = new List<clauseWrapper>();        
        @AuraEnabled public List<String> clauseType = new List<String>();
        @AuraEnabled public List<OpportunityClause__c> clauseSelected = new List<OpportunityClause__c>();
        @AuraEnabled public List<OpportunityClause__c> precedentClauseSelected = new List<OpportunityClause__c>();
        
        public clauseAndOptionWrapper (List<clauseWrapper> clauseWrap, List<String> clauseType, List<OpportunityClause__c> clauseSelected, List<OpportunityClause__c> precedentClauseSelected){
            this.clauseWrap = clauseWrap;
            this.clauseType = clauseType;
            this.clauseSelected = clauseSelected;
            this.precedentClauseSelected = precedentClauseSelected;
            
        }
    }
    @AuraEnabled
    public static Boolean enableClauseEditUpdate(Id oppId){
        Boolean isLocked = false;
        Set<String> profilenameSet = new Set<String>();
        List<Profile> userProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
        String name = userProfile[0].Name;
        
        profilenameSet.add(CONSTANTS.SYSTEM_ADMINISTRATOR);
        profilenameSet.add(CONSTANTS.SCG_SYS_ADM);
        profilenameSet.add(CONSTANTS.SCG_BUSINESS_SUPPORT);
        profilenameSet.add(CONSTANTS.SCG_DATA_MIGRATION);
        profilenameSet.add(CONSTANTS.SCG_INTEGRATION);
        
        if(Approval.isLocked(oppId) && !profilenameSet.Contains(name)){
            isLocked = true;
        }
        return isLocked;
    }
    
}