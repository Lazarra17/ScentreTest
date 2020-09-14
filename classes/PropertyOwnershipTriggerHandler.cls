/*
* Class PropertyOwnershipTriggerHandler
*
* Trigger Handler for the Property Ownership SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class PropertyOwnershipTriggerHandler extends TriggerHandler implements ITrigger{
    private Map<Id, Property__c> propertyToUpdateMap = new Map<Id, Property__c>();
    
    // Constructor
    public PropertyOwnershipTriggerHandler()
    {
    }
    
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
        }
        
        if(Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            Set<Id> propertyIdSet = new Set<Id>();
            //START -- RPP-2872 Kyle Tan 5/22/18
            if(Trigger.isDelete) {
                for(Sobject SobjectPropertyOwnershipRec : Trigger.old) {
                    PropertyOwnership__c propertyOwnershipRec = (PropertyOwnership__c) SobjectPropertyOwnershipRec;
                    propertyIdSet.add(propertyOwnershipRec.Property__c);
                }
            } else {
                for(Sobject SobjectPropertyOwnershipRec : Trigger.new) {
                    PropertyOwnership__c propertyOwnershipRec = (PropertyOwnership__c) SobjectPropertyOwnershipRec;
                    propertyIdSet.add(propertyOwnershipRec.Property__c);
                }
            }
            
            propertyToUpdateMap = PropertyOwnershipBL.buildPropertyToUpdateMap(propertyIdSet);
            //END -- RPP-2872 Kyle Tan 5/22/18
        }
        
    }
    public void beforeInsert(SObject so)
    {
    }
    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }
    
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
    
    public void andFinally()
    {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyOwnershipTriggerHandler.class.getName());
        
        try{
            //START -- RPP-2872 Kyle Tan 5/22/18
            database.upsert(propertyToUpdateMap.values());
            //END -- RPP-2872 Kyle Tan 5/22/18
        } catch (exception e) {
            errorHandler.createError(e);
        }
        errorHandler.save();
    }
}