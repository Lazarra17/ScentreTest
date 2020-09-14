/**
*  @description : Helper class to publish all kind of platform events
*  @author      : pkumarlg 
*  @since       : 
*  @release     : 
**/
public class EventpublishHelper {
    public static Set<String> usernameorprofileSet;
    public static Map<Id,User> loggedinuserInfo;
    
    public EventpublishHelper(){
        
    }
    public class Eventpublishwrapper{
        public List<Sobject> eventsobjectList=new List<Sobject>();
        public List<Sobject> basesobjectList=new List<Sobject>();
    }
    
    /*******************************************************************
    *  @description : Method to publish opportunity platfrom event
    *******************************************************************/
    public static Eventpublishwrapper opportunityFieldChangePublishHelper(Map<Id,Sobject> oppoOldMap, Map<Id,Sobject> oppoNewMap, Map<Id, Opportunity> oppoMap) {
        Eventpublishwrapper oppoPublishWrapper=new Eventpublishwrapper();
        List<OpportunityEvent__e> oppoFieldChangeEventList = new List<OpportunityEvent__e>();
        Map<String,Set<String>> fieldSetandfieldAPInameOppo =SchemaDescribeBL.describefieldnamefromFS(Constants.OPPORTUNITY,Constants.OPPORTUNITY_INTEGRATION_FIELDSET);
        Map<String,Set<String>> objectandfieldAPIname=new Map<String,Set<String>>();
        objectandfieldAPIname = PlatformEventUtils.getfieldlistforintegration(Constants.OPPORTUNITY);
        List<Id> oppoIdsForPublish=new List<Id>();
        for(Sobject sobjectRecod: oppoMap.values()){
            Boolean ischanged=false;
            Opportunity oppoData = (Opportunity) sobjectRecod;
            if(oppoOldMap != null){
                Opportunity oldRecord=(Opportunity) oppoOldMap.get(oppoData.id);
                
                // iterate for each field from metadata
                for(String fieldapiname :fieldSetandfieldAPInameOppo.get(Constants.OPPORTUNITY_INTEGRATION_FIELDSET)){
                    if(oppoData.get(fieldapiname) != oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        oppoIdsForPublish.add(sobjectRecod.id);
                        oppoPublishWrapper.basesobjectList.add(sobjectRecod);
                        break;
                    }
                }
            }
        }
        List<String> fieldApiNameList=new List<String>();
        fieldApiNameList.addAll(objectandfieldAPIname.get(Constants.OPPORTUNITY));
        List<String> jsonPayloadOpportunity = new List<String>();
        if(oppoIdsForPublish.size()>0 && fieldapinamelist.size()>0){
            // note : reset fieldapinamelist to empty to get full dataset
            //System.debug('Get json payload ');
            //fieldapinamelist = new List<String>();
            jsonPayloadOpportunity = PlatformEventUtils.getRecordsJsonPayload(oppoIdsForPublish, fieldapinamelist);
        }
        //System.debug('jsonPayloadOpportunity ' + jsonPayloadOpportunity);
        if(jsonPayloadOpportunity.size()>0){
            oppoFieldChangeEventList = OpportunityBL.generateOppoEvents(jsonPayloadOpportunity);
        }
        oppoPublishWrapper.eventsobjectList.addAll((List<Sobject>) oppoFieldChangeEventList);
        return oppoPublishWrapper;
    }
    
