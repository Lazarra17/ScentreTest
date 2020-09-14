public class UpdatePropertyField { 
    public static List<Task> updatePropertyOnTask(List<Task> taskList){
        List<Task> taskListToUpdate = new List<Task>();
        Map<String, Set<Id>> sObjVsIdsMap = new Map<String, Set<Id>>();
        Map<String, ObjectAPIvsPropertyPath__mdt> objAPIvsPropPath = new Map<String, ObjectAPIvsPropertyPath__mdt>();
        Map<Id, sObject> IdVsSobjMap = new Map<Id, sObject>();
        
        for(ObjectAPIvsPropertyPath__mdt pathMeta : [SELECT Id, ObjAPIName__c, PropertyNamePath__c FROM ObjectAPIvsPropertyPath__mdt WHERE isActive__c = TRUE]){
            objAPIvsPropPath.put(pathMeta.ObjAPIName__c , pathMeta);
        }
        for(Task t : taskList){ 
            Id taskWhatId = t.WhatId;
            if( sObjVsIdsMap.containsKey(taskWhatId.getsobjecttype().getDescribe().getName())){
                sObjVsIdsMap.get(taskWhatId.getsobjecttype().getDescribe().getName()).add(t.WhatId);
            } else{
                sObjVsIdsMap.put(taskWhatId.getsobjecttype().getDescribe().getName(), new Set<Id>{ t.WhatId });
            }
        }       
        
        for(String sObjectType : sObjVsIdsMap.keySet()){
            Set<Id> newTestSet = new Set<Id>();
            newTestSet = sObjVsIdsMap.get(sObjectType);
            if(objAPIvsPropPath.containsKey(sObjectType)){
                String propFieldAPI = objAPIvsPropPath.get(sObjectType).PropertyNamePath__c;
                String query = 'SELECT Id,' + propFieldAPI 
             	    		   + ' FROM ' + sObjectType 
            		    	   +' WHERE Id IN : newTestSet'; 
                IdVsSobjMap = new Map<Id, sObject>(Database.query(query));
            }	            
        }
        
        for(Task tsk: taskList){
            if(IdVsSobjMap.containsKey(tsk.WhatId)){
                
                String propFieldAPI2 = objAPIvsPropPath.get(tsk.WhatId.getsobjecttype().getDescribe().getName()).PropertyNamePath__c;
                String tempObject = (String)(getValueFromSobject((sObject)IdVsSobjMap.get(tsk.WhatId), propFieldAPI2));
                tsk.Property2__c =  tempObject;
                taskListToUpdate.add(tsk);
            }
        }
        return taskListToUpdate;
    }
    
    public static Object getValueFromSobject(sObject sObj, String concatenatedFieldString){
        if(String.isBlank(concatenatedFieldString)) return null;
        Object value;
        Map<String, Object> fieldValues = sObj.getPopulatedFieldsAsMap();
        List<String> splittedFields = concatenatedFieldString.split('\\.');
        for(Integer i = 0 ; i < splittedFields.size(); i++){
            if(sObj == null) return null;
            if(fieldValues.get(splittedFields[i]) instanceof sObject){
                fieldValues = ((sObject)fieldValues.get(splittedFields[i])).getPopulatedFieldsAsMap();
            }else{
                value = fieldValues.get(splittedFields[i]);
            }
        }
        return value;
    }

}