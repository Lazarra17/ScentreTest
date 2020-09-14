/**
* Class PropertyMapsTriggerHandler
*
* Trigger Handler for the PropertyMaps__c SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class PropertyMapsTriggerHandler extends TriggerHandler implements ITrigger {
    private Map<Id, List<Space__c>> propertySpaceMap = new Map<Id, List<Space__c>>();
    private List<Space__c> spaceToUpdateList = new List<Space__c>();
    
    // Constructor
    public PropertyMapsTriggerHandler()
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
            Set<Id> propertyIdSet = new Set<Id>();
            PropertyMaps__c oldPropMapRec = new PropertyMaps__c();
            for(PropertyMaps__c propMapRec :(List<PropertyMaps__c>) Trigger.new) {
                if(Trigger.isInsert) {
                    propertyIdSet.add(propMapRec.Property__c);
                }
                if(Trigger.isUpdate) {
                    oldPropMapRec = (PropertyMaps__c)Trigger.oldMap.get(propMapRec.Id);
                    if(propMapRec.URL__c != oldPropMapRec.URL__c) {
                        propertyIdSet.add(propMapRec.Property__c);
                    }
                }
            }
            // START : KT RPP-5580 8-2-18
            if(propertyIdSet != null && propertyIdSet.size() > 0) {
                propertySpaceMap = DatabaseSOQLBank.getSpacesOfProperty(propertyIdSet);
            }
            // END : KT RPP-5580 8-2-18
            if(Trigger.isInsert) {
            }
            if(Trigger.isUpdate) {
            }
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
        PropertyMaps__c newPropMap = (PropertyMaps__c)so;
        
        // START : KT RPP-5580 8-2-18
        spaceToUpdateList.addAll(PropertyMapsBL.updateSpaceFloorPlanURL(propertySpaceMap, newPropMap));
        // END : KT RPP-5580 8-2-18
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
        PropertyMaps__c newPropMap = (PropertyMaps__c)so;
        PropertyMaps__c oldPropMap = (PropertyMaps__c)oldSo;
        
        // START : KT RPP-5580 8-2-18
        if(newPropMap.URL__c != oldPropMap.URL__c) {
            spaceToUpdateList.addAll(PropertyMapsBL.updateSpaceFloorPlanURL(propertySpaceMap, newPropMap));
        }
        // END : KT RPP-5580 8-2-18
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    public void andFinally()
    {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyMapsTriggerHandler.class.getName());
        
        // START : KT RPP-5580 8-2-18
        if(spaceToUpdateList != null && spaceToUpdateList.size() > 0) {
            try {
                database.update(spaceToUpdateList, false);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : KT RPP-5580 8-2-18
        errorHandler.save();
    }

}