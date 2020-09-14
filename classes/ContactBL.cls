public class ContactBL {
    public class ContactWithFinalizedOppoWrapper {
        public boolean sendEvent {get; set;}
        public Set<Id> contacts {get; set;}
        public List<Id> accountContactRelations {get; set;}
        public Map<Id, List<Id>> contactToACRMap {get; set;}
    }
    
    public class ACRWrapper {
        public Id ID {get; set;}
        public String STARTDATE {get; set;}
        public String ACCOUNTNUMBER {get; set;}
        public String ROLES {get; set;}
        public Boolean ISACTIVE {get; set;}
        public Id ACCOUNTID {get; set;}
        public Id CONTACTID {get; set;}
    }
    
    private static List<ACRWrapper> convertACRByRoles (Map<String,Object> acrDeJson) {
        List<ACRWrapper> jsonReadyACRs = new List<ACRWrapper>();
        if (acrDeJson.get('ROLES') != null) {
            String[] tmpStrings = String.valueOf(acrDeJson.get('ROLES')).split(';');
            for (String tmpString : tmpStrings) {
                ContactBL.ACRWrapper acrWrapper = new ContactBL.ACRWrapper();
                acrWrapper.ID = String.valueOf(acrDeJson.get('ID')) != null ? String.valueOf(acrDeJson.get('ID')) : '';
                acrWrapper.STARTDATE = String.valueOf(acrDeJson.get('STARTDATE')) != null ? String.valueOf(acrDeJson.get('STARTDATE')) : '';
                acrWrapper.ACCOUNTNUMBER = String.valueOf(acrDeJson.get('ACCOUNT.ACCOUNTNUMBER__C')) != null ? String.valueOf(acrDeJson.get('ACCOUNT.ACCOUNTNUMBER__C')) : '';
                acrWrapper.ROLES = tmpString != null ? tmpString : '';
                acrWrapper.ISACTIVE = Boolean.valueOf(acrDeJson.get('ISACTIVE')) ? TRUE : FALSE;
                acrWrapper.ACCOUNTID = String.valueOf(acrDeJson.get('ACCOUNTID')) != null ? String.valueOf(acrDeJson.get('ACCOUNTID')) : '';
                acrWrapper.CONTACTID = String.valueOf(acrDeJson.get('CONTACTID')) != null ? String.valueOf(acrDeJson.get('CONTACTID')) : '';
                jsonReadyACRs.add(acrWrapper);
            }
        } else {
            
        }
        return jsonReadyACRs;
    }
    /*
    * Author : chen chen
    * Parameter : contactIds - List of contact ids 
    * Description : Using id to find an active Contact that has a AccountContactRelationship.Role of "Billing Contact" or "Sales Turnover Contact" with an "active" AccountContactRelationship for an Account associated to a finalised Opportunity
    */ 
    public static ContactWithFinalizedOppoWrapper constructBaseStructureFromContact (List<Id> contactIds) {
        ContactWithFinalizedOppoWrapper contactWrapper = new ContactWithFinalizedOppoWrapper();
        contactWrapper.sendEvent = false;
        contactWrapper.contacts = new Set<Id>();
        contactWrapper.accountContactRelations  = new List<Id>();
        contactWrapper.contactToACRMap = new Map<Id, List<Id>>();
        List<String> roles = new List<String>();
        roles.add(Constants.ACC_CON_RELATION_BILLING);
        roles.add(Constants.ACC_CON_RELATION_SALES);
        List<Id> acrIds = new List<Id>();
        Set<Id> contactEventIds = new Set<Id>();
        if (contactIds.size() > 0) {
            //List<AccountContactRelation> accountContactRelations = [Select Id, ContactId, AccountId, Account.Status__c From AccountContactRelation Where contactId in: contactIds And Roles in :roles];
            List<AccountContactRelation> accountContactRelations = [Select Id, ContactId, AccountId, Account.Status__c From AccountContactRelation Where contactId in: contactIds];
            
            // Collect active accounts, if none, break
            List<Id> activeAccountIds = new List<Id>();
            Map<Id, List<Id>> contactToACR = new Map<Id, List<Id>>();
            for (AccountContactRelation accountContactRelation : accountContactRelations) {
                System.debug(accountContactRelation.AccountId);
                //if (accountContactRelation.AccountId != Null && accountContactRelation.Account.Status__c == Constants.ACTIVE) {
                if (accountContactRelation.AccountId != Null) {
                    activeAccountIds.add(accountContactRelation.AccountId);           
                }
            }
            if (activeAccountIds.size() > 0) {
                List<Account> tenantAccounts = [Select Id from Account where Id in :activeAccountIds and TenantNo__c != ''];
                //List<Opportunity> oppos = [Select Id, accountId From Opportunity Where accountId in :activeAccountIds And JDESentStatus__c != ''];
                if (tenantAccounts.size() > 0) {
                    List<Id> accountIds = new List<Id>();
                    for (Account acc : tenantAccounts) {
                        accountIds.add(acc.Id);
                    }
                    //List<AccountContactRelation> acrs = [Select Id, ContactId, AccountId From AccountContactRelation Where AccountId in: accountIds And ContactId in: contactIds And Roles in :roles];
                    List<AccountContactRelation> acrs = [Select Id, ContactId, AccountId From AccountContactRelation Where AccountId in: accountIds And ContactId in: contactIds];
                    for (AccountContactRelation acr : acrs) {
                        acrIds.add(acr.Id);
                        contactEventIds.add(acr.ContactId);
                        if (contactToACR.get(acr.ContactId) != null) {
                            contactToACR.get(acr.ContactId).add(acr.Id);
                        } else {
                            List<Id> mapACR = new List<Id>();
                            mapACR.add(acr.Id);
                            contactToACR.put(acr.ContactId, mapACR);
                        }
                    }
                    contactWrapper.sendEvent = true;
                    contactWrapper.contacts = contactEventIds;
                    contactWrapper.contactToACRMap = contactToACR;
                    contactWrapper.accountContactRelations = acrIds;
                }
            }
        }
        //System.debug(contactWrapper);
        return contactWrapper;
    }
    
    /*
    * Author : chen chen
    * Parameter : ContactWithFinalizedOppoWrapper event wrapper for contact & ACR
    * Description : Generate Address book events from wrapper info
    */
    public static List<AccountContactEvent__e> constructPE(ContactWithFinalizedOppoWrapper contactWithFinalizedOppoWrapper) {
        List<AccountContactEvent__e> acEvents = new List<AccountContactEvent__e>(); 
        List<String> objectApiNames = new List<String>();
        objectAPiNames.add(Constants.OBJECT_ACR);
        objectAPiNames.add(Constants.OBJECT_CONTACT);
        List<PlatformEventPayloadSelection__mdt > payloadSelections = [SELECT ObjectApiName__c, Content__c FROM PlatformEventPayloadSelection__mdt WHERE ObjectApiName__c in: objectApiNames];
        List<String> contactApiNames = new List<String>();
        List<String> acrApiNames = new List<String>();
        for (PlatformEventPayloadSelection__mdt payloadSelection : payloadSelections) {
            String content = payloadSelection.Content__c;
            List<String> splitString = content.split(',');
            if (payloadSelection.ObjectApiName__c == Constants.OBJECT_ACR) {
                for (String apiName : splitString) {
                    apiName = apiName.trim();
                    acrApiNames.add(apiName);
                }
            } else {
                for (String apiName : splitString) {
                    apiName = apiName.trim();
                    contactApiNames.add(apiName);
                }
            }
        }
        // Json Payload For Contact
        List<Id> contactIds = new List<Id>();
        contactIds.addall(contactWithFinalizedOppoWrapper.contacts);
        Map<Id, String> contactPayloads = PlatformEventUtils.getRecordsJsonPayloadMap(contactIds, contactApiNames);
        // Json Payload for AccountContactRelation
        Map<Id, String> acrPayloads = PlatformEventUtils.getRecordsJsonPayloadMap(contactWithFinalizedOppoWrapper.accountContactRelations, acrApiNames);
        // run through the map to construct the platform event
        for (Id contactId: contactWithFinalizedOppoWrapper.contactToACRMap.keySet()){
            //String contactPayload = contactPayloads.get(contactId);
            List<Id> acrIds = contactWithFinalizedOppoWrapper.contactToACRMap.get(contactId);
            String[] acrPayloadArray = new String[acrIds.size()];
            List<ACRWrapper> jsonReadyACRs = new List<ACRWrapper>();
            for (Integer i = 0; i < acrIds.size(); i++) {
                Map<String, Object> acrDeJson;
                List<ACRWrapper> convertACRByRoles;
                acrPayloadArray[i] =  acrPayloads.get(acrIds.get(i));
                try {
                	acrDeJson = (Map<String, Object>) JSON.deserializeUntyped(acrPayloads.get(acrIds.get(i)));    
                } catch (Exception e) {
                    acrDeJson = NULL;
                }
                
                if (acrDeJson!=NULL & !acrDeJson.isEmpty()) {
                    convertACRByRoles = convertACRByRoles(acrDeJson);
                    jsonReadyACRs.addAll(convertACRByRoles);
                }
            }
            // Convert ACR
            AccountContactEvent__e acEvent = new AccountContactEvent__e();
            try {
                acEvent.ACRPayload__c = JSON.serialize(jsonReadyACRs);
            } catch (Exception e) {
                acEvent.ACRPayload__c = NULL;
            }
            
            if (acEvent.ACRPayload__c != NULL && acEvent.ACRPayload__c != '') {
                acEvent.ContactPayload__c = contactPayloads.get(contactId);
                acEvents.add(acEvent);
            }
        }
        return acEvents;
    }
    
    /**
    * @Author: Chen Chen
    * @Para: List<AccountContactEvent__e> successfullpublish, List of successfully sent address book events
    * @Desc: This is used for updating contact platform events by the successfully sent address book events
    */
    public static void updateContactWhenAddressBookEventSentSuccess(List<AccountContactEvent__e> successFullPublish) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityTriggerHandler.class.getName());
        List<Contact> contactToUpdateDispatchDetailsList=new List<Contact>(); 
        if(successFullPublish.size() > 0){
            for(AccountContactEvent__e publishedEvent: successFullPublish){
                // get values from pubished event payload to update parent records
                Map<String, Object> publishedContactEvents;
                try {
                    publishedContactEvents=(Map<String, Object>)JSON.deserializeUntyped(publishedEvent.ContactPayload__c);
                } catch (Exception e) {
                    publishedContactEvents = NULL;
                }
                
                if (publishedContactEvents != NULL && !publishedContactEvents.isEmpty()) {
                    Contact contactToUpdateDispatchDetails=new Contact();
                    contactToUpdateDispatchDetails.id = (id)publishedContactEvents.get(Constants.DML_ID.toUpperCase());
                    String dispatchTimeStampStr = (String)publishedContactEvents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                    contactToUpdateDispatchDetails.TechDispatchedTimeStamp__c = DateTime.valueOf(dispatchTimeStampStr);
                    String dispatchVersionStr = (String)publishedContactEvents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                    contactToUpdateDispatchDetails.TechDispatchedVersion__c = Decimal.valueOf(dispatchVersionStr);
                    contactToUpdateDispatchDetailsList.add(contactToUpdateDispatchDetails);
                }
            }
        }
        if(contactToUpdateDispatchDetailsList.size()>0){
            try {
                Database.update(contactToUpdateDispatchDetailsList);
            } catch (Exception e) {
                errorHandler.createError(e);
            }
            
        }
        errorHandler.save();
    }
}