    /*******************************************************************
    *  @description : Method to publish case platfrom event
    *******************************************************************/
    public static Eventpublishwrapper caseFieldChangePublishHelper(Map<Id,Sobject> caseOldMap, Map<Id,Sobject> caseNewMap, Map<Id, Case> caseMap) {
    	Eventpublishwrapper casePublishWrapper=new Eventpublishwrapper();
        List<CaseEvent__e> caseFieldChangeEventList = new List<CaseEvent__e>();
        Map<String,Set<String>> fieldSetandfieldAPInameCase = SchemaDescribeBL.describefieldnamefromFS(Constants.OBJECT_CASE, Constants.CASE_INTEGRATION_FIELDSET);
        Map<String,Set<String>> objectandfieldAPIname=new Map<String,Set<String>>();
        objectandfieldAPIname = PlatformEventUtils.getfieldlistforintegration(Constants.OBJECT_CASE);
        List<Id> caseIdsForPublish=new List<Id>();
        for(Sobject sobjectRecod: caseMap.values()){
            Boolean ischanged=false;
            Case caseData = (Case) sobjectRecod;
            if(caseOldMap != null){
                Case oldRecord = (Case) caseOldMap.get(caseData.id);
                
                // iterate for each field from metadata
                for(String fieldapiname :fieldSetandfieldAPInameCase.get(Constants.CASE_INTEGRATION_FIELDSET)){
                    if(caseData.get(fieldapiname) != oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        caseIdsForPublish.add(sobjectRecod.id);
                        casePublishWrapper.basesobjectList.add(sobjectRecod);
                        break;
                    }
                }
            } else {
                //System.debug('This is insert situation');
                // iterate for each field from metadata
                for(String fieldapiname :fieldSetandfieldAPInameCase.get(Constants.CASE_INTEGRATION_FIELDSET)){
                    if(caseData.get(fieldapiname) != null && caseData.get(fieldapiname) != ''){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        caseIdsForPublish.add(sobjectRecod.id);
                        casePublishWrapper.basesobjectList.add(sobjectRecod);
                        break;
                    }
                }
            }
        }
        // Create Map record Id to record type Id
        Map<Id, Id> recordIdToRecordTypeId = new Map<Id, Id>();
        for(Sobject sobjectRecod: caseMap.values()) {
            Case caseData = (Case) sobjectRecod;
            recordIdToRecordTypeId.put(caseData.Id, caseData.RecordTypeId);
        }
        List<String> fieldApiNameList = new List<String>();
        fieldApiNameList.addAll(objectandfieldAPIname.get(Constants.OBJECT_CASE));
        //List<String> jsonPayloadCase = new List<String>();
        Map<Id, String> recrdJson = new Map<Id, String>();
        if(caseIdsForPublish.size()>0 && fieldapinamelist.size()>0){
            // note : reset fieldapinamelist to empty to get full dataset
            //jsonPayloadCase = PlatformEventUtils.getRecordsJsonPayload(caseIdsForPublish, fieldapinamelist);
            recrdJson = PlatformEventUtils.getRecordsJsonPayloadMap(caseIdsForPublish, fieldapinamelist);
        }
        if(recrdJson.size()>0){
            //caseFieldChangeEventList = CaseBL.generateCaseEvents(jsonPayloadCase);
            caseFieldChangeEventList = CaseBL.generateCaseEventsByMap(recrdJson, recordIdToRecordTypeId);
        }
        casePublishWrapper.eventsobjectList.addAll((List<Sobject>) caseFieldChangeEventList);
        return casePublishWrapper;
    }
    
    /*******************************************************************
    *  @description : Method to publish Account Contact Relation platfrom event
    *******************************************************************/
    public static List<Id> acrFieldChangePublishHelper(Map<Id,Sobject> acrOldMap, Map<Id,Sobject> acrNewMap) {
        List<Id> validACRIds = new List<Id>();
        //Map<String, Set<String>> fieldSetandfieldAPIname = SchemaDescribeBL.describefieldnamefromFS(Constants.ACCOUNT_CONTACT_RELATION, Constants.SPACE_INTEGRATION_FIELDSET);
        Set<String> apiFieldSetForACR = new Set<String>();
        apiFieldSetForACR.add(Constants.ACR_ROLES);
        apiFieldSetForACR.add(Constants.ACR_ISACTIVE);
        for(Sobject sobjectRecod: acrNewMap.values()){
            Boolean ischanged=false;
            AccountContactRelation acrData = (AccountContactRelation) sobjectRecod;
            if(acrOldMap != null){
                AccountContactRelation oldRecord=(AccountContactRelation) acrOldMap.get(acrData.id);
                // iterate for each field from metadata
                for(String fieldapiname : apiFieldSetForACR){
                    if(acrData.get(fieldapiname) != oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        // if (acrData.IsActive && (acrData.Roles == Constants.ACC_CON_RELATION_BILLING || acrData.Roles == Constants.ACC_CON_RELATION_SALES)) {
                        //if (acrData.Roles == Constants.ACC_CON_RELATION_BILLING || acrData.Roles == Constants.ACC_CON_RELATION_SALES) {
                            validACRIds.add(sobjectRecod.id);    
                        //}
                        break;
                    }
                }
            } else {
                if (acrData.get(Constants.ACR_ROLES) != null || acrData.get(Constants.ACR_ISACTIVE) != null) {
                    validACRIds.add(sobjectRecod.id);  
                }
            }
        }
        // return valid contact Ids
        List<AccountContactRelation> acrs = [Select Id, ContactId, Contact.Status__c From AccountContactRelation Where Id in:validACRIds];
        List<Id> contactIds = new List<Id>();
        for (AccountContactRelation acr : acrs) {
            if (acr.ContactId != null && acr.Contact.Status__c != null && acr.Contact.Status__c == Constants.ACTIVE) {
                contactIds.add(acr.ContactId);
            }
        }
        return contactIds;
    }
    
