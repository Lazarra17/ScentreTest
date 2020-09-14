/**
 ** Comments: Used to instantiate and execute Trigger Handlers associated with sObjects.
 ** Date Provided: 13-04-2018
 ** Owner: Accenture PLC
 ** Confidential. This document incorporates information that is proprietary to Accenture. 
 ** The Accenture information in this document is supplied in confidence and, except for any purposes agreed by the parties, 
 ** should not be disclosed, duplicated or otherwise revealed in whole or in part without the prior written consent of Accenture
 **/
public without sharing class TriggerFactory
{
    
    /**
     * Public static method to create and execute a trigger handler
     *
     * Arguments:   Schema.sObjectType soType - Object type to process (SObject.sObjectType)
     *
     * Throws a TriggerException if no handler has been found.
     */
    //public static void createAndExecuteHandler(Schema.sObjectType soType)
    public static void createAndExecuteHandler(Type handlerType)
    {
        if(!BypassSettings__c.getInstance().GlobalTriggerBypass__c){
            // Get a handler appropriate to the object being processed
            ITrigger handler = getHandler(handlerType);
             
            // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
            if (handler == null)
            {
                throw new TriggerException('No Trigger Handler found named: ' + handlerType.getName());
            }
             
            // Execute the handler to fulfil the trigger
            if(validateRun(handlerType.getName())){
                if(Trigger.isAfter){
                    TriggerHandler.bypass(handlerType.getName());
                }
                execute(handler);
            }
        }
    }
 
    /**
     * private static method to control the execution of the handler
     *
     * Arguments:   ITrigger handler - A Trigger Handler to execute
     */
    private static void execute(ITrigger handler)
    {
        /*if(!handler.validateRun()) {
            return;
        }*/
        // Before Trigger
        if (Trigger.isBefore)
        {
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore();
 
            // Iterate through the records to be deleted passing them to the handler.
            if (Trigger.isDelete)
            {
                for (SObject so : Trigger.old)
                {
                    handler.beforeDelete(so);
                }
            }
            // Iterate through the records to be inserted passing them to the handler.
            else if (Trigger.isInsert)
            {
                for (SObject so : Trigger.new)
                {
                    handler.beforeInsert(so);
                }
            }
            // Iterate through the records to be updated passing them to the handler.
            else if (Trigger.isUpdate)
            {
                for (SObject so : Trigger.old)
                {
                    handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
        else
        {
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter();
 
            // Iterate through the records deleted passing them to the handler.
            if (Trigger.isDelete)
            {
                for (SObject so : Trigger.old)
                {
                    handler.afterDelete(so);
                }
            }
            // Iterate through the records inserted passing them to the handler.
            else if (Trigger.isInsert)
            {
                for (SObject so : Trigger.new)
                {
                    handler.afterInsert(so);
                }
            }
            // Iterate through the records updated passing them to the handler.
            else if (Trigger.isUpdate)
            {
                for (SObject so : Trigger.old)
                {
                    handler.afterUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
 
        // Perform any post processing
        handler.andFinally();
    }

    private static Boolean validateRun(String handlerName)
    {   
        Boolean doRun = true;
        List<TriggerSwitch__mdt> triggerSwitchList = null;
        //String handlerName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));

        if(TriggerHandler.isBypassed(handlerName)) {
            doRun = false;
        }
        
        // check if it is in the trigger switch 
        triggerSwitchList = [SELECT SwitchOn__c FROM TriggerSwitch__mdt WHERE HandlerName__c =: handlerName LIMIT 1];    

        if (triggerSwitchList != null && triggerSwitchList.size() > 0) {
            if (!triggerSwitchList[0].SwitchOn__c) {
                doRun = false;
            }
        }

        return doRun;
    }
 
    /**
     * private static method to get the named handler.
     *
     * Arguments:   Type t - Class of handler to instatiate
     *
     * Returns:     ITrigger - A trigger handler if one exists or null.
     */
    private static ITrigger getHandler(Type handlerType){
        ITrigger iTrigger = null;
        Object handler = TriggerHandler.handlerInstances.containsKey(handlerType.getName()) //RPP-10922
                            ? TriggerHandler.handlerInstances.get(handlerType.getName())
                            : handlerType.newInstance();

        // if its not an instance of ITrigger return null
        if (handler instanceOf ITrigger){
            iTrigger = (ITrigger) handler;
        }
 
        return iTrigger;
    }
 
    public class TriggerException extends Exception {}
}