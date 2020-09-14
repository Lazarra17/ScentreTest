public without sharing class CovidCaseRelatedListController {
    
    public class Response{
        @AuraEnabled
        public String Is_Files_Accessible;
        @AuraEnabled
        public String Is_Notes_Accessible;
        @AuraEnabled
        public String Exception_Message;
        @AuraEnabled
        public String Success_Message;
    }
    
    @AuraEnabled
    public static Response getUserAccessibility(Id caseId, Id currentUserId){
        Response res = New Response();
        Case caseRec = [SELECT Id, SubType__c, TECH_Is_National_Account__c, Space__r.Property__r.Id, OwnerId FROM Case WHERE Id =: caseId LIMIT 1];
        String usrProfileName = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        
        String loggedInUserId = currentUserId;
        
        res.Is_Files_Accessible = 'NO';
        res.Is_Notes_Accessible = 'NO';
        
        try{
            if(caseRec.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST && (UserInfo.getName() == 'John Papagiannis' || UserInfo.getName() == 'Andrew Hulls' || UserInfo.getName() == 'Courtney Kingston')){
                res.Is_Files_Accessible = 'YES';
                res.Is_Notes_Accessible = 'YES';
            }
            else if(caseRec.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST && usrProfileName != Constants.SYSTEM_ADMINISTRATOR && usrProfileName != Constants.SCG_SYS_ADM && userInfo.getUserId() != caseRec.OwnerId){
                if(caseRec.TECH_Is_National_Account__c == true){
                    
                    /*List<CaseTeamMember> CaseTeamMembers = [SELECT MemberId FROM CaseTeamMember WHERE ParentId =: caseRec.Id];
                    List<Id> CaseTeamMemberIds = New List<Id>();
                    
                    for(CaseTeamMember ctm : CaseTeamMembers){
                        CaseTeamMemberIds.add(ctm.MemberId);
                    }*/
                    
                    for(CaseTeamMember csMember : [SELECT MemberId FROM CaseTeamMember WHERE ParentId =: caseRec.Id AND MemberId = :UserInfo.getUserId()]){                        
                        res.Is_Files_Accessible = 'YES';
                        res.Is_Notes_Accessible = 'YES';
                        system.debug('case team yes');
                    }
                    
                    /*if(CaseTeamMemberIds.contains(currentUserId)){
                        res.Is_Files_Accessible = 'YES';
                        res.Is_Notes_Accessible = 'YES';
                        system.debug('case team yes');
                    }
                    else{
                        res.Is_Files_Accessible = 'NO';
                        res.Is_Notes_Accessible = 'NO';
                        system.debug('case team no');
                    }*/
                    
                }
                else{
                    /*List<PropertyTeam__c> PropTeamMembers = [SELECT TeamMember__c, TeamMember__r.Id FROM PropertyTeam__c WHERE Property__c =: caseRec.Space__r.Property__r.Id];
                    List<Id> PropTeamMemberIds = New List<Id>();
                    
                    for(PropertyTeam__c pt : PropTeamMembers){
                        PropTeamMemberIds.add(pt.TeamMember__r.Id);
                    }*/
                    
                    for(PropertyTeam__c propTeam : [SELECT TeamMember__c, TeamMember__r.Id FROM PropertyTeam__c WHERE Property__c =: caseRec.Space__r.Property__r.Id AND TeamMember__c = :UserInfo.getUserId() AND Active__c = TRUE]){
                        res.Is_Files_Accessible = 'YES';
                        res.Is_Notes_Accessible = 'YES';
                        res.Success_Message = loggedInUserId;    
                    }
                    
                    /*if(PropTeamMemberIds.contains(currentUserId)){
                        res.Is_Files_Accessible = 'YES';
                        res.Is_Notes_Accessible = 'YES';
                        system.debug('prop team yes');
                    }
                    else{
                        res.Is_Files_Accessible = 'NO';
                        res.Is_Notes_Accessible = 'NO';
                        system.debug('prop team no');
                    }*/
                }
            }
            else{
                res.Is_Files_Accessible = 'YES';
                res.Is_Notes_Accessible = 'YES';
            }
        }
        catch(Exception e){
            system.debug('----Exception Encoutered----' + e.getMessage());
            res.Exception_Message = e.getMessage();
        }
        
        return res;
    }
    
    @AuraEnabled
    public static Map<Integer, List<ContentDocument>> getRelatedFiles(Id caseId)
    {   
        Map<Integer, List<ContentDocument>> sizeIndicatorVsallFiles = new Map<Integer, List<ContentDocument>>();
        List<ContentDocumentLink> CDLs = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];

        List<Id> CDIdList = new List<Id>();
        for (ContentDocumentLink nextCDL : CDLs){
            CDIdList.add(nextCDL.ContentDocumentId); 
        }        

        List<ContentDocument> allFiles = [SELECT Id, Title, FileType, CreatedDate, ContentSize 
                                       FROM ContentDocument 
                                       WHERE Id IN :CDIdList AND FileType != 'SNOTE'
                                       ORDER BY CreatedDate DESC];
        
        List<ContentDocument> limitedFiles = new List<ContentDocument>();
        
        if(allFiles.size() > 3){
            for(Integer i = 0; i < 3; i++){
                limitedFiles.add(allFiles[i]);
            }
            
            sizeIndicatorVsallFiles.put(allFiles.size(), limitedFiles);
        }else{
            sizeIndicatorVsallFiles.put(allFiles.size(), allFiles);
        }
       
        return sizeIndicatorVsallFiles	;
    }
    
    @AuraEnabled
    public static Map<Integer, List<ContentNote>> getRelatedNotes(Id caseId)
    {   
        Map<Integer, List<ContentNote>> sizeIndicatorVsallNotes = new Map<Integer, List<ContentNote>>();
        List<ContentDocumentLink> CDLs = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];
        
        List<Id> CDIdList = new List<Id>();
        for (ContentDocumentLink nextCDL : CDLs){
            CDIdList.add(nextCDL.ContentDocumentId); 
        }
        
        List<ContentNote> allNotes = [SELECT Id, Title, CreatedDate  
                            FROM ContentNote 
                            WHERE Id = : CDIdList
                            ORDER BY CreatedDate DESC];
        
        List<ContentNote> limitedNotes = new list<ContentNote>();
                
        if(allNotes.size() > 3){
            for(Integer i = 0; i < 3; i++){
                limitedNotes.add(allNotes[i]);
            }
            
            sizeIndicatorVsallNotes.put(allNotes.size(), limitedNotes);
        }else{
            sizeIndicatorVsallNotes.put(allNotes.size(), allNotes);
        }
       
        return sizeIndicatorVsallNotes	;
    }
    
    @AuraEnabled
    public static Response createNewNote(ContentNote noteRec, Id caseId){
        Response res = New Response();
        try{
            if(noteRec != null){
                insert noteRec;
                ContentDocument cd=[SELECT Id FROM ContentDocument WHERE Id =: noteRec.Id];
                ContentDocumentLink cdl=new ContentDocumentLink();
                cdl.ContentDocumentId = cd.Id;
                cdl.LinkedEntityId = caseId;
                //cdl.ShareType='V';
                //cdl.Visibility='AllUsers';
                insert cdl;
                res.Success_Message = 'New Note Created Successfully';
            }
        } catch (Exception ex){
			res.Exception_Message = ex.getMessage();
        }
        
        return res;
    }    
        
}