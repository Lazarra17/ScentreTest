trigger TaskTrigger on Task (after delete, after insert, after update, before delete, before insert, before update) {
    if(Trigger.new!=null){
        for(Task taskRec : (List<Task>) Trigger.new){
            if(Constants.TASK_TYPE_CONFIRM_JV_APPROVAL.equalsIgnoreCase(taskRec.TaskType__c)){
                TriggerHandler.clearBypass('TaskTriggerHandler');
                break;
            }
        }
    }
    TriggerFactory.createAndExecuteHandler(TaskTriggerHandler.class);
}