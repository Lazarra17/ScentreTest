public class TaskBL {
	
    /** 
    * @Author: Chen Chen
    * @Para: List<String> jsonPayloads, List of json payload that need to send out as task event
    * @Desc: This is used for generating task platform events by the providing payloads
    */ 
    
    public static List<TaskEvent__e> generateTaskEvents(List<String> payloads) {
        List<TaskEvent__e> taskEvents = new List<TaskEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                TaskEvent__e taskE = new TaskEvent__e();
                taskE.JSONPayload__c = payload;
                taskEvents.add(taskE);
            }
        }
        return taskEvents;
    }
    
    public static void updateTaskWhenTaskEventSentSuccess(List<TaskEvent__e> successfullpublish) {
        List<Task> taskToUpdateDispatchDetailsList=new List<Task>(); 
        if(!successfullpublish.isEmpty()&&successfullpublish.size()>0){
            for(TaskEvent__e publishedEvent: successfullpublish){
                // get values from pubished event payload to update parent records
                Map<String, Object> publishedTaskEvents=(Map<String, Object>)JSON.deserializeUntyped(publishedEvent.JSONPayload__c);
                Task taskToUpdateDispatchDetails=new Task();
                taskToUpdateDispatchDetails.id=(id)publishedTaskEvents.get(Constants.DML_ID.toUpperCase());
                String dispatchTimeStampStr=(String)publishedTaskEvents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                taskToUpdateDispatchDetails.TechDispatchedTimeStamp__c =DateTime.valueOf(dispatchTimeStampStr);
                String dispatchVersionStr=(String)publishedTaskEvents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                taskToUpdateDispatchDetails.TechDispatchedVersion__c=Decimal.valueOf(dispatchversionstr);
                taskToUpdateDispatchDetailsList.add(taskToUpdateDispatchDetails);
            }
        }
        if(!taskToUpdateDispatchDetailsList.isEmpty() && taskToUpdateDispatchDetailsList.size()>0){
            Database.update(taskToUpdateDispatchDetailsList);
        }
    }
    
    /**
	* @Author : Chen chen
	* @Parameter : list of tasks need to be checked
	* @Description : based on the custom meta data task event trigger to determine whether to send event or not
	*/
    public static List<Task> taskEventCriteriaCheck(List<Task> tasks) {
        List<Task> validTasks = new List<Task>();
        List<TaskEventTrigger__mdt> criteriaSelections = [SELECT TaskStatus__c, TaskType__c FROM TaskEventTrigger__mdt LIMIT 10000];
        for (Task taskRecord : tasks) {
            if (taskRecord.OpportunityNumber__c != null && taskRecord.OpportunityNumber__c != '') {
            	for (TaskEventTrigger__mdt taskEventTrigger : criteriaSelections) {
                    if (taskRecord.TaskType__c != null && taskRecord.Status != null && taskRecord.TaskType__c == taskEventTrigger.TaskType__c && taskRecord.Status == taskEventTrigger.TaskStatus__c) {
                        validTasks.add(taskRecord);
                        break;
                    }
                }   
            }
        }
        return validTasks;
    }
    
    /**
    * @Author: Chen Chen
    * @Parameter: trigger new map
    * @Description: when task is fulfilled the critera from custom meta data type task event trigger, put it into map
    */
    public static Map<Id, Task> taskEventTriggerCriteriaCheckMap(Map<Id, Sobject> taskNewMap) {
        Map<Id, Task> dbTaskDataMapToPublish = new Map<Id, Task>();
        List<Task> dbTaskDataMap = taskNewMap.values();
        List<Task> validTasks = taskEventCriteriaCheck(dbTaskDataMap);
        if (validTasks.size() > 0) {
            for (Task taskRecord : validTasks) {
                dbTaskDataMapToPublish.put(taskRecord.Id, (Task)taskNewMap.get(taskRecord.Id));
            }   
        }
        return dbTaskDataMapToPublish;
    }
}