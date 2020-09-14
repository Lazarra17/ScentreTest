public class CreateInspectionfromSpaceController {
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
    public class createinspectionwrapper{
        public space__c spaceRecord;
        public Date dueDate;
        public Id recordTypeId;
        public id ownerId;
        public string subject;
    }
    @AuraEnabled
    public static Response getspacedetails(id spaceId){
        Response responsedetails=new Response();
        Space__c spaceRecord;
        try {
            spaceRecord=[SELECT Id,Name,CurrentLease__c,CurrentLease__r.Account__c,CurrentLease__r.Name,CurrentLease__r.Id,Property__r.Name,CurrentLease__r.Account__r.Name,CurrentLeaseExpiryDate__c,CurrentLease__r.Account__r.ParentId,CurrentLease__r.Opportunity__c from Space__c where id =:spaceId];
        } catch (Exception e) {
            spaceRecord = NULL;
        }
        
        Map<String,AccountTeamMember> accountteamMap=new Map<String,AccountTeamMember>();
        Map<String,PropertyTeam__c> rolepropertyTeamMap=new Map<String,PropertyTeam__c>();
        Set<Id> accountids=new Set<Id>();
        accountids.add(spaceRecord.CurrentLease__r.Account__c);
        accountids.add(spaceRecord.CurrentLease__r.Account__r.ParentId);
        
        for(AccountTeamMember memberRecod: [Select id,TeamMemberRole,UserId from AccountTeamMember where AccountId =:accountids AND TeamMemberRole=:Constants.TEAM_ROLE_RDAM AND Account.RecordType.Name=:Constants.GROUP_LEVEL]){
            accountteamMap.put(memberRecod.TeamMemberRole,memberRecod);
        }  
        for(PropertyTeam__c propertyteam: [Select id,Role__c,TeamMember__c from PropertyTeam__c where Property__c =: spaceRecord.Property__c AND  Active__c=true AND Role__c=:Constants.TEAM_ROLE_RDM AND TeamMember__r.IsActive=true]){
            rolepropertyTeamMap.put(propertyteam.Role__c,propertyteam);
        }
        
        Id ownerid=userinfo.getUserId();
        if(accountteamMap.containskey(Constants.TEAM_ROLE_RDAM)){
            ownerid=accountteamMap.get(Constants.TEAM_ROLE_RDAM).UserId;
        }else if(rolepropertyTeamMap.containskey(Constants.TEAM_ROLE_RDM)){
            ownerid=rolepropertyTeamMap.get(Constants.TEAM_ROLE_RDM).TeamMember__c;
        }
        createinspectionwrapper wrapper=new createinspectionwrapper();
        wrapper.ownerId=ownerid;
        wrapper.spaceRecord=spaceRecord;
        wrapper.dueDate=System.today().addDays(2);
        //if(spaceRecord.CurrentLease__r.Account__c!=null){
        //  wrapper.subject=spaceRecord.Property__r.Name+' - '+spaceRecord.Name+' - '+spaceRecord.CurrentLease__r.Account__r.Name+' - Inspection Report'; 
        //}else{
        wrapper.subject=spaceRecord.Property__r.Name+' - '+spaceRecord.Name+' - Inspection Report'; 
        //}
        wrapper.recordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get(CONSTANTS.INSPECTION_REPORT).getRecordTypeId();
        
        try {
            responsedetails.returnValue = JSON.serialize(wrapper);
        } catch (Exception e) {
            responsedetails.returnValue = NULL;
        }
        return responsedetails;
    }
    
    //RPP-10876 - START 
    @AuraEnabled
    public static Boolean isIRCaseRaisedEarlier(Id spaceId){
        Boolean checkResult = false;
        list<Case> caseList =[SELECT Id, Space__c, CreatedDate 
                              FROM Case 
                              WHERE CreatedDate = LAST_N_DAYS:60
                              AND Space__c =: spaceId
                              AND RecordType.Name =: Constants.CASE_RECORDTYPE_INSPECTIONREPORT];
        if(caseList.size() > 0){
            checkResult = true;  
        }
        return checkResult;
    }
    //RPP-10876 - END
    
    //added below method to implement RPP-10876 
    @AuraEnabled
    public static void getselectOptions(Id caseId, String reason, String description ) {
        Case cases =[SELECT Id, Other_Reason__c, New_IR_Case_Reason__c, Subject, Status, 
                     Priority, DueDate__c, Contract__c 
                     FROM Case 
                     WHERE Id =: caseId 
                     LIMIT 1];
        if(reason == 'Other'){
            cases.Other_Reason__c = description; 
        }
        cases.New_IR_Case_Reason__c = reason;
        update cases;
    }
}