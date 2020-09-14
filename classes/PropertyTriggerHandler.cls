/**
* Class PropertyTriggerHandler
*
* Trigger Handler for the Property SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class PropertyTriggerHandler extends TriggerHandler
implements ITrigger
{
    
    private Map<Id, List<Account>> propertyAccountListMap = new Map<Id, List<Account>>();
    private List<Account> accountToUpdateList = new List<Account>();
    private Set<Id> propertyIds = new Set<Id>();
    // Constructor
    public PropertyTriggerHandler()
    {
    }
    
    /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){   
        
    }
    
    public void bulkAfter(){
        // Start -- RPP-2127 Clark Garde 4/20/18
        List<Property__c> propertyList = Trigger.new;
        if(Trigger.isInsert || Trigger.isUpdate){
            for(Property__c propertyVar : propertyList){
                propertyIds.add(propertyVar.Id);
            }
            
            propertyAccountListMap = PropertyBL.getAccount(Trigger.new, propertyIds);
        }
        // End -- RPP-2127
        
    }
    
    public void beforeInsert(SObject so){
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){
    }
    
    public void beforeDelete(SObject so){
    }
    
    public void afterInsert(SObject so){
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
        // Start -- RPP-2127 Clark Garde 4/20/18
        Property__c newProperty = (Property__c)so;
        Property__c oldProperty = (Property__c)oldSo;
        
        accountToUpdateList = PropertyBL.renameAccount(oldProperty, newProperty, accountToUpdateList, propertyAccountListMap);
        // End -- RPP-2127
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
    
    public void andFinally(){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyTriggerHandler.class.getName());
        
        if(accountToUpdateList.size() > 0){
            try{
                Database.update(accountToUpdateList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
}