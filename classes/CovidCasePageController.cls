public class CovidCasePageController {
        
    @AuraEnabled
    public static Map<String, List<CovidCaseVisibilitySetting__mdt>> getFieldsToShow(Id recordId){
        Boolean iSectionAccessible = checkSectionAccess(recordId);
        
        Map<String, List<CovidCaseVisibilitySetting__mdt>> sctionNamevsMetadataRecords = new Map<String, List<CovidCaseVisibilitySetting__mdt>>();
        
        List<SectionAndUserAccessOnCovidCase__mdt> parentMetadata = [SELECT MasterLabel, DeveloperName, Sort_Number__c, Show_by_Default__c, 
                                                                     (SELECT MasterLabel, DeveloperName, Field_API_Name__c, Sort_Number__c, 
                                                                      Is_Ready_Only__c, Is_Required__c, SectionAndUserAccessOnCovidCase__c, SectionAndUserAccessOnCovidCase__r.MasterLabel
                                                                      FROM CovidCaseVisibilitySetting__r) 
                                                                     FROM SectionAndUserAccessOnCovidCase__mdt
                                                                     ORDER BY Sort_Number__c];
        
        
       
        Map<String, Map<Integer, CovidCaseVisibilitySetting__mdt>> parentVsChildMap = new  Map<String, Map<Integer, CovidCaseVisibilitySetting__mdt>>();
        CovidCasePageController obj = new CovidCasePageController();
        for(SectionAndUserAccessOnCovidCase__mdt mdtParent : parentMetadata){
            System.debug('iSectionAccessible: '+iSectionAccessible+', Show_by_Default__c: '+mdtParent.Show_by_Default__c);
            if(!iSectionAccessible && !mdtParent.Show_by_Default__c)
                    continue;
            
            for(CovidCaseVisibilitySetting__mdt mdtChild : mdtParent.CovidCaseVisibilitySetting__r){
                Integer childSortNumber = (Integer) mdtChild.Sort_Number__c;
                
                if(parentVsChildMap.containsKey(mdtParent.MasterLabel)){
                    parentVsChildMap.get(mdtParent.MasterLabel).put(childSortNumber, mdtChild);
                }else{                    
                    parentVsChildMap.put(mdtParent.MasterLabel, new Map<Integer, CovidCaseVisibilitySetting__mdt>());
                    parentVsChildMap.get(mdtParent.MasterLabel).put(childSortNumber, mdtChild);
                }
            }
        }
        
        for(SectionAndUserAccessOnCovidCase__mdt mdtParent : parentMetadata){
            System.debug('iSectionAccessible: '+iSectionAccessible+', Show_by_Default__c: '+mdtParent.Show_by_Default__c);
            if(!iSectionAccessible && !mdtParent.Show_by_Default__c)
                    continue;
            
            for(Integer index = 0; index <= parentVsChildMap.get(mdtParent.MasterLabel).size(); index++){
                if(!parentVsChildMap.get(mdtParent.MasterLabel).containsKey(index))
                    continue;
                
                CovidCaseVisibilitySetting__mdt mdtChildRec = parentVsChildMap.get(mdtParent.MasterLabel).get(index);
                System.debug('mdtChildRec : '+mdtChildRec );
                if(sctionNamevsMetadataRecords.containsKey(mdtParent.MasterLabel)){
                    sctionNamevsMetadataRecords.get(mdtChildRec.SectionAndUserAccessOnCovidCase__r.MasterLabel).add(mdtChildRec);
                }else{                    
                    sctionNamevsMetadataRecords.put(mdtParent.MasterLabel, new List<CovidCaseVisibilitySetting__mdt>());
                    sctionNamevsMetadataRecords.get(mdtChildRec.SectionAndUserAccessOnCovidCase__r.MasterLabel).add(mdtChildRec);
                }            
            }
        }
        
        
        
        return sctionNamevsMetadataRecords;
    }
    
    /*@AuraEnabled
    public static List<CovidCaseVisibilitySetting__mdt> getRequiredFields(){
        List<CovidCaseVisibilitySetting__mdt> reqFields = new List<CovidCaseVisibilitySetting__mdt>();
        
        for(CovidCaseVisibilitySetting__mdt fields : [SELECT MasterLabel, Is_Required__c, Field_API_Name__c FROM CovidCaseVisibilitySetting__mdt]){
        	if(fields.Is_Required__c)
                reqFields.add(fields);
        }
            
        return reqFields;
        
    }*/
    
    @AuraEnabled
    public static Boolean checkSectionAccess(Id recordId){
        
        Boolean isDataAccessibleToLogggedInUser = FALSE;
        List<Profile> sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'SCG-SysAdm'];
        Case cs = [SELECT Id, TECH_Is_National_Account__c, Space__c, Space__r.Property__c, OwnerId FROM Case WHERE Id = :recordId];

        if((UserInfo.getProfileId() == sysAdminProfile[0].Id || UserInfo.getProfileId() == sysAdminProfile[1].Id || UserInfo.getUserId() == cs.OwnerId) && !Test.isRunningTest())
            return TRUE;
        
        
        if(UserInfo.getName() == 'John Papagiannis' || UserInfo.getName() == 'Andrew Hulls' || UserInfo.getName() == 'Courtney Kingston')
            return TRUE;
        
        if(cs.TECH_Is_National_Account__c){
            for(CaseTeamMember csMem : [SELECT MemberId, ParentId, Parent.Property__c, Parent.Account.Is_National_Account__c FROM CaseTeamMember WHERE ParentId = :recordId]){
                
                if(UserInfo.getUserId() == csMem.MemberId)
                    isDataAccessibleToLogggedInUser = TRUE;
            }    
        }else{
            for(PropertyTeam__c propTeams : [SELECT Id, TeamMember__c FROM PropertyTeam__c WHERE Property__c = :cs.Space__r.Property__c AND Active__c = TRUE]){
                
                if(UserInfo.getUserId() == propTeams.TeamMember__c)
                    isDataAccessibleToLogggedInUser = TRUE;
            }
        }
        
        return isDataAccessibleToLogggedInUser;
    }
    
    @AuraEnabled
    public static String getCaseRecordType(){
        return Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.LVI_COVID19).getRecordTypeId();
	}
    
    @AuraEnabled
    public static Boolean isCaseLocked(Id caseId){
        return Approval.isLocked(caseId);
    }
}