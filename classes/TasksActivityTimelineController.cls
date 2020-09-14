public with sharing class TasksActivityTimelineController {
 
    public class TasksActivityTimelineWrapper{
        @AuraEnabled public List<Task> allTaskList = new List<Task>();
        @AuraEnabled public List<Task> adhocTaskList = new List<Task>();
    }
    
   /**
    * @author:          Kyle Tan
    * @description:     retrieves tasks of the opportunity
    **/
    @AuraEnabled
    public static LightningResponse getTasksOfOpp(Id oppId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(TasksActivityTimelineController.class.getName());
        TasksActivityTimelineWrapper wrapper = new TasksActivityTimelineWrapper();
        LightningResponse responseObject = new LightningResponse();
        String businessUnit;
        String oppStage;
        Set<Id> IdSet = new Set<Id>();
        Set<String> subjectStrSet = new Set<String>();
        Set<String> subjectbyStageSet = new Set<String>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<String, Schema.RecordTypeInfo> opportunityRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        Map<Id, TaskTemplateAndCondition__c> taskTemplateMap = new Map<Id, TaskTemplateAndCondition__c>();
        List<Task> taskList = new List<Task>();
        
        if(oppId != null) {
            IdSet.add(oppId);
        }
        try{
            oppMap = DatabaseSOQLBank.getOpportunityMap(IdSet);
        }
        catch(Exception e) {
            oppMap = null;
        }
        if(oppMap != null) {
            IdSet = new Set<Id>();
            for(Opportunity oppRec : oppMap.values()) {
                IdSet.add(oppRec.Id);
                if(oppRec.RecordTypeId == opportunityRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId()) {
                    businessUnit = Constants.RETAIL;
                } else if (oppRec.RecordTypeId == opportunityRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId()) {
                    businessUnit = Constants.COMMERCIAL;
                }
                oppStage = oppRec.StageName;
            }
            taskTemplateMap = DatabaseSOQLBank.getTaskTemplateByStage(businessUnit);
            if(taskTemplateMap != null) {
                for(TaskTemplateAndCondition__c taskTempRec : taskTemplateMap.values()) {
                    subjectStrSet.add(taskTempRec.TaskType__c);
                    if(taskTempRec.OpportunityStage__c == oppStage) {
                        subjectbyStageSet.add(taskTempRec.TaskType__c);
                    }
                }
                try {
                    taskList = DatabaseSOQLBank.getTasks(IdSet);
                } catch(Exception e) {
                    taskList = null;
                }
                if(taskList != null && taskList.size() > 0) {
                    for(Task taskRec: taskList) {
                        if(UserInfo.getUserId() == taskRec.OwnerId) {
                            responseObject.message = taskRec.Owner.name;
                        } else {
                            responseObject.message = taskRec.Owner.name;
                        }
                        if(subjectStrSet.contains(taskRec.TaskType__c)) {
                            if(subjectbyStageSet.contains(taskRec.TaskType__c)) {
                                wrapper.allTaskList.add(taskRec);
                            }
                        } else {
                            if(taskRec.Status == Constants.OPEN) {
                                wrapper.adhocTaskList.add(taskRec);
                            }
                        }
                    }
                    responseObject.returnValue = JSON.serialize(wrapper);
                }
            }
        }
        errorHandler.save();
        return responseObject;
    }
    
   /**
    * @author:          Kyle Tan
    * @description:     updates task status
    **/
    @AuraEnabled
    public static LightningResponse updateTaskStatus(String taskId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(TasksActivityTimelineController.class.getName());
        LightningResponse response = new LightningResponse();
        Task taskRec = new Task();
        try{
            taskRec = DatabaseSOQLBank.getTask(Id.valueOf(taskId));
        } catch(Exception e) {
            taskRec = null;
        }
        if(taskRec != null) {
            if(taskRec.Status == Constants.OPEN) {
                taskRec.Status = Constants.COMPLETED;
            } else {
                taskRec.Status = Constants.OPEN;
            }
            try{
                database.update(taskRec);
            } catch(Exception e) {
                response.status = Constants.FAILED;
                response.message = e.getMessage();
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
        return response;
    }
    
   /**
    * @author:          Kyle Tan
    * @description:     updates task status
    **/
    @AuraEnabled
    public static LightningResponse deleteTask(Id taskId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(TasksActivityTimelineController.class.getName());
        LightningResponse response = new LightningResponse();
        try{
            database.delete(taskId);
        } catch(Exception e) {
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        errorHandler.save();
        return response;
    }
}