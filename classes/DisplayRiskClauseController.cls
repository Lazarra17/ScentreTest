public class DisplayRiskClauseController {
    public class Response{
        @AuraEnabled
        public String status; 
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String returnValue;
        
        public Response(){
            this.status ='Success';
            this.message = '';
            this.returnValue = '';
        }
    }
    
    public class displayClauseWrapper{        
        public String accountName;
        public String accountId;
        public String clauseName;
        public String clauseId;
        public String clauseType;
        public String spaceName;
        public Id spaceId;
        public String propertyName;
        public String accountCategory;
        public Boolean highRiskClause;
        public Boolean riskApplies;
        public Boolean approved;
        public String reasonRecommendation;
    }
    
    @AuraEnabled
    public static Response getDetails(Id recordID, String sourceName){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(DisplayRiskClauseController.class.getName());
        Response responsedetails=new Response();   
        List<OpportunityClause__c> oppClauseRecordList=new List<OpportunityClause__c>();
        Id opportunityRecordId;
        Schema.SObjectType sobjectype=recordID.getsobjecttype();
        String accountCategory=null;
        if(String.isNotBlank(recordID)){
            List<displayClauseWrapper> displayWrapperList = new List<displayClauseWrapper>();
            if(String.isBlank(sourceName)){            
                
                Set<String> contarctStatusSet=new Set<String>();
                List<String> validcontarctStatus=Label.ContractStausforRisk.split(';');
                contarctStatusSet.addAll(validcontarctStatus);
                Opportunity opportunityRecord;
                List<Contract__c> contractRecordList =new List<Contract__c>();
                Space__c spaceRecord;
                if(sobjectype+'' == Constants.OPPORTUNITY){
                    opportunityRecordId=recordID;
                    try {
                        opportunityRecord =[Select id,Property__c,Space__c,Account.Category__c from Opportunity where Id=:recordID]; 
                    } catch (Exception e) {
                        opportunityRecord = NULL;
                    }
                    
                    accountCategory=OpportunityRecord.Account.Category__c;
                    recordID=OpportunityRecord.Property__c;
                    
                }            
                if(sobjectype+'' == Constants.SPACE){
                    try {
                        spaceRecord=[Select id,Property__c from Space__c where Id =: recordID];
                    } catch (Exception e) {
                        spaceRecord = NULL;
                    }
                    recordID=spaceRecord.Property__c;
                }
                contractRecordList = [SELECT Id,Name,Property__c,Opportunity__c,LeaseStatus__c from Contract__c 
                                      WHERE Property__c =: recordID
                                      AND (LeaseStatus__c IN : contarctStatusSet)];
                
                Set<Id> opportunityIdSet = new Set<Id>();
                for(Contract__c contr: contractRecordList){
                    if(contr.Opportunity__c!=opportunityRecordId||String.isBlank(opportunityRecordId)){
                        opportunityIdSet.add(contr.Opportunity__c);
                    }
                }
                Set<String> impactedRCASet=new Set<String>();
                impactedRCASet.add('Exclusivity');
                impactedRCASet.add('Exclusion Zone');
                impactedRCASet.add('Right of Refusal');
                
                try{
                    if(sobjectype+'' == Constants.OPPORTUNITY){
                        oppClauseRecordList = [SELECT Id, Name,Type__c,Opportunity__r.Space__c,Opportunity__r.Space__r.Name,
                                               Opportunity__r.Account.Id,Opportunity__r.Account.Name,Opportunity__r.Property__r.Name,
                                               toLabel(Opportunity__r.Account.Category__c),ReferencedClause__r.HighRiskClause__c,
                                               ReferencedClause__r.RiskApplies__c,ReasonRecommendation__c,Approved__c
                                               FROM OpportunityClause__c WHERE Opportunity__c IN: opportunityIdSet 
                                               //AND (ReferencedClause__r.HighRiskClause__c=true)
                                               AND ReferencedClause__r.SubType__c IN: impactedRCASet 
                                               ORDER BY ReferencedClause__r.HighRiskClause__c,Opportunity__r.Space__r.Name,Opportunity__r.Account.Category__c];
                    }else{
                        oppClauseRecordList = [SELECT Id, Name,Type__c,Opportunity__r.Space__c,Opportunity__r.Space__r.Name,
                                               Opportunity__r.Account.Id,Opportunity__r.Account.Name,Opportunity__r.Property__r.Name,
                                               toLabel(Opportunity__r.Account.Category__c),ReferencedClause__r.HighRiskClause__c,
                                               ReferencedClause__r.RiskApplies__c,ReasonRecommendation__c,Approved__c
                                               FROM OpportunityClause__c WHERE Opportunity__c IN: opportunityIdSet 
                                               AND (ReferencedClause__r.HighRiskClause__c=true OR ReferencedClause__r.RiskApplies__c = true) 
                                               ORDER BY ReferencedClause__r.HighRiskClause__c DESC,Opportunity__r.Space__r.Name,Opportunity__r.Account.Category__c];
                    }                    
                } catch(Exception e) {
                    responsedetails.status = Constants.FAILED;
                    responsedetails.message = e.getMessage();
                    errorHandler.createError(e);
                } 
            }
            else if(sourceName=='Risktab'){
                oppClauseRecordList = [SELECT Id, Name,Type__c,Opportunity__r.Space__c,Opportunity__r.Space__r.Name,
                                       Opportunity__r.Account.Id,Opportunity__r.Account.Name,Opportunity__r.Property__r.Name,
                                       toLabel(Opportunity__r.Account.Category__c),ReferencedClause__r.HighRiskClause__c,
                                       ReferencedClause__r.RiskApplies__c, ReasonRecommendation__c,Approved__c
                                       FROM OpportunityClause__c WHERE Opportunity__c =: recordID
                                       AND (ReferencedClause__r.RiskApplies__c = true OR ReferencedClause__r.HighRiskClause__c=true) 
                                       ORDER BY ReferencedClause__r.HighRiskClause__c,Opportunity__r.Space__r.Name];
            }
            for(OpportunityClause__c opptyClauseRecord: oppClauseRecordList){
                displayClauseWrapper displayWrapper = new displayClauseWrapper();
                displayWrapper.accountName=opptyClauseRecord.Opportunity__r.Account.Name;
                displayWrapper.accountId=opptyClauseRecord.Opportunity__r.Account.Id;
                displayWrapper.clauseName=opptyClauseRecord.Name;
                displayWrapper.clauseId=opptyClauseRecord.Id;
                displayWrapper.clauseType=opptyClauseRecord.Type__c;
                displayWrapper.spaceName=opptyClauseRecord.Opportunity__r.Space__r.Name;
                displayWrapper.spaceId=opptyClauseRecord.Opportunity__r.Space__c;
                displayWrapper.propertyName=opptyClauseRecord.Opportunity__r.Property__r.Name;
                displayWrapper.accountCategory=opptyClauseRecord.Opportunity__r.Account.Category__c;
                displayWrapper.highRiskClause=opptyClauseRecord.ReferencedClause__r.HighRiskClause__c;
                displayWrapper.riskApplies=opptyClauseRecord.ReferencedClause__r.RiskApplies__c;
                displayWrapper.reasonRecommendation = opptyClauseRecord.ReasonRecommendation__c;
                displayWrapper.approved =opptyClauseRecord.Approved__c;
                displayWrapperList.add(displayWrapper);
            }
            
            try {
                responsedetails.returnValue = JSON.serialize(displayWrapperList);
            } catch (Exception e) {
                responsedetails.returnValue = NULL;
            }
        }
        return responsedetails;
    }
    
    @AuraEnabled
    public static Response updateOpportunityClause(String clauseWrapperJSON){
        OpportunityClause__c oppClauseTemp;
        Response res = new Response();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(DisplayRiskClauseController.class.getName());
        List<DisplayClauseWrapper> clauseWrapperList;
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        if(clauseWrapperJSON != '' && clauseWrapperJSON != null){
            try {
                clauseWrapperList = (List<DisplayClauseWrapper>) JSON.deserialize(clauseWrapperJSON, List<DisplayClauseWrapper>.class);
            } catch (Exception e) {
                clauseWrapperList = NULL;
            }
            
        }
        for(DisplayClauseWrapper cWrapper :clauseWrapperList){
            oppClauseTemp = new OpportunityClause__c();   
            oppClauseTemp.Id = cWrapper.clauseId;
            oppClauseTemp.ReasonRecommendation__c = cWrapper.reasonRecommendation;
            opportunityClauseList.add(oppClauseTemp);
        }
        if(opportunityClauseList != null && opportunityClauseList.size() > 0){
            try{
                Database.update(opportunityClauseList);
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
    public static Boolean isColumnEditable(Opportunity opportunity){
        Boolean canUpdate = false;        
        Profile prof = DatabaseSOQLBank.getProfile(UserInfo.getProfileId());        
        if(!Constants.OPPTY_STAGENAME_ISSUE_LEASE.equalsIgnoreCase(opportunity.StageName) 
           && (opportunity.OwnerId == UserInfo.getUserId() || Constants.SYSTEM_ADMINISTRATOR.equalsIgnoreCase(prof.Name))){
               canUpdate = true;
           }        
        return canUpdate;
    }
    
    @AuraEnabled
    public static Boolean userHasEditAccess(Id opportunityId) {
        Boolean hasEditAccess = false;
        Boolean isOppLocked = false;
        Boolean isDealAchieved = false;
        Boolean userAccess = false;
        opportunity oppRecord = new Opportunity();
        if(opportunityId != null) {
            try {
                oppRecord = [SELECT id, DealAchieved__c FROM Opportunity WHERE id =: opportunityId];
            } catch(Exception e) {
                oppRecord = null;
            }
            if(Approval.isLocked(opportunityId)) {
                isOppLocked = true;
            }
        }
        if(oppRecord != null) {
            isDealAchieved = oppRecord.DealAchieved__c;
        }
        for(UserRecordAccess usrRecAcc : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userInfo.getUserId() AND RecordId =:opportunityId]){
            hasEditAccess = usrRecAcc.HasEditAccess;
        }      
        if(!isOppLocked && !isDealAchieved && hasEditAccess) {
            userAccess = true;
        }
        return userAccess;
    }
}