    /*******************************************************************
    *  @description : Method to publish Contact platfrom event
    *******************************************************************/
    public static List<Id> contactFieldChangePublishHelper(Map<Id,Sobject> contactOldMap, Map<Id,Sobject> contactNewMap) {
        List<Id> activeContactIds = new List<Id>();
        Map<String, Set<String>> fieldSetandfieldAPInameContact = SchemaDescribeBL.describefieldnamefromFS(Constants.CONTACT, Constants.CONTACT_INTEGRATION_FIELDSET);
        for(Sobject sobjectRecod: contactNewMap.values()){
            Boolean ischanged=false;
            Contact contactData=(Contact) sobjectRecod;
            if(contactOldMap != null){
                Contact oldRecord=(Contact) contactOldMap.get(contactData.id);
                
                // iterate for each field from metadata
                for(String fieldapiname :fieldSetandfieldAPInameContact.get(Constants.CONTACT_INTEGRATION_FIELDSET)){
                    if(contactData.get(fieldapiname)!=oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        // Raoul recommend not to do this check
                        //if (contactData.Status__c == Constants.ACTIVE) {
                            activeContactIds.add(sobjectRecod.id);    
                        //}
                        break;
                    }
                }
            }
        }
        // return active contactIds
        return activeContactIds;
    }
    
    /*******************************************************************
    *  @description : Method to publish Task platfrom event
    *******************************************************************/
    public static Eventpublishwrapper taskFieldChangePublishHelper(Map<Id,Sobject> taskOldMap, Map<Id,Sobject> taskNewMap, Map<Id, Task> taskMap) {
        Eventpublishwrapper taskPublishWrapper = new Eventpublishwrapper();
        List<Id> activeTaskIds = new List<Id>();
        List<TaskEvent__e> taskFieldChangeEventList = new List<TaskEvent__e>();
        Map<String, Set<String>> fieldSetandfieldAPInameTask = SchemaDescribeBL.describefieldnamefromFS(Constants.TASK, Constants.TASK_INTEGRATION_FIELDSET);
        Map<String,Set<String>> objectandfieldAPIname=new Map<String,Set<String>>();
        objectandfieldAPIname = PlatformEventUtils.getfieldlistforintegration(Constants.TASK);
        for(Sobject sobjectRecod: taskNewMap.values()){
            Boolean ischanged=false;
            Task taskData=(Task) sobjectRecod;
            if(taskOldMap != null){
                Task oldRecord=(Task) taskOldMap.get(taskData.id);
                // iterate for each field from metadata
                for(String fieldapiname :fieldSetandfieldAPInameTask.get(Constants.TASK_INTEGRATION_FIELDSET)){
                    if(taskData.get(fieldapiname)!= oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged && taskMap.containsKey(sobjectRecod.Id)){
                        activeTaskIds.add(sobjectRecod.id);
                        break;
                    }
                }
            }
        }
        // check if they are fulfill the criteria
        List<String> fieldApiNameList=new List<String>();
        fieldApiNameList.addAll(objectandfieldAPIname.get(Constants.TASK));
        List<String> jsonPayloadTasks = new List<String>();
        if(activeTaskIds.size()>0 && fieldapinamelist.size()>0){
            // note : reset fieldapinamelist to empty to get full dataset
            //System.debug('Get json payload ');
            //fieldapinamelist = new List<String>();
            jsonPayloadTasks = PlatformEventUtils.getRecordsJsonPayload(activeTaskIds, fieldapinamelist);
        }
        //System.debug('jsonPayloadOpportunity ' + jsonPayloadOpportunity);
        if(jsonPayloadTasks.size()>0){
            taskFieldChangeEventList = TaskBL.generateTaskEvents(jsonPayloadTasks);
        }
        taskPublishWrapper.eventsobjectList.addAll((List<Sobject>) taskFieldChangeEventList);
        return taskPublishWrapper;
    }
    
