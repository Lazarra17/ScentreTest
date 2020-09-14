/**
* Class CaseTriggerHandler
*
* Trigger Handler for the Case SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*
**/
public without sharing class CaseTriggerHandler extends TriggerHandler
implements ITrigger {
    
    List<CaseEvent__e> caseEventsToPublish = new List<CaseEvent__e>();
    
    private static Map<Id, Account> accountMap = new Map<Id, Account>();
    Map<String, Map<String, String>> approvalMatrixMap = new Map<String, Map<String, String>>();
    Map<Id, Map<String, PropertyTeam__c>> propIdPropertyTeamMap = new Map<Id, Map<String, PropertyTeam__c>>();
    Map<Id, Map<String, AccountTeamMember>> accIdAccountTeamMap = new Map<Id, Map<String, AccountTeamMember>>();
    
    Map<String,Set<String>> fieldSetandfieldAPInameCase = new Map<String,Set<String>>(); //10532
    public List<BillingNotRequiredEditable__mdt>  UserListtoEditBNR = new List<BillingNotRequiredEditable__mdt>(); //10532
    //Profile AdminId = new Profile(); //10532
    //Profile integratiUser = new Profile(); //10532   
    //Profile CustomAdminId = new Profile(); //10532 
    
    public static Map<Id, Profile> requiredProfilesMap = new Map<Id, Profile>();
    
    private static Map<Id,Schema.RecordTypeInfo> caseRecordTypeMap;
    private static Map<String,Schema.RecordTypeInfo> caseRecordTypeNameMap;
    private static Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByDeveloperName;
    
    private TaskUtility.TaskOwnerWrapper taskOwnerWrap = new TaskUtility.TaskOwnerWrapper();
    private List<Task> newTaskList = new List<Task>();
    private List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>();
    private static Map<String, Schema.RecordTypeInfo> taskRecordTypeMap;
    
    private Set<Id> unlockCaseRecordIdSet = new Set<Id>();
    private Set<Id> lockCompletedCaseRecordIdSet = new Set<Id>();
    private List<Case> childCaseList = new List<Case>();
    private Map<Id, Case> parentCaseMap = new Map<Id, Case>();
    
    private Map<Id, Space__c> caseSpaceMap = new Map<Id, Space__c>();
    Map<String, Schema.SObjectField> cseMapFields = Schema.SObjectType.Case.fields.getMap();
    Set<String> ownerEditableFields = new Set<String>{ 'ownerid', 'status' };
    Set<String> nonOwnerEditableFields = new Set<String>{ 'ownerid' };
    
    private Set<Id> spaceIdSetCaseLV05 = new Set<Id>(); 
    private List<Opportunity> oppListSpaceCaseLV05 = new List<Opportunity>();
    //private List<Opportunity> oppListToExcludeForUpdate = new List<Opportunity>();  //10771
    Map<Id,Case> newIdCaseMap = new map<Id, Case>();                                //10771
    private Map<Id,Date> spaceIdTermLeaseDateMap = new Map<Id,Date>();
    private List<Opportunity> oppListToUpdate = new List<Opportunity>(); 
    private Map<Id,Id> contractSpaceMap = new Map<Id,Id>();
    private List<Space__c> caseContractSpaceList = new List<Space__c>();
    private List<Space__c> spaceListToUpdate = new List<Space__c>();
    
    public List<CaseTeamMember> caseTeamsToInsert = new List<CaseTeamMember>();
    
    //RPP-11090 - Variable declarations START
    public List<Copy_Covid_Case_Details__mdt> copyCovidMetadata;
    public List<Case> childCases = new List<Case>();
    public List<Case> childCasesToUpdate = new List<Case>();
    public Map<Id, Case> parentCovidCaseVsTaskList = new Map<Id, Case>();
    //RPP-11090 - END
    
    //RPP-11100
    public static List<Covid_Case_Rental_Assistan__mdt> covidRentalAsstMetadataList;
    //RPP-11100
    // Constructor
    public CaseTriggerHandler()
    {
    }
    
    /**
* bulkBefore
*
* This method is called prior to execution of a BEFORE trigger. Use this to cache
* any data required into maps prior execution of the trigger.
**/
    public void bulkBefore() {
        caseRecordTypeMap = RecordTypeUtil.getAllRecordTypesById(Constants.OBJECT_CASE);
        taskRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        
        
        fieldSetandfieldAPInameCase =SchemaDescribeBL.describefieldnamefromFS(Constants.OBJECT_CASE,Constants.CASE_BILLING_NOTREQ_FIELDSET); //10532
        UserListtoEditBNR = [SELECT MasterLabel, User_record_Id__c FROM BillingNotRequiredEditable__mdt]; //10532
        if(covidRentalAsstMetadataList == NULL || covidRentalAsstMetadataList.isEmpty()){
            covidRentalAsstMetadataList = [SELECT MasterLabel, Start_Date__c, End_Date__c FROM Covid_Case_Rental_Assistan__mdt];
        }
        
        //AdminId = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator'];//10532
        //integratiUser = [SELECT Id,Name FROM Profile WHERE Name = 'SCG-Sys Integration'];//10532
        //CustomAdminId = [SELECT Id,Name FROM Profile WHERE Name = 'SCG-SysAdm'];//10532
        
        if(requiredProfilesMap.size() == 0)
            requiredProfilesMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' OR Name = 'SCG-Sys Integration' OR Name = 'SCG-SysAdm']);
        
        if(Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> spaceIdSet = new Set<Id>();
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> propertyIdSet = new Set<Id>();
            Set<Id> parentAccountIdSet = new Set<Id>();
            Set<Id> parentCaseIdSet = new Set<Id>();
            
            for(Case newCase : (List<Case>) Trigger.new){
                if(newCase.TechPropertyId__c != null){
                    propertyIdSet.add(newCase.TechPropertyId__c);
                }
                
                if(newCase.AccountId != null){
                    accountIdSet.add(newCase.AccountId);
                }
                
                if(newCase.Space__c != null){
                    spaceIdSet.add(newCase.Space__c);
                }
                if (newCase.ParentId != null) {
                    parentCaseIdSet.add(newCase.ParentId);
                }
            }
            parentCaseMap = DatabaseSOQLBank.getCase(parentCaseIdSet);
            accountMap = DatabaseSOQLBank.getAccountById(accountIdSet);
            system.debug('accountMap : ' + accountMap);
            if(Trigger.isInsert) {
                // CaseBL.getRelevantCaseOwners(accountIdSet, propertyIdSet); 
                system.debug('noofRecords : ' + Trigger.new.size());
                for(Account acc : accountMap.values()){
                    if(acc.ParentId != null){
                        parentAccountIdSet.add(acc.ParentId);
                        
                        if(acc.Parent.ParentId != null){
                            parentAccountIdSet.add(acc.Parent.ParentId);
                        }
                    }
                }
                
                approvalMatrixMap = DatabaseSOQLBank.getApprovalMatrixMetadata();
                accIdAccountTeamMap = DatabaseSOQLBank.getAccountTeamPerAccount(parentAccountIdSet);
                propIdPropertyTeamMap = DatabaseSOQLBank.getPropertyTeamByProperty(propertyIdSet);
                caseSpaceMap = DatabaseSOQLBank.getSpaceRecords(spaceIdSet);
            }
            
            system.debug('approvalMatrixMap : ' + approvalMatrixMap);
            system.debug('propIdPropertyTeamMap : ' + propIdPropertyTeamMap);
            
            if(Trigger.isUpdate) {
                
            }
        }
        
        //RPP-11100 Start
        if(Trigger.isInsert){
            
            for(Case newCase : (List<Case>) Trigger.new){
                if(newCase.Rental_Assistance_Period__c != '' && newCase.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST){
                    
                    for(Covid_Case_Rental_Assistan__mdt covidRentalAsstMetadata : covidRentalAsstMetadataList){
                        if(covidRentalAsstMetadata.MasterLabel == newCase.Rental_Assistance_Period__c){
                            
                            if(newCase.Rental_Assistance_Start_Date__c == NULL){
                            	newCase.Rental_Assistance_Start_Date__c = covidRentalAsstMetadata.Start_Date__c;
                        	}
                        	if(newCase.Rental_Assistance_End_Date__c == NULL){
                            	newCase.Rental_Assistance_End_Date__c = covidRentalAsstMetadata.End_Date__c;
                        	}
                        }
                    }
                }
            }
        }
        
        if(Trigger.isUpdate){
            
            for(Case newCase : (List<Case>) Trigger.new){
                if(newCase.Rental_Assistance_Period__c != '' && newCase.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST){
                    Case oldCase = (Case)Trigger.oldMap.get(newCase.ID);
                    if(newCase.Rental_Assistance_Period__c != oldCase.Rental_Assistance_Period__c){
                        
                        for(Covid_Case_Rental_Assistan__mdt covidRentalAsstMetadata : covidRentalAsstMetadataList){
                            if(covidRentalAsstMetadata.MasterLabel == newCase.Rental_Assistance_Period__c){
                                
                                if(newCase.Rental_Assistance_Start_Date__c == oldCase.Rental_Assistance_Start_Date__c || newCase.Rental_Assistance_Start_Date__c == NULL){
                                    newCase.Rental_Assistance_Start_Date__c = covidRentalAsstMetadata.Start_Date__c;
                                }
                                if(newCase.Rental_Assistance_End_Date__c == oldCase.Rental_Assistance_End_Date__c || newCase.Rental_Assistance_End_Date__c == NULL){
                                    newCase.Rental_Assistance_End_Date__c = covidRentalAsstMetadata.End_Date__c;
                                }
                            }
                        }
                    }
                }
            }
        }
        //RPP-11100 End
    }
    
    public void bulkAfter(){
        caseRecordTypeNameMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        caseRecordTypeMapByDeveloperName  = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OBJECT_CASE);
        System.debug('IN BULK AFTER >>> :');
        if(Trigger.isInsert || Trigger.isUpdate) {
            List<Case> completedLV02 = new List<Case>();
            List<Case> rejectedLV02 = new List<Case>();
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> propertyIdSet = new Set<Id>();
            Set<Id> parentCaseIdSet = new Set<Id>();
            System.debug('Trigger.newmap ' + Trigger.newmap);
            Map<Id, Case> dbCaseDataMapToPublish = CaseBL.caseEventTriggerCriteriaCheckMap(Trigger.newmap);
            System.debug('dbCaseDataMapToPublish ' + dbCaseDataMapToPublish);
            EventpublishHelper.Eventpublishwrapper caseWrapper = new EventpublishHelper.Eventpublishwrapper();
            
            //RPP-10771 - START
            List<Case> newCaseList = new List<Case>();
            Set<Id> caseIdSet1 = new Set<Id>();
            newCaseList = (List<Case>) Trigger.new;
            for(Case cs1: newCaseList){
                caseIdSet1.add(cs1.Id);
            }
            
            //List<CaseTeamMember> caseTeamsToCreate = new List<CaseTeamMember>();
            //List<CaseTeamMember> caseTeamsToCreate = CaseBL.populateCaseTeamMembers(newCaseList);
            
            newIdCaseMap = new map<Id, Case>([SELECT Id,Contract__c,Contract__r.ActualVacateDate__c,Contract__r.Opportunity__c,Space__c,Space__r.LatestAchievedOpportunity__c
                                              FROM Case
                                              WHERE Id IN: caseIdSet1]);
            //RPP-10771 - END
            
            if(EventpublishHelper.isValidpublish() && dbCaseDataMapToPublish !=null && dbCaseDataMapToPublish.size()>0){
                caseWrapper = EventpublishHelper.caseFieldChangePublishHelper(Trigger.oldMap, Trigger.newMap, dbCaseDataMapToPublish);
                System.debug('caseWrapper ' + caseWrapper);
                caseEventsToPublish.addAll((List<CaseEvent__e>) caseWrapper.eventsobjectList);
            }
            System.debug('caseEventsToPublish ' + caseEventsToPublish);
            for(Case cas : (List<Case>) Trigger.new){
                Case oldCase = new Case();
                
                if(Trigger.isInsert){
                    if(cas.TechPropertyId__c != null){
                        propertyIdSet.add(cas.TechPropertyId__c);
                    }
                }
                if(Trigger.isUpdate){
                    oldCase = (Case) trigger.oldMap.get(cas.Id);
                    
                    //RPP - 4286 - Janus Gargoles - START - 06/18/2019
                    if(cas.RecordTypeId == caseRecordTypeNameMap.get(Constants.TERMINATE_A_LEASE).getRecordTypeId() &&
                       (oldCase.Status != cas.Status && cas.Status == Constants.CASE_STATUS_APPROVED)){
                           if(cas.Space__c != null){
                               spaceIdSetCaseLV05.add(cas.Space__c);
                               if(cas.TerminateLeaseDate__c != null){
                                   spaceIdTermLeaseDateMap.put(cas.Space__c, cas.TerminateLeaseDate__c);
                                   if(cas.TerminateLeaseDate__c <= Date.today() && cas.Contract__c != null){
                                       contractSpaceMap.put(cas.Space__c, cas.Contract__c);
                                   }
                               }
                           }
                       }
                    //RPP - 4286 - Janus Gargoles - END - 06/18/2019   
                    
                    
                    
                    if(cas.TechHasChildCase__c){
                        parentCaseIdSet.add(cas.Id);
                    }
                    
                    
                    // RPP-10622 START LF 08/06/2019
                    if (oldCase.Status != cas.Status && cas.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED)
                        && cas.OldOpportunity__c != null && cas.Opportunity__c != null
                        && cas.RecordTypeId == caseRecordTypeMapByDeveloperName.get(Constants.LV02_SPECIALTY_VARIATION).getRecordTypeId()
                        && (cas.Capital__c)) {
                            completedLV02.add(cas);
                        }
                    // RPP-10622 END LF 08/06/2019
                    // RPP-10577 START LF 08/27/2019
                    if (oldCase.Status != cas.Status && cas.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_REJECTED)
                        && cas.RecordTypeId == caseRecordTypeMapByDeveloperName.get(Constants.LV02_SPECIALTY_VARIATION).getRecordTypeId()) {
                            rejectedLV02.add(cas);	
                        }
                    // RPP-10577 END LF 08/27/2019                    
                }
            }
            
            // RPP-10622 START LF 08/06/2019
            if (completedLV02.size() > 0) {
                LV02CaseBL.updateOriginalOpps(completedLV02);
            }
            // RPP-10622 END LF 08/06/2019
            
            // RPP-10577 START LF 08/27/2019
            if (rejectedLV02.size() > 0) {
                LV02CaseBL.unlockVariationOpps(rejectedLV02);
            }
            // RPP-10577 END LF 08/27/2019
            
            //RPP - 4286 - Janus Gargoles - START - 06/18/2019
            if(spaceIdSetCaseLV05.size() != 0){
                try{
                    oppListSpaceCaseLV05 = DatabaseSOQLBank.getOpportunityFromSpace(spaceIdSetCaseLV05);
                    caseContractSpaceList = DatabaseSOQLBank.getSpaces(spaceIdSetCaseLV05);
                }catch(Exception e){
                    oppListSpaceCaseLV05 = null;
                    caseContractSpaceList = null;
                }   
            }
            
            //Call new method on CaseBL.updateFRTerminationDate to update the opportunities Forecasted Rent Termination Date
            if((!oppListSpaceCaseLV05.isEmpty() && oppListSpaceCaseLV05.size() != 0) && (spaceIdTermLeaseDateMap.size() != 0)){
                oppListToUpdate = CaseBL.updateFRTerminationDate(oppListSpaceCaseLV05, spaceIdTermLeaseDateMap);
                System.debug('back from CaseBL oppListToUpdate' + oppListToUpdate);
            }
            if((!caseContractSpaceList.isEmpty() && caseContractSpaceList.size() != 0) && (contractSpaceMap.size() != 0)){
                spaceListToUpdate = CaseBL.updateSpaceStatus(caseContractSpaceList, contractSpaceMap);
            }
            //RPP - 4286 - Janus Gargoles - END - 06/18/2019 
            
            //RPP-10771 - START
            List<Opportunity> opListToupdateCopy = new List<Opportunity>();
            opListToupdateCopy.addAll(oppListToUpdate);
            for(Case cas : (List<Case>) Trigger.new){
                if(newIdCaseMap.containskey(cas.Id)){
                    Case casTemp = newIdCaseMap.get(cas.Id);
                    //if(newIdCaseMap.get(cas.Id).Contract__r.ActualVacateDate__c != null){
                    if(newIdCaseMap.get(cas.Id).Contract__r.Opportunity__c == newIdCaseMap.get(cas.Id).Space__r.LatestAchievedOpportunity__c){
                        //if(casTemp.Contract__r.Opportunity__c == casTemp.Space__r.LatestAchievedOpportunity__c){
                        for(Opportunity opp : opListToupdateCopy){
                            if(opp.Id == casTemp.Contract__r.Opportunity__c)
                                oppListToUpdate.remove(oppListToUpdate.indexOf(opp));
                        }
                    }
                    //}
                }
            } 
            System.debug('oppListToUpdate  >>>  '+oppListToUpdate);
            //RPP-10771 - END
            
            childCaseList = DatabaseSOQLBank.getChildCase(parentCaseIdSet);
            
            if(Trigger.isInsert || Trigger.isUpdate) {
                try{
                    taskTemplateList = DatabaseSOQLBank.getTaskTemplate(Constants.OBJECT_CASE);
                } catch(Exception e){
                    taskTemplateList = null;
                }
                
                if(accountMap != null){
                    for(Account acc : accountMap.values()){
                        if(acc.ParentId != null){
                            accountIdSet.add(acc.ParentId);
                            
                            if(acc.Parent.ParentId != null){
                                accountIdSet.add(acc.Parent.ParentId);
                            }
                        }
                    }
                }
                
                taskOwnerWrap = TaskUtility.getOppAndPropertyTeamMember(propertyIdSet, null, accountIdSet);
            }
            
            if(Trigger.isInsert) {
                //List<CaseTeamMember> caseTeamsToInsertTemp = new List<CaseTeamMember>();
                //caseTeamsToInsertTemp.addAll(CaseBL.populateCaseTeamMembers(newCaseList));
                //if(caseTeamsToInsertTemp.size() > 0)
                //caseTeamsToInsert.addAll(CaseBL.populateCaseTeamMembers(newCaseList));
                for(CaseTeamMember csMem : CaseBL.populateCaseTeamMembers(newCaseList)){
                    caseTeamsToInsert.add(csMem);
                }
            }
            //RPP-11090 - START
            if(Trigger.isUpdate){
                Set<Id> parentCaseIds = CaseBL.getCovidParentCaseSet(newCaseList);
                if(parentCaseIds.size() > 0){
                	copyCovidMetadata = DatabaseSOQLBank.getCopyCovidCaseDetailsMetadata();
                	childCases = DatabaseSOQLBank.getChildCases(parentCaseIds, copyCovidMetadata);
                    parentCovidCaseVsTaskList = new Map<Id, Case>(DatabaseSOQLBank.parentCovidCaseVsTaskList(parentCaseIds));
                }
            }
            //RPP-11090 - END
        }
    }
    
    public void beforeInsert(SObject so){
        String caseRecTypeName;
        Space__c caseSpace;
        Account caseAccount;
        Case newCase = (Case) so;
        Map<String, String> matrixRoleFieldMap;
        Map<String, PropertyTeam__c> propertyTeamPerRoleMap;
        Map<String, AccountTeamMember> accountTeamPerRoleMap;
        
        caseRecTypeName = caseRecordTypeMap.get(newCase.RecordTypeId).getName();
        
        system.debug('caseRecTypeName :' + caseRecTypeName);
        
        if(approvalMatrixMap.containsKey(caseRecTypeName)){
            matrixRoleFieldMap = approvalMatrixMap.get(caseRecTypeName);
        }
        
        if(propIdPropertyTeamMap.containsKey(newCase.TechPropertyId__c)){
            propertyTeamPerRoleMap = propIdPropertyTeamMap.get(newCase.TechPropertyId__c);
        }
        
        
        if(accountMap.containsKey(newCase.AccountId)){
            caseAccount = accountMap.get(newCase.AccountId);
        }
        
        if(newCase.Space__c != null && caseSpaceMap.containsKey(newCase.Space__c)){
            caseSpace = caseSpaceMap.get(newCase.Space__c);
            if(caseSpace.Property__r.Country__c==Constants.NEW_ZEALAND){
                newCase.CurrencyISOCode=Constants.CURRENCYCODENZD;
            }else{
                newCase.CurrencyISOCode=Constants.CURRENCYCODEAUD;
            }
            
        }
        
        //system.debug('matrixRoleFieldMap :' + matrixRoleFieldMap);
        //system.debug('beforeInsert--propertyTeamPerRoleMap :' + propertyTeamPerRoleMap);
        //system.debug('beforeInsert--accountMap: ' + accountMap);
        //system.debug('beforeInsert--caseAccount: ' + caseAccount);
        //system.debug('beforeInsert--accIdAccountTeamMap: ' + accIdAccountTeamMap);
        
        /*if(accIdAccountTeamMap.containsKey(newCase.AccountId)){
accountTeamPerRoleMap = accIdAccountTeamMap.get(newCase.AccountId);
}*/
        
        CaseBL.updateCaseOwner(newCase, caseSpace, caseRecTypeName, caseAccount, accIdAccountTeamMap, propertyTeamPerRoleMap);
        CaseBL.updateCaseApprovers(newCase, matrixRoleFieldMap, propertyTeamPerRoleMap, caseSpace, caseRecTypeName);
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){
        Case updateCase = (Case) so;
        Case oldCase = (Case) oldSo;
        
        String caseRecordTypeName;
        
        
        /*//System.debug('UserListtoEditBNR>>>'+UserInfo.getProfileId() + ' ====== ' + integratiUser.Id + ' ==== ' + Approval.isLocked(oldCase.Id));
//start10532
if(UserInfo.getProfileId() == integratiUser.Id && Approval.isLocked(oldCase.Id)){
System.debug('Case unlocked on line no. 360');
Approval.unlock(oldCase.Id);
}else if(UserInfo.getProfileId() == AdminId.Id && oldCase.Status == Constants.CASE_STATUS_COMPLETED
&& updateCase.Status != oldCase.Status){
//This else if block is added to implement RPP - 11024
Approval.unlock(oldCase.Id);
}else if(!(UserInfo.getProfileId() == AdminId.Id || 
UserInfo.getProfileId() == CustomAdminId.Id || 
UserInfo.getProfileId() == integratiUser.Id)){   //check for system admin
//unlock the record first
System.debug('UserListtoEditBNR>>>'+UserListtoEditBNR);
System.debug('oldCase.Status === '+oldCase.Status);
System.debug('updateCase.Status === '+updateCase.Status);
System.debug('isLocked === '+Approval.isLocked(oldCase.Id));
if(Approval.isLocked(oldCase.Id) && oldCase.Status != Constants.CASE_STATUS_COMPLETED){
System.debug('Case unlocked on line no. 369');
Approval.unlock(oldCase.Id);
}

Boolean BNRUser = False;
String CurrentUserId = UserInfo.getUserId();


for(BillingNotRequiredEditable__mdt BNRUser1 : UserListtoEditBNR){

if(CurrentUserId != BNRUser1.User_record_Id__c){
BNRUser = TRUE;
System.debug('BNRUser'+BNRUser);
} 
}


//String caseRecordTypeName;
Set<String> caseSkipRTypes = new Set<String>{constants.RETAIL_DESIGN_BILLING};
caseRecordTypeName = caseRecordTypeMap.get(updateCase.RecordTypeId).getName();
System.debug('caseSkipRTypes '+caseSkipRTypes);
System.debug('caseRecordTypeName '+caseRecordTypeName);


Boolean OtherFupdated =False;
Boolean BNRupdated =False;
//if the user is Kara Adams, check if other fields are changed,if yes> then error
if(!BNRUser){
if(caseSkipRTypes.contains(caseRecordTypeName)){
if(oldCase.Status == CONSTANTS.CASE_STATUS_COMPLETED 
|| oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_BATCH_PROCESSING) 
|| oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_CANCELLED)){

for(String fieldapiname :fieldSetandfieldAPInameCase.get(Constants.CASE_BILLING_NOTREQ_FIELDSET)){
if(updateCase.get(fieldapiname) != oldCase.get(fieldapiname)){

system.debug('debug 1 for Kara updating ');
updateCase.addError('This record is Locked. If you need to edit it,contact your Admin.(Kara Adams)'); 
}
}
}
}

}
//if any other user is changing any field, error
else if(caseSkipRTypes.contains(caseRecordTypeName)){
if(oldCase.Status == CONSTANTS.CASE_STATUS_COMPLETED || oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_BATCH_PROCESSING) || oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_CANCELLED)){

for(String fieldapiname :fieldSetandfieldAPInameCase.get(Constants.CASE_BILLING_NOTREQ_FIELDSET)){

if(updateCase.get(fieldapiname) != oldCase.get(fieldapiname)){

OtherFupdated = True; 
}
}
if(updateCase.Billing_Not_Required__c != oldCase.Billing_Not_Required__c){
BNRupdated = True;
}
if(OtherFupdated || BNRupdated){
updateCase.addError('This record is Locked. If you need to edit it,contact your Admin. (other users)'); 
}
}
}

}  
//end10532*/
        
        //System.debug('UserListtoEditBNR>>>'+UserInfo.getProfileId() + ' ====== ' + integratiUser.Id + ' ==== ' + Approval.isLocked(oldCase.Id));
        //start10532
        Boolean isIntegrationProfile = (requiredProfilesMap.containsKey(UserInfo.getProfileId()) && requiredProfilesMap.get(UserInfo.getProfileId()).Name == 'SCG-Sys Integration') ? TRUE : FALSE;
        Boolean isAdminProfile = (requiredProfilesMap.containsKey(UserInfo.getProfileId()) && requiredProfilesMap.get(UserInfo.getProfileId()).Name == 'System Administrator') ? TRUE : FALSE;
        Boolean isCustomAdminProfile = (requiredProfilesMap.containsKey(UserInfo.getProfileId()) && requiredProfilesMap.get(UserInfo.getProfileId()).Name == 'SCG-SysAdm') ? TRUE : FALSE;
        
        if(isIntegrationProfile && Approval.isLocked(oldCase.Id)){
            System.debug('Case unlocked on line no. 360');
            Approval.unlock(oldCase.Id);
        }else if(isAdminProfile && oldCase.Status == Constants.CASE_STATUS_COMPLETED && updateCase.Status != oldCase.Status){
            //This else if block is added to implement RPP - 11024
            Approval.unlock(oldCase.Id);
        }else if(!(isAdminProfile || isCustomAdminProfile || isIntegrationProfile)){   //check for system admin
            System.debug('UserListtoEditBNR>>>'+UserListtoEditBNR);
            System.debug('oldCase.Status === '+oldCase.Status);
            System.debug('updateCase.Status === '+updateCase.Status);
            System.debug('isLocked === '+Approval.isLocked(oldCase.Id));
            if(Approval.isLocked(oldCase.Id) && oldCase.Status != Constants.CASE_STATUS_COMPLETED){
                System.debug('Case unlocked on line no. 369');
                Approval.unlock(oldCase.Id);
            }
            
            Boolean BNRUser = False;
            String CurrentUserId = UserInfo.getUserId();
            
            
            for(BillingNotRequiredEditable__mdt BNRUser1 : UserListtoEditBNR){
                
                if(CurrentUserId != BNRUser1.User_record_Id__c){
                    BNRUser = TRUE;
                    System.debug('BNRUser'+BNRUser);
                } 
            }
            
            
            //String caseRecordTypeName;
            Set<String> caseSkipRTypes = new Set<String>{constants.RETAIL_DESIGN_BILLING};
                caseRecordTypeName = caseRecordTypeMap.get(updateCase.RecordTypeId).getName();
            System.debug('caseSkipRTypes '+caseSkipRTypes);
            System.debug('caseRecordTypeName '+caseRecordTypeName);
            
            
            Boolean OtherFupdated =False;
            Boolean BNRupdated =False;
            //if the user is Kara Adams, check if other fields are changed,if yes> then error
            if(!BNRUser){
                if(caseSkipRTypes.contains(caseRecordTypeName)){
                    if(oldCase.Status == CONSTANTS.CASE_STATUS_COMPLETED 
                       || oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_BATCH_PROCESSING) 
                       || oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_CANCELLED)){
                           
                           for(String fieldapiname :fieldSetandfieldAPInameCase.get(Constants.CASE_BILLING_NOTREQ_FIELDSET)){
                               if(updateCase.get(fieldapiname) != oldCase.get(fieldapiname)){
                                   
                                   system.debug('debug 1 for Kara updating ');
                                   updateCase.addError('This record is Locked. If you need to edit it,contact your Admin.(Kara Adams)'); 
                               }
                           }
                       }
                }
                
            }
            //if any other user is changing any field, error
            else if(caseSkipRTypes.contains(caseRecordTypeName)){
                if(oldCase.Status == CONSTANTS.CASE_STATUS_COMPLETED || oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_BATCH_PROCESSING) || oldCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_CANCELLED)){
                    
                    for(String fieldapiname :fieldSetandfieldAPInameCase.get(Constants.CASE_BILLING_NOTREQ_FIELDSET)){
                        
                        if(updateCase.get(fieldapiname) != oldCase.get(fieldapiname)){
                            
                            OtherFupdated = True; 
                        }
                    }
                    if(updateCase.Billing_Not_Required__c != oldCase.Billing_Not_Required__c){
                        BNRupdated = True;
                    }
                    if(OtherFupdated || BNRupdated){
                        updateCase.addError('This record is Locked. If you need to edit it,contact your Admin. (other users)'); 
                    }
                }
            }
            
        }  
        //end10532
        
        
        
        
        if(updateCase.Status != oldCase.Status){
            if(updateCase.Status == CONSTANTS.CASE_STATUS_INVALID){
                updateCase.Approved__c = false;
                updateCase.JDESentStatus__c = '';
                unlockCaseRecordIdSet.add(updateCase.Id);
                System.debug('unlockCaseRecordIdSet 440 === '+unlockCaseRecordIdSet);
            }else if (updateCase.Status == CONSTANTS.CASE_STATUS_MANUAL && oldCase.Status != Constants.CASE_STATUS_COMPLETED){
                unlockCaseRecordIdSet.add(updateCase.Id);
                System.debug('unlockCaseRecordIdSet 442 === '+unlockCaseRecordIdSet);
            } else if (updateCase.Status == CONSTANTS.CASE_STATUS_RESEND && oldCase.Status == CONSTANTS.CASE_STATUS_INVALID) {
                if (updateCase.JDESentStatus__c != 'Ready') {
                    updateCase.JDESentStatus__c = 'Ready';
                }
            }          
            
        }
        Boolean validUpdate = true;
        
        // ---
        System.debug('oldCase.Status: ' + oldCase.Status);
        // ---
        if(oldCase.Status == constants.CASE_STATUS_MANUAL){
            
            Id parentOwnerId = parentCaseMap.containsKey(oldCase.ParentId) ? parentCaseMap.get(oldCase.ParentId).ownerId : null;
            
            if (updateCase.Status == Constants.CASE_STATUS_COMPLETED_CANCELLED) {
                ownerEditableFields.add('reasonforcancellation__c');
            }
            
            System.debug('nonOwnerEditableFields === '+nonOwnerEditableFields);
            System.debug('ownerEditableFields === '+ownerEditableFields);
            
            for (String str : cseMapFields.keyset()) { 
                try {
                    if(updateCase.get(str) != oldCase.get(str)){
                        
                        if(oldCase.ownerid != userinfo.getuserid() && !userinfo.getuserid().equals(parentOwnerId)){
                            // Check if field is editable by non Owner
                            validUpdate = nonOwnerEditableFields.contains(str);
                        } else if (oldCase.ownerid == updateCase.ownerid){
                            validUpdate = ownerEditableFields.contains(str);
                            System.debug('Owner Updated ==='+ str);
                        }
                    } 
                } 
                catch (Exception e) { 
                    System.debug('Error: ' + e); 
                } 
            }     
            if(!validUpdate){
                updateCase.adderror(label.CaseManualErrorMessage);
            } 
            
        }
    }
    
    /**
* beforeDelete
*
* This method is called iteratively for each record to be deleted during a BEFORE
* trigger.
**/
    public void beforeDelete(SObject so)
    {
        
    }
    
    public void afterInsert(SObject so) {
        String caseRecordTypeName;
        Account caseAccount;
        Case newCase = (Case) so;
        
        if(caseRecordTypeMap.containsKey(newCase.RecordTypeId)){
            caseRecordTypeName = caseRecordTypeMap.get(newCase.RecordTypeId).getName();
        }
        
        if(accountMap != null && accountMap.containsKey(newCase.AccountId)){
            caseAccount = accountMap.get(newCase.AccountId);
        }
        
        //if(Constants.ASSIGN_OF_A_LEASE.equalsIgnoreCase(caseRecordTypeName)){
        if(taskTemplateList != null){
            newTaskList.addAll(
                TaskUtility.createCaseTask(
                    newCase, 
                    caseRecordTypeName,
                    taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                    taskTemplateList,
                    taskOwnerWrap,
                    caseAccount
                )
            );
        }
        //}
        //
    }
    
    public void afterUpdate(SObject oldSo, SObject so){
        Case updateCase = (Case) so;
        Case oldCase = (Case) oldSo;
        Account caseAccount;
            
        if(accountMap != null && accountMap.containsKey(updateCase.AccountId)){
            caseAccount = accountMap.get(updateCase.AccountId);
        }
        
        //was commented for 10532,added in before update (457-465)
        
        
        String caseRecordTypeName;
        Set<String> caseSkipRTypes = new Set<String>{constants.RETAIL_DESIGN_BILLING,constants.INSPECTION_REPORT, constants.RETAIL_DESIGN_INSTRUCTION, constants.STATEMENT_OF_COMPLETION};
            caseRecordTypeName = caseRecordTypeMap.get(updateCase.RecordTypeId).getName();
        
        //RPP - 11024 Start LF 31/3/2020
        if(updateCase.Status != oldCase.Status){
            if(oldCase.Status == Constants.CASE_STATUS_MANUAL && updateCase.Status == Constants.CASE_STATUS_COMPLETED){
                lockCompletedCaseRecordIdSet.add(updateCase.Id);
                System.debug('Record To Be Locked === '+updateCase.Id);
            }
        }
        //RPP - 11024 End LF 31/3/2020
        
        if(updateCase.Status != oldCase.Status && !caseSkipRTypes.contains(caseRecordTypeName)){
            if(updateCase.Status == CONSTANTS.CASE_STATUS_COMPLETED || 
               updateCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_BATCH_PROCESSING) || 
               updateCase.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_CANCELLED)){
                   
                   lockCompletedCaseRecordIdSet.add(updateCase.Id);
               }
        } 
        
        if((childCaseList != null && childCaseList.size() > 0) && (updateCase.Type == CONSTANTS.CASE_TYPE_LV04BANK_GUARANTEE || updateCase.Type == CONSTANTS.CASE_TYPE_LV18MISCELLANEOUS)){
            if(updateCase.Type == CONSTANTS.CASE_TYPE_LV04BANK_GUARANTEE && updateCase.Status == CONSTANTS.CASE_STATUS_MANUAL){
                for(Case caseRec : childCaseList){
                    caseRec.Status = CONSTANTS.CASE_STATUS_APPROVED;
                }
                
            } else if(updateCase.ParentId == null && updateCase.TechHasChildCase__c){
                
                for(Case caseRec : childCaseList){
                    caseRec.Status = updateCase.Status;
                }
                
            }
        }
        
        if(updateCase.Status != oldCase.Status){
            if(updateCase.Status == Constants.CASE_STATUS_COMPLETED_REJECTED && updateCase.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST){
                if(taskTemplateList != null){
                    newTaskList.addAll(
                        TaskUtility.createCaseTask(
                            updateCase, 
                            caseRecordTypeName,
                            taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                            taskTemplateList,
                            taskOwnerWrap,
                            caseAccount
                        )
                    );
                }
            }
        }
        
        //RPP-11090
        List<Case> casesToUpdate = CaseBL.updateChildCases(updateCase, oldCase, childCases, copyCovidMetadata);
        if(!casesToUpdate.isEmpty()){
            childCasesToUpdate.addAll(casesToUpdate);
        }
        for(Id parentId : CaseBL.parentCovidCaseIds){
            Case cs;
            if(parentCovidCaseVsTaskList.containsKey(parentId)){
                cs = parentCovidCaseVsTaskList.get(parentId);
                if(cs.Tasks.size() == 0){
                    Task tsk = new Task();
                    tsk.Subject = Constants.TASK_UPDATE_CHILD_CASES;
                    tsk.OwnerId = cs.OwnerId;
                    tsk.WhatId = cs.Id;
                    newTaskList.add(tsk);
                }
            }
        }
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    /**
* andFinally
*
* This method is called once all records have been processed by the trigger. Use this
* method to accomplish any final operations such as creation or updates of other records.
**/
    
    public void andFinally()
    {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(CaseTriggerHandler.class.getName());
        List<CaseEvent__e> successfullpublishCase = new List<CaseEvent__e>();
        System.debug('Finally caseEventsToPublish ' + caseEventsToPublish);
        if (caseEventsToPublish.size() > 0) {
            System.debug('caseEventsToPublish ' + caseEventsToPublish);
            List<Database.SaveResult> resultsCase = EventBus.publish(caseEventsToPublish);
            for(integer i=0; i<resultsCase.size(); i++){
                if(resultsCase[i].isSuccess()){
                    successfullpublishCase.add(caseEventsToPublish[i]);
                }
            }
            CaseBL.updateCaseWhenCaseEventSentSuccess(successfullpublishCase);
        }
        
        System.debug('newTaskList final === '+newTaskList);
        try{
            Database.insert(newTaskList);
        } catch(Exception e){
            errorHandler.createError(e);
        }
        
        //RPP-11090 - START
        try{
            if(childCasesToUpdate.size() > 0){
                System.debug('childCasesToUpdate === '+ childCasesToUpdate);
                Database.update(childCasesToUpdate, FALSE);
            }
            	
        }catch(Exception e){
            errorHandler.createError(e);
        }
        //RPP-11090 - END
        
        if(unlockCaseRecordIdSet.size() > 0 && unlockCaseRecordIdSet != null){
            try{
                List<Id> forUnlockCaseIdList=new List<Id>();
                forUnlockCaseIdList.addAll(unlockCaseRecordIdSet);
                System.debug('Case unlocked on line no. 609');
                Approval.unlock(forUnlockCaseIdList);
                System.debug('forUnlockCaseIdList === '+forUnlockCaseIdList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        //was commented out for 10532, added in beforeupdate (521-531)
        
        //for completed case that was unlocked because of setting the Case status to manual, the record should be locked
        system.debug('-----lockCompletedCaseRecordIdSet-----' + lockCompletedCaseRecordIdSet);
        if(lockCompletedCaseRecordIdSet.size() > 0 && lockCompletedCaseRecordIdSet != null){
            try{
                List<Id> forlockCaseIdList=new List<Id>();
                forlockCaseIdList.addAll(lockCompletedCaseRecordIdSet);
                System.debug('forlockCaseIdList === '+forlockCaseIdList);
                Approval.lock(forlockCaseIdList);
            }catch(Exception e){
                System.debug('Exception === '+e);
                errorHandler.createError(e);
            }
        }  
        
        //for updating child cases status with LV04 Bank Guarantee and LV18 Miscellaneous Lease Type
        if(childCaseList.size() > 0 && childCaseList != null){
            try{
                System.debug('childCaseList === '+childCaseList);
                Database.update(childCaseList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        //RPP - 4286 - Janus Gargoles - START - 06/18/2019
        if(oppListToUpdate.size() != 0 && oppListToUpdate != null){
            try{
                List<Database.SaveResult> srList = Database.update(oppListToUpdate,false);
                for(Integer i=0;i<oppListToUpdate.size();i++){
                    Database.SaveResult sr = srList[i];
                    Id failedRecordId = oppListToUpdate[i].Id;
                    if(!sr.isSuccess()){
                        errorHandler.createError(sr.getErrors()[0].getMessage(), String.valueOf(failedRecordId), String.valueOf(sr.getErrors()[0].getStatusCode()));
                    }
                }
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        if(spaceListToUpdate.size() != 0 && !spaceListToUpdate.isEmpty()){
            try{
                List<Database.SaveResult> srList = Database.update(spaceListToUpdate, false);
                for(Database.SaveResult sr : srList){
                    if(!sr.isSuccess()){
                        errorHandler.createError(sr, null);
                    }
                }
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        //RPP - 4286 - Janus Gargoles - END - 06/18/2019        
        errorHandler.save();
        
        if(caseTeamsToInsert.size() > 0)
            Database.insert(caseTeamsToInsert, FALSE);
    }
    
}