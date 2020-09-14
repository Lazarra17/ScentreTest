public class AccountBL {
    
    /*
     *  @author: 		Kyle Tan
     *	@parameters:	accountRecord 		- account record to be updated
	 *					propertyShortName 	- short name to add to the account name
     *  @description:	This method updates the Account Records Name
     */
    public static Account renameAccount (Account accountRecord, String propertyShortName) {
        if(String.isNotBlank(propertyShortName)) {
            accountRecord.Name = accountRecord.TradingName__c + CONSTANTS.DASH + propertyShortName;
        } else {
            accountRecord.Name = accountRecord.TradingName__c;
        }
        
        return accountRecord;
    }

    /*
     *  @author:         Yana Navarro
     *  @parameters:     account - account record to be updated
     *  @description:    This method copy the Account BillingAddress to ShippingAddress
     */
    public static Account copyBillingToShippingAddress(Account account){
        account.ShippingCity = account.BillingCity;
        account.ShippingStreet = account.BillingStreet;
        account.ShippingStateCode = account.BillingStateCode;
        account.ShippingPostalCode = account.BillingPostalCode;
        account.ShippingCountryCode = account.BillingCountryCode;
        account.TradingName__c = account.name;

        return account;
    }
    
    /**
    * @Author: Chen Chen
    * @Para: List<String> jsonPayloads, List of json payload that need to send out as space event
    * @Desc: This is used for generating account platform events by the providing payloads
    */ 
    public static List<AccountEvent__e> generateAccountEvents(List<String> payloads) {
        List<AccountEvent__e> accountEvents = new List<AccountEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                AccountEvent__e accountE = new AccountEvent__e();
                accountE.JSONPayload__c = payload;
                accountEvents.add(accountE);
            }
        }
        return accountEvents;
    }
    /**
    * @Author: Chen Chen
    * @Para: List<String> jsonPayloads, List of json payload that need to send out as space event
    * @Desc: This is used for generating account platform events by the providing payloads
    */
    public static Map<Id, Account> accountEventTriggerCriteriaCheck(Map<Id,Sobject> accountNewMap) {
        Map<Id, Account> dbAccountDataMapToPublish = new Map<Id, Account>();
        if (accountNewMap.size() > 0) {
            Map<Id, Id> childToParentIdMap = new Map<Id, Id>();
            Set<Id> queryAccountIdSet = new Set<Id>();
            Set<Id> accountIds = accountNewMap.keySet();
            queryAccountIdSet.addAll(accountIds);
            // Construct from here for account hierarchy
            List<Account> firstLevelCheck = [Select Id, ParentId From Account Where ParentId in: accountIds];
            if (firstLevelCheck.size() > 0) {
            	for (Account acc : firstLevelCheck) {
                    queryAccountIdSet.add(acc.Id);
                    childToParentIdMap.put(acc.Id, acc.ParentId);
                }   
            }
            List<Account> secondLevelCheck = [Select Id, ParentId From Account Where ParentId in: firstLevelCheck];
            if (secondLevelCheck.size() > 0) {
            	for (Account acc : secondLevelCheck) {
                    queryAccountIdSet.add(acc.Id);
                    childToParentIdMap.put(acc.Id, acc.ParentId);
                }   
            }
            System.debug('queryAccountIdSet ' + queryAccountIdSet);
            Set<Id> availableIds = DatabaseSOQLBank.getOpportunityByAccountIdAndStageName(queryAccountIdSet);
            System.debug('availableIds ' + availableIds);
            for (Id id : availableIds) {
                if (accountNewMap.get(id ) != null) {
                    System.debug('base level reached');
                    dbAccountDataMapToPublish.put(id, (Account) accountNewMap.get(id));
                } else {
                    // second level check
                    if (childToParentIdMap.get(id) != null ) {
                        if (accountNewMap.get(childToParentIdMap.get(id)) != null) {
                            //add to the map
                            System.debug('second level reached');
                            if (dbAccountDataMapToPublish.get(childToParentIdMap.get(id)) == null) {
                                System.debug('second level reached no map' + childToParentIdMap.get(id));
                                dbAccountDataMapToPublish.put(childToParentIdMap.get(id), (Account) accountNewMap.get(childToParentIdMap.get(id)));
                            }
                        } else {
                            // first level check
                            if (childToParentIdMap.get(childToParentIdMap.get(id)) != null) {
                                if (accountNewMap.get(childToParentIdMap.get(childToParentIdMap.get(id))) != null) {
                                    System.debug('first level reached');
                                    if (dbAccountDataMapToPublish.get(childToParentIdMap.get(childToParentIdMap.get(id))) == null) {
                                        System.debug('first level reached no map' + childToParentIdMap.get(childToParentIdMap.get(id)));
                                    	dbAccountDataMapToPublish.put(childToParentIdMap.get(childToParentIdMap.get(id)), (Account) accountNewMap.get(childToParentIdMap.get(childToParentIdMap.get(id))));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        System.debug('dbAccountDataMapToPublish ' + dbAccountDataMapToPublish);
        return dbAccountDataMapToPublish;
    }
    /*
    * @Author: Chen Chen
    * @Para: List<AccountEvent__e> successfullpublish, List of successfully sent account events
    * @Desc: This is used for updating account platform events by the successfully sent account events
    */
    public static void updateAccountWhenAccountEventSentSuccess(List<AccountEvent__e> successFullPublish) {
        List<Account> accountToUpdateDispatchDetailsList=new List<Account>(); 
        if(successFullPublish.size() > 0){
            for(AccountEvent__e publishedEvent: successFullPublish){
                // get values from pubished event payload to update parent records
                Map<String, Object> publishedAccountEvents;
                try {
                    publishedAccountEvents=(Map<String, Object>)JSON.deserializeUntyped(publishedEvent.JSONPayload__c);
                } catch (Exception e) {
                    publishedAccountEvents = NULL;
                }
                
                if (publishedAccountEvents != NULL && !publishedAccountEvents.isEmpty()) {
                    Account acountToUpdateDispatchDetails=new Account();
                    acountToUpdateDispatchDetails.id = (id)publishedAccountEvents.get(Constants.DML_ID.toUpperCase());
                    String dispatchTimeStampStr = (String)publishedAccountEvents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                    acountToUpdateDispatchDetails.TechDispatchedTimeStamp__c = DateTime.valueOf(dispatchTimeStampStr);
                    String dispatchVersionStr = (String)publishedAccountEvents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                    acountToUpdateDispatchDetails.TechDispatchedVersion__c = Decimal.valueOf(dispatchVersionStr);
                    accountToUpdateDispatchDetailsList.add(acountToUpdateDispatchDetails);
                }
            }
        }
        if(accountToUpdateDispatchDetailsList.size()>0){
            Database.update(accountToUpdateDispatchDetailsList);
        }
    }
}