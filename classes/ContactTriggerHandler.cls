/**
* Class ContactTriggerHandler
*
* Trigger Handler for the Contact SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*
*/
public without sharing class ContactTriggerHandler extends TriggerHandler
implements ITrigger {
    
    List<AccountContactEvent__e> acEvents = new List<AccountContactEvent__e>();    
    // Constructor
    public ContactTriggerHandler()
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
            
        }
        
        if(Trigger.isInsert) {
            
        }
        
        if(Trigger.isUpdate) {
            List<Id> activeContactIds = EventpublishHelper.contactFieldChangePublishHelper(Trigger.oldMap, Trigger.newMap);
            if (activeContactIds.size() > 0) {
                ContactBL.ContactWithFinalizedOppoWrapper conW = ContactBL.constructBaseStructureFromContact(activeContactIds);
                 List<AccountContactEvent__e> successfullpublishAddressBook=new List<AccountContactEvent__e>(); 
                 if (conW.sendEvent) {
                    acEvents = ContactBL.constructPE(conW);
                }
            }
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
        List<AccountContactEvent__e> acSuccessEvents = new List<AccountContactEvent__e>();
        if (acEvents.size() > 0 ) {
            List<Database.SaveResult> resultsAddressBook = EventBus.publish(acEvents);
            for(integer i=0; i<resultsAddressBook.size(); i++){
                if(resultsAddressBook[i].isSuccess()){
                    acSuccessEvents.add(acEvents[i]);
                }
            }
            if (acSuccessEvents.size() > 0) {
                ContactBL.updateContactWhenAddressBookEventSentSuccess(acSuccessEvents);   
            }
        }   
    }
}