    /*******************************************************************
    *  @description : Method to publish Account platfrom event
    *******************************************************************/
    public static Eventpublishwrapper accountFieldChangePublishHelper(Map<Id,Sobject> accountOldMap,Map<Id,Sobject> accountNewMap,Map<Id, Account> dbAccountDataMap) {
        Eventpublishwrapper accountPublishWrapper=new Eventpublishwrapper();
        List<AccountEvent__e> accountFieldChangeEventList = new List<AccountEvent__e>();
        Map<String,Set<String>> fieldSetandfieldAPInameAccount =SchemaDescribeBL.describefieldnamefromFS(Constants.ACCOUNT,Constants.ACCOUNT_INTEGRATION_FIELDSET);
        Map<String,Set<String>> objectandfieldAPIname=new Map<String,Set<String>>();
        objectandfieldAPIname = PlatformEventUtils.getfieldlistforintegration(Constants.ACCOUNT);
        List<Id> accountIdsForPublish=new List<Id>();
        for(Sobject sobjectRecod: dbAccountDataMap.values()){
            Boolean ischanged=false;
            Account accountData=(Account)sobjectRecod;
            if(accountOldMap != null){
                Account oldRecord=(Account) accountOldMap.get(accountData.id);
                
                // iterate for each field from metadata
                for(String fieldapiname :fieldSetandfieldAPInameAccount.get(Constants.ACCOUNT_INTEGRATION_FIELDSET)){
                    if(accountData.get(fieldapiname)!=oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        //System.debug('ischanged is true');
                        accountIdsForPublish.add(sobjectRecod.id);
                        accountPublishWrapper.basesobjectList.add(sobjectRecod);
                        break;
                    }
                }
            }
        }
        List<String> fieldApiNameList=new List<String>();
        fieldApiNameList.addAll(objectandfieldAPIname.get(Constants.ACCOUNT));
        List<String> jsonPayloadAccount=new List<String>();
        
        if(accountIdsForPublish.size()>0 && fieldapinamelist.size()>0){
            jsonPayloadAccount=PlatformEventUtils.getRecordsJsonPayload(accountIdsForPublish,fieldapinamelist);
        }
        //System.debug('jsonPayloadAccount ' + jsonPayloadAccount);
        if(jsonPayloadAccount.size()>0){
            accountFieldChangeEventList = AccountBL.generateAccountEvents(jsonPayloadAccount);
        }
        //System.debug('accountFieldChangeEventList ' + accountFieldChangeEventList);
        accountPublishWrapper.eventsobjectList.addAll((List<Sobject>) accountFieldChangeEventList);
        return accountPublishWrapper;
    }
    /*******************************************************************
    *  @description : Method to publish Space platfrom event
    *******************************************************************/
    public static Eventpublishwrapper SpacefieldChangepublishHelper(Map<Id,Sobject> spaceoldMap,Map<Id,Sobject> spacenewMap,Map<Id,Space__c> dbSpacedataMap){
        List<SpaceEvent__e>  spacefieldchangeEvenList=new List<SpaceEvent__e>();
        Map<String,Set<String>> fieldSetandfieldAPInameSpace = new Map<String,Set<String>>();
        fieldSetandfieldAPInameSpace =SchemaDescribeBL.describefieldnamefromFS(Constants.SPACE, Constants.SPACE_INTEGRATION_FIELDSET);
        //System.debug('fieldSetandfieldAPIname ' + fieldSetandfieldAPInameSpace);
        Map<String,Set<String>> objectandfieldAPIname=new Map<String,Set<String>>();
        objectandfieldAPIname=PlatformEventUtils.getfieldlistforintegration(Constants.SPACE);
        List<Id> spaceidsforpublish=new List<Id>();
        Eventpublishwrapper spacepublishwrapper=new Eventpublishwrapper(); 
        // check for field changes from metadata list for each recod.
        for(Sobject sobjectRecod: spacenewMap.values()){
            Boolean ischanged=false;
            Space__c spacedata=(Space__c)sobjectRecod;
            if(spaceoldMap!=null){
                Space__c oldRecord=(Space__c)spaceoldMap.get(spacedata.id);
                
                // iterate for each field from metadata
                //System.debug('fieldSetandfieldAPIname2 ' + fieldSetandfieldAPInameSpace.get(Constants.SPACE_INTEGRATION_FIELDSET));
                for(String fieldapiname :fieldSetandfieldAPInameSpace.get(Constants.SPACE_INTEGRATION_FIELDSET)){
                    if(spacedata.get(fieldapiname)!=oldRecord.get(fieldapiname)){
                        ischanged=true;
                    }
                    // for change any one field from the list breaka and go for next record.
                    if(ischanged){
                        spaceidsforpublish.add(sobjectRecod.id);
                        spacepublishwrapper.basesobjectList.add(sobjectRecod);
                        break;
                    }
                }
            }
        }
        
        List<String> fieldapinamelist=new List<String>();
        fieldapinamelist.addAll(objectandfieldAPIname.get(Constants.SPACE));
        List<String> jsonPayloadSpace=new List<String>();
        
        if(spaceidsforpublish.size()>0&&spaceidsforpublish!=null && fieldapinamelist.size()>0&&fieldapinamelist!=null){
            jsonPayloadSpace=PlatformEventUtils.getRecordsJsonPayload(spaceidsforpublish,fieldapinamelist);
        }
        if(jsonPayloadSpace.size()>0&&jsonPayloadSpace!=null){
            spacefieldchangeEvenList = SpaceBL.generateSpaceEvents(jsonPayloadSpace);
        }
        spacepublishwrapper.eventsobjectList.addAll((List<Sobject>)spacefieldchangeEvenList);
        return  spacepublishwrapper;
    }
    
