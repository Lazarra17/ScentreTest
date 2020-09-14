global class PopulatePropertyOnTaskBatch implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, WhatId, Property2__c FROM Task WHERE Property2__c = NULL AND WhatId != NULL]);
    }
    global void execute(Database.BatchableContext BC, List<Task> taskList){
        System.debug('taskList.Prop   '+ taskList[0].Property2__c);
        taskList = UpdatePropertyField.updatePropertyOnTask(taskList);
        System.debug('taskList.Prop after   '+ taskList[0].Property2__c);
        Database.update(taskList, false);
    }
    global void finish(Database.BatchableContext BC){
        
    }
}