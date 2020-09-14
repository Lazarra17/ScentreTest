/**
* Class ACRTriggerHandler
*
* Trigger Handler for the Account Contact Relation SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*
**/
public without sharing class ACRTriggerHandler extends TriggerHandler
implements ITrigger {
    
    List<AccountContactEvent__e> acEvents = new List<AccountContactEvent__e>();
    Map<Id, Account> accountMap = new Map<Id, Account>(); //RPP - 10752
    // Constructor
    public ACRTriggerHandler()
    {
    }
    
    /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    **/
    public void bulkBefore()
    {
      
        if(Trigger.isInsert || Trigger.isUpdate) {
            
        }
        
        if(Trigger.isInsert) {

        }
        
        if(Trigger.isUpdate) {
            
        }
        
    }
    
    public void bulkAfter()
    {
        
        if(Trigger.isInsert || Trigger.isUpdate) {
            List<Id> activeContactIds = EventpublishHelper.acrFieldChangePublishHelper(Trigger.oldMap, Trigger.newMap);
            if (activeContactIds.size() > 0) {
                ContactBL.ContactWithFinalizedOppoWrapper conW = ContactBL.constructBaseStructureFromContact(activeContactIds);
                 List<AccountContactEvent__e> successfullpublishAddressBook=new List<AccountContactEvent__e>(); 
                 if (conW.sendEvent) {
                    acEvents = ContactBL.constructPE(conW);
                }
            }
            
            //RPP - 10752
            accountMap = AccountContactRelationBL.updateRDIApplicableContactCount((Map<Id,AccountContactRelation>)Trigger.oldMap, (Map<Id,AccountContactRelation>)Trigger.newMap);
        }
        
        if(Trigger.isDelete) {
            //RPP - 10752
            //RPP-10960 Allow users to Remove Relationship from Property Account Related Contacts
            accountMap = AccountContactRelationBL.updateRDIApplicableContactCount(null, (Map<Id,AccountContactRelation>)Trigger.oldMap);
        }
        
        if(Trigger.isUpdate) {
            
        } 
        
    }
    
    public void beforeInsert(SObject so)
    {
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
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
    **/
    
    public void andFinally()
    {
        List<AccountContactEvent__e> addressBookSuccessEvents = new List<AccountContactEvent__e>();
        if (acEvents.size() > 0 ) {
            List<Database.SaveResult> resultsAddressBook = EventBus.publish(acEvents);
            for(integer i=0; i<resultsAddressBook.size(); i++){
                if(resultsAddressBook[i].isSuccess()){
                    addressBookSuccessEvents.add(acEvents[i]);
                }
            }
            if (addressBookSuccessEvents.size() > 0) {
                ContactBL.updateContactWhenAddressBookEventSentSuccess(addressBookSuccessEvents);   
            }
        } 
        if(!accountMap.isEmpty()) update accountMap.values();
    }
}