    /*******************************************************************
*  @description : Method to Check if the publish logic should be bypassed for user or not
*******************************************************************/
    public static Boolean isValidpublish(){
        Boolean validuser=true;
        
        if(usernameorprofileSet==null||usernameorprofileSet.size()==0){
            usernameorprofileSet=new Set<String>();
        }
        if(loggedinuserInfo==null||loggedinuserInfo.size()==0){
            loggedinuserInfo=new Map<Id,User>();
        }
        
        // do query only if the map variable is null -  STATIC DATA
        if(usernameorprofileSet==null&&usernameorprofileSet.size()==0){
            for(BypassPublishPlatformEvent__mdt bypassmetadataRecord: [Select Id,DeveloperName,EntityType__c,EntityTypeName__c from BypassPublishPlatformEvent__mdt]){
                usernameorprofileSet.add(bypassmetadataRecord.EntityTypeName__c);
            }
        }
        
        // do query only if the variable is null -  STATIC DATA
        if(loggedinuserInfo==null){
            loggedinuserInfo=new Map<Id,User>([Select Id,ProfileId,Profile.Name,Email,UserName from User where Id=:UserInfo.getUserId()]);
        }
        if(usernameorprofileSet!=null&&usernameorprofileSet.size()>0&&loggedinuserInfo.size()>0&&loggedinuserInfo!=null&&loggedinuserInfo.get(UserInfo.getUserId())!=null){
            if(usernameorprofileSet.contains(UserInfo.getUserName())||usernameorprofileSet.contains(loggedinuserInfo.get(UserInfo.getUserId()).Profile.name)){
                validuser=false;
            }
        }
        return validuser;
    } 
}