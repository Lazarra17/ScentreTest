/**
* Class AccountHandler
*
* Trigger Handler for the Account SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*
*
*/
public without sharing class AccountTriggerHandler extends TriggerHandler
implements ITrigger {
    
    List<AccountEvent__e> accountEventsToPublish = new List<AccountEvent__e>();    
    private Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = new Map<String, Schema.RecordTypeInfo>();
    private Map<String, Schema.RecordTypeInfo> accountRecordTypeMapBydeveloperName = new Map<String, Schema.RecordTypeInfo>();
    private Map<Id, Property__c> propertyMap = new Map<Id, Property__c>();
    private Map<Id, Account> parentaccountMap = new Map<Id, Account>();
    private Profile profileName = new Profile();
    private Map<Id, Account> idVsAccountMap = new Map<Id, Account>();
    // Constructor
    public AccountTriggerHandler()
    {
        
    }
    
    /**
* bulkBefore
*
* This method is called prior to execution of a BEFORE trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    public void bulkBefore()
    {
        Set<Id> accountIdSet = new Set<Id>();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(AccountTriggerHandler.class.getName());
        if(Trigger.isInsert || Trigger.isUpdate) {
            
            List<Account> newAccountList = (List<Account>) Trigger.new;
            Set<Id> newAccountIds = new Set<Id>();
            for(Account acc : newAccountList){
                newAccountIds.add(acc.Id);
            }

            idVsAccountMap = new Map<Id, Account>([Select Id, Name, 
                                            (Select Id, Name, RecordType.Name, StageName 
                                                From Opportunities 
                                                Where ((RecordType.Name =: Constants.OPP_COMMERCIAL_LEASING OR 
                                                RecordType.Name =: Constants.OPP_RETAIL_LEASING) AND 
                                                StageName !=: Constants.OPPTY_STAGENAME_CLOSED) OR 
                                                (RecordType.Name =: Constants.OPP_STORE_ROOM_LEASING)), 
                                            (Select Id, RecordType.Name, LeaseStatus__c 
                                                From Contracts1__r 
                                                Where (RecordType.Name =: Constants.CON_COMMERCIAL_CONTRACT OR 
                                                RecordType.Name =: Constants.CON_RETAIL_CONTRACT) AND 
                                                LeaseStatus__c !=: Constants.CON_EXPIRED_STATUS) 
                                            FROM Account 
                                            Where Id IN :newAccountIds]);

            profileName = DatabaseSOQLBank.getProfile(userinfo.getProfileId());
                    
            // START -- RPP-2126 Kyle Tan 4/20/18
            Account accountTemp = new Account();
            Set<Id> propertyIdSet = new Set<Id>();
            Set<Id> parentAccountIdSet = new Set<Id>();  
            //accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
            accountRecordTypeMapBydeveloperName= RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.ACCOUNT);
            for(SObject accountSObject : Trigger.new) {
                accountTemp = (Account) accountSObject;
                propertyIdSet.add(accountTemp.Property__c);
                parentAccountIdSet.add(accountTemp.ParentId);
            }
            
            if(!propertyIdSet.isEmpty()) {
                try{
                    propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet));
                    parentaccountMap=new Map<Id, Account>(DatabaseSOQLBank.getAccountById(parentAccountIdSet));
                }catch(Exception e) {
                    errorHandler.createError(e);
                }
            }
            errorHandler.save();
            // END -- RPP-2126
        }
        
        if(Trigger.isInsert) {
            
        }
        
        if(Trigger.isUpdate) {
            
        }
        
    }
    
    public void bulkAfter()
    {
        
        if(Trigger.isInsert || Trigger.isUpdate) {
            
        }
        
        if(Trigger.isInsert) {
            
        }
        
        if(Trigger.isUpdate) {
            Map<Id, Account> dbAccountDataMapToPublish = AccountBL.accountEventTriggerCriteriaCheck(Trigger.newmap);
            EventpublishHelper.Eventpublishwrapper accountWrapper = new EventpublishHelper.Eventpublishwrapper();
            if(EventpublishHelper.isValidpublish() && dbAccountDataMapToPublish!=null && dbAccountDataMapToPublish.size()>0){
                accountWrapper = EventpublishHelper.accountFieldChangePublishHelper(Trigger.oldMap, Trigger.newMap, dbAccountDataMapToPublish);
                accountEventsToPublish.addAll((List<AccountEvent__e>) accountWrapper.eventsobjectList);
            }
        } 
        
    }
    
    public void beforeInsert(SObject so)
    {
        
        // START -- RPP-2126 Kyle Tan 4/20/18
        Account newAccountRecord = (Account) so;
        
        // START -- RPP-1609 Yana Navarro 4.30.2018
        if(newAccountRecord.TechConvertedLeadId__c != null){
            AccountBL.copyBillingToShippingAddress(newAccountRecord);
        }
        // END -- RPP-1609
        
        if(newAccountRecord.RecordTypeId == accountRecordTypeMapBydeveloperName.get(CONSTANTS.PROPERTY_BASED_APINAME).getRecordTypeId()) {
            if(propertyMap.get(newAccountRecord.Property__c) != null) {
                AccountBL.renameAccount(newAccountRecord, propertyMap.get(newAccountRecord.Property__c).PropertyShortName__c);
            }
        }
        // END -- RPP-2126
        // Default Account details from group parent account
        if(String.IsNotBlank(newAccountRecord.ParentID)&&parentaccountMap.containskey(newAccountRecord.ParentID)){
            if(parentaccountMap.get(newAccountRecord.ParentID).RecordType.DeveloperName==Constants.GROUP_LEVEL_APINAME){
                if(String.isBlank(newAccountRecord.Category__c)){
                    newAccountRecord.Category__c=parentaccountMap.get(newAccountRecord.ParentID).Category__c;
                    newAccountRecord.SuperfineCategory__c=parentaccountMap.get(newAccountRecord.ParentID).SuperfineCategory__c;
                }
                if(String.IsBlank(newAccountRecord.BillingState)){
                    newAccountRecord.BillingState=parentaccountMap.get(newAccountRecord.ParentID).BillingState;
                }
                if(String.IsBlank(newAccountRecord.BillingCountry)){
                    newAccountRecord.BillingCountry=parentaccountMap.get(newAccountRecord.ParentID).BillingCountry;
                }
                if(String.IsBlank(newAccountRecord.ShippingState)){
                    newAccountRecord.ShippingState=parentaccountMap.get(newAccountRecord.ParentID).ShippingState;
                }
                if(String.IsBlank(newAccountRecord.ShippingCountry)){
                    newAccountRecord.ShippingCountry=parentaccountMap.get(newAccountRecord.ParentID).ShippingCountry;
                } 
            }
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
        system.debug('--in BeforeUpdate--');
        // START -- RPP-2126 Kyle Tan 4/20/18
        Account newAccountRecord = (Account) so;
        Account oldAccountRecord = (Account) oldSo;
        
        if(newAccountRecord.RecordTypeId == accountRecordTypeMapBydeveloperName.get(CONSTANTS.PROPERTY_BASED_APINAME).getRecordTypeId()) {
            if((String.isNotBlank(newAccountRecord.TradingName__c) && !newAccountRecord.TradingName__c.equalsIgnoreCase(oldAccountRecord.TradingName__c)) || newAccountRecord.Property__c != oldAccountRecord.Property__c || (String.isNotBlank(newAccountRecord.Name) && !newAccountRecord.Name.equalsIgnoreCase(oldAccountRecord.Name)) ) {
                if(propertyMap.containsKey(newAccountRecord.Property__c)){
                    AccountBL.renameAccount(newAccountRecord, propertyMap.get(newAccountRecord.Property__c).PropertyShortName__c);
                }  
            }
        }
        // END -- RPP-2126
        
        // START -- RPP-9986 Arxxus 04/06/19
        
        //Profile profileName = DatabaseSOQLBank.getProfile(userinfo.getProfileId());
        if(idVsAccountMap.containsKey(newAccountRecord.Id)){
            if(profileName.Name == Constants.SCGRETAILCENTREMGT){
                if(newAccountRecord.BillingCountry != oldAccountRecord.BillingCountry || newAccountRecord.BillingStreet != oldAccountRecord.BillingStreet || 
                   newAccountRecord.BillingCity != oldAccountRecord.BillingCity || newAccountRecord.BillingState != oldAccountRecord.BillingState || 
                   newAccountRecord.BillingPostalCode != oldAccountRecord.BillingPostalCode){
                       Boolean showError = false;
                       Boolean allowUpdate = false;
                       Boolean throwError = false;
                       Account accWithOppsContracts = idVsAccountMap.get(newAccountRecord.Id);

                       if(accWithOppsContracts.Contracts1__r.size() > 0){
                           Trigger.newMap.get(newAccountRecord.Id).addError('Please contact Property Retail Admin to update Billing Address');
                       }
                       if(accWithOppsContracts.Opportunities.size() > 0){
                           for(Opportunity opp : accWithOppsContracts.Opportunities){
                               if((opp.RecordType.Name == Constants.OPP_COMMERCIAL_LEASING || opp.RecordType.Name == Constants.OPP_RETAIL_LEASING) && opp.StageName != Constants.OPPTY_STAGENAME_CLOSED){
                                  showError = True; 
                               }else if(opp.RecordType.Name == Constants.OPP_STORE_ROOM_LEASING && opp.StageName == Constants.OPPTY_UNDERSTAND_NEGOTIATE){
                                   allowUpdate = True;
                               }else if(opp.RecordType.Name == Constants.OPP_STORE_ROOM_LEASING && opp.StageName != Constants.OPPTY_UNDERSTAND_NEGOTIATE){
                                   throwError = True;
                               }
                           }
                       }
                       if(showError){
                           Trigger.newMap.get(newAccountRecord.Id).addError('Please contact Property Retail Admin to update Billing Address');                            
                       }else if(!allowUpdate){
                           if(throwError){
                             Trigger.newMap.get(newAccountRecord.Id).addError('Please contact Property Retail Admin to update Billing Address');                            
                            }
                       }
                   }          
            } 
        }
        
        // END -- RPP-9986

    }
    
    /**
* beforeDelete
*
* This method is called iteratively for each record to be deleted during a BEFORE
* trigger.
*/
    
    public void beforeDelete(SObject so)
    {
        
    }
    
    public void afterInsert(SObject so)
    {
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    /**
* andFinally
*
* This method is called once all records have been processed by the trigger. Use this
* method to accomplish any final operations such as creation or updates of other records.
*/
    
    public void andFinally()
    {
        List<AccountEvent__e> successfullpublishAccount=new List<AccountEvent__e>();
        if (accountEventsToPublish.size() > 0) {
            List<Database.SaveResult> resultsAccount = EventBus.publish(accountEventsToPublish);
            for(integer i=0; i<resultsAccount.size(); i++){
                if(resultsAccount[i].isSuccess()){
                    successfullpublishAccount.add(accountEventsToPublish[i]);
                }
            }
            AccountBL.updateAccountWhenAccountEventSentSuccess(successfullpublishAccount);
        }
    }
}