/**
* Class TaskTriggerHandler
*
* Trigger Handler for the Opportunity SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public class TaskTriggerHandler extends TriggerHandler implements ITrigger{
    private TaskUtility.TaskOwnerWrapper taskOwnerWrap = new TaskUtility.TaskOwnerWrapper();
    private List<Task> newTaskForInsertList = new List<Task>();
    private List<Task> newTaskForInsertListFinal = new List<Task>();
    private Map<String, List<TaskTemplateAndCondition__c>> parentNameTaskTemplateListMap;
    private static Map<String, Schema.RecordTypeInfo> taskRecordTypeMap;
    
    //private Map<String, Map<String, List<TaskTemplateAndCondition__c>>> businessUnitTaskTemplateMap;
    private static Map<Id, SObject> parentRecordMap = new Map<Id, SObject>();
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    private Map<Id, List<TaskTemplateAndCondition__c>> dependentTaskTemplateMap = new Map<Id, List<TaskTemplateAndCondition__c>>();
    
    private Map<String, String> taskTypeParentObjectMap = new Map<String, String>();
    private List<Task> taskForUpdateList = new List<Task>();
    private Map<Id, Opportunity> oppForUpdateMap = new Map<Id, Opportunity>();
    
    Map<Id,Task> dbTaskDataMapToPublish=new Map<Id, Task>();
    List<TaskEvent__e> taskEventsToPublish = new List<TaskEvent__e>();
    private Map<Id, Case> caseMap = new Map<Id, Case>();
    private Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    private Map<String, List<TaskTemplateAndCondition__c>> taskTypeTaskTemplateListMap = new Map<String, List<TaskTemplateAndCondition__c>>();
    
    public List<TaskTemplateAndCondition__c> firstChild = new List<TaskTemplateAndCondition__c>();
    public List<TaskTemplateAndCondition__c> secondChild = new List<TaskTemplateAndCondition__c>();
    
    public Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
    
    // RPP-6009 KT 10.12.2018
    private Map<Id,List<PropertyTeam__c>> propertyTeamMap = new Map<Id,List<PropertyTeam__c>>();
    /**
* This method is called prior to execution of a AFTER trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    public void bulkBefore(){
        Set<String> taskTypeSet = new Set<String>();
        List<Task> taskList = (List<Task>) Trigger.new;
        System.debug('---In Bulk before Method---'+taskList[0]);
        taskTypeSet.add(Constants.SEND_DOC_FOR_EXECUTION_API);
        taskRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        
        if(Trigger.isInsert || Trigger.isUpdate){
            Set<Id> oppWhatIdSet = new Set<Id>();
            Set<Id> caseWhatIdSet = new Set<Id>();
            Set<Id> taskOppIdSet = new Set<Id>();
            for(Task tas : taskList){
                if(String.isNotBlank(tas.WhatId)){
                    if(tas.WhatId.getSObjectType() == Schema.Case.SObjectType){
                        caseWhatIdSet.add(tas.WhatId);
                    } else if(tas.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                        oppWhatIdSet.add(tas.WhatId);
                    }
                }
            }
            
            if(caseWhatIdSet != null && !caseWhatIdSet.isEmpty()){
                try{
                    caseMap.putAll(DatabaseSOQLBank.getCase(caseWhatIdSet));
                } catch(Exception e){
                    caseMap = null;
                }
            }
            
            if(oppWhatIdSet != null && !oppWhatIdSet.isEmpty()){
                try{
                    opportunityMap.putAll(DatabaseSOQLBank.getOpportunityMap(oppWhatIdSet));
                } catch(Exception e){
                    opportunityMap = null;
                }
            }
            
            if(caseMap != null){
                parentRecordMap.putAll(caseMap);
            }
            
            if(opportunityMap != null){
                parentRecordMap.putAll(opportunityMap);
            }
            
            if(Trigger.isInsert){
                //RPP - 10774  START 
               System.debug('TaskTriggerHandlertaskListBEFORE>>>  ' + taskList);
               UpdatePropertyField.updatePropertyOnTask(taskList);
               System.debug('TaskTriggerHandlertaskListAFTER>>>  ' + taskList); 
                //RPP - 10774  END
                
                //RPP-10730 : Populate KPI and due date for 'Initial Cost Estimate' & 'Sketch Plan', KPI as 5 & 10 & ActivityDate as 5 & 10 excluding weekends.
                for(Task t : taskList){
                    if(t.TaskType__c == '70 - Initial Cost Estimate'){
                        t.KPI__c = 10;
                        t.ActivityDate = DateUtils.AddBusinessDays(system.today(),10);
                    }
                    if(t.TaskType__c == '71 - Sketch Plan'){
                        t.KPI__c = 5;
                        t.ActivityDate = DateUtils.AddBusinessDays(system.today(),5);
                    }
                }
                
                for(TaskTemplateAndCondition__c taskTemplate: [SELECT Id, TaskType__c, CaseRecordType__c, BusinessUnit__c, LeaseType__c, SpecialtyLeaseType__c,
                                                               OpportunityStage__c, ApplicableCountry__c
                                                               FROM TaskTemplateAndCondition__c 
                                                               WHERE TaskType__c IN: taskTypeSet]){
                                                                   if(taskTypeTaskTemplateListMap.containsKey(taskTemplate.TaskType__c)){
                                                                       taskTypeTaskTemplateListMap.get(taskTemplate.TaskType__c).add(taskTemplate);
                                                                   } else {
                                                                       taskTypeTaskTemplateListMap.put(
                                                                           taskTemplate.TaskType__c,
                                                                           new List<TaskTemplateAndCondition__c>{taskTemplate}
                                                                       );
                                                                   }
                                                               }
                system.debug('oppWhatIdSet-->' + oppWhatIdSet);
                if(oppWhatIdSet != null && oppWhatIdSet.size() > 0) {
                    List<Opportunity> opportunityList = new List<Opportunity>();
                    Set<Id> propertyIdSet = new Set<Id>();
                    Map<Id, List<PropertyTeam__c>> propTeamMap = new Map<Id, List<PropertyTeam__c>>();
                    try {
                        opportunityList = DatabaseSOQLBank.getOpportunityList(oppWhatIdSet);
                    } catch(Exception e) {
                        opportunityList = null;
                    }
                    if(opportunityList != null && opportunityList.size() > 0) {
                        for(Opportunity oppRec :opportunityList) {
                            propertyIdSet.add(oppRec.Property__c);
                        }
                    }
                    system.debug('propertyIdSet-->' + propertyIdSet);
                    if(propertyIdSet != null && propertyIdSet.size() > 0) {
                        try {
                            for(PropertyTeam__c propTeamRec :DatabaseSOQLBank.getPropertyTeam(propertyIdSet)) {
                                if(propTeamMap.containsKey(propTeamRec.Property__c)) {
                                    propTeamMap.get(propTeamRec.Property__c).add(propTeamRec);
                                } else {
                                    propTeamMap.put(propTeamRec.Property__c, new List<PropertyTeam__c>{propTeamRec});
                                }
                            }
                        } catch(Exception e) {
                            propTeamMap = null;
                        }
                        system.debug('propTeamMap-->' + propTeamMap);
                        if(propTeamMap != null) {
                            for(Opportunity oppRec :opportunityList) {
                                if(propTeamMap.containsKey(oppRec.Property__c)) {
                                    propertyTeamMap.put(oppRec.Id, propTeamMap.get(oppRec.Property__c));
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
* This method is called prior to execution of a BEFORE trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    public void bulkAfter(){
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> whatIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> oppPropertyIdSet = new Set<Id>();
        Set<Id> parentTasktemplateIdSet = new Set<Id>();
        Set<String> parentTaskTypeSet = new Set<String>();
        List<Task> taskList = (List<Task>) Trigger.new;
        
        Map<Id, TaskTemplateAndCondition__c> childTaskTemplateMap;
        
        if(Trigger.isInsert || Trigger.isUpdate){
            
            Task oldTask;
            Set<Id> adsTaskOppIdSet = new Set<Id>();
            
            for(Task taskRec : taskList){
                if(taskRec.WhatId != null){
                    whatIdSet.add(taskRec.WhatId);
                    if(taskRec.WhatId.getsobjecttype() == Schema.Case.SObjectType){
                        caseIdSet.add(taskRec.WhatId);
                    } else if(taskRec.WhatId.getsobjecttype() == Schema.Opportunity.SObjectType){
                        oppIdSet.add(taskRec.WhatId);
                        }
                }
                
                if(taskRec.TECHTaskTemplateId__c != null){
                    parentTasktemplateIdSet.add(taskRec.TECHTaskTemplateId__c);
                    //firstChild = [Select ID,TaskType__c,DependentTask__r.TaskType__c,AssigneesTeam__c,AccountTeamRole__c,ApplicableCountry__c,AssignTo__c,BusinessUnit__c,CaseRecordType__c,DependentTask__c,DueDate__c,GroupRenewalRole__c,IsActive__c,IsStageChange__c,JVApproval__c,LeaseType__c,Object__c,OpportunityStage__c,Order__c,ProjectTeamRole__c,SkipWeekends__c,SpecialtyLeaseType__c,TaskDescription__c,TaskName__c From TaskTemplateAndCondition__c Where TaskType__c = '24 - Send Documents to JV for Execution' AND DependentTask__c =: taskRec.TECHTaskTemplateId__c];
                    
                    if(firstChild.size() > 0){
                    system.debug('Dat=> ' +firstChild);
                    
                    //secondChild = [Select ID,TaskType__c,DependentTask__r.TaskType__c,AssigneesTeam__c,AccountTeamRole__c,ApplicableCountry__c,AssignTo__c,BusinessUnit__c,CaseRecordType__c,DependentTask__c,DueDate__c,GroupRenewalRole__c,IsActive__c,IsStageChange__c,JVApproval__c,LeaseType__c,Object__c,OpportunityStage__c,Order__c,ProjectTeamRole__c,SkipWeekends__c,SpecialtyLeaseType__c,TaskDescription__c,TaskName__c From TaskTemplateAndCondition__c Where TaskType__c = '25 - Send Executed Lease to Solicitor' AND DependentTask__c =: firstChild[0].id];
					system.debug('Dat=> ' +secondChild);
                }
                }
                
                
                System.debug('Dta===> ' + taskRec.TECHTaskTemplateId__c);
                
                if(Trigger.isUpdate){
                    oldTask = (Task) Trigger.oldMap.get(taskRec.Id);
                    
                    if(Constants.COMPLETED.equalsIgnoreCase(taskRec.Status) && taskRec.Status != oldTask.Status){
                        if(Constants.ACCEPT_DISCLOSURE_STATEMENT_API.equalsIgnoreCase(taskRec.TaskType__c)){
                            adsTaskOppIdSet.add(taskRec.WhatId);
                        }
                    }
                }
            }
            
            //parentTasktemplateIdSet.add(taskRec.TECHTaskTemplateId__c);
            firstChild = [Select ID,TaskType__c,DependentTask__r.TaskType__c,AssigneesTeam__c,AccountTeamRole__c,ApplicableCountry__c,AssignTo__c,BusinessUnit__c,CaseRecordType__c,DependentTask__c,DueDate__c,GroupRenewalRole__c,IsActive__c,IsStageChange__c,JVApproval__c,LeaseType__c,Object__c,OpportunityStage__c,Order__c,ProjectTeamRole__c,SkipWeekends__c,SpecialtyLeaseType__c,TaskDescription__c,TaskName__c From TaskTemplateAndCondition__c Where TaskType__c = '24 - Send Documents to JV for Execution' AND DependentTask__c IN :parentTasktemplateIdSet];
            
            if(firstChild.size() > 0)
                secondChild = [Select ID,TaskType__c,DependentTask__r.TaskType__c,AssigneesTeam__c,AccountTeamRole__c,ApplicableCountry__c,AssignTo__c,BusinessUnit__c,CaseRecordType__c,DependentTask__c,DueDate__c,GroupRenewalRole__c,IsActive__c,IsStageChange__c,JVApproval__c,LeaseType__c,Object__c,OpportunityStage__c,Order__c,ProjectTeamRole__c,SkipWeekends__c,SpecialtyLeaseType__c,TaskDescription__c,TaskName__c From TaskTemplateAndCondition__c Where TaskType__c = '25 - Send Executed Lease to Solicitor' AND DependentTask__c =: firstChild[0].id];
            else
                secondChild = new List<TaskTemplateAndCondition__c>();
            system.debug('Dat=> ' +secondChild);
            
            
            
            if(Trigger.isUpdate || Trigger.isInsert){
                //Send Task Event Start
                dbTaskDataMapToPublish = TaskBL.taskEventTriggerCriteriaCheckMap(Trigger.newmap);
                EventpublishHelper.Eventpublishwrapper taskWrapper = new EventpublishHelper.Eventpublishwrapper();
                if(EventpublishHelper.isValidpublish() && dbTaskDataMapToPublish !=null && dbTaskDataMapToPublish.size()>0){
                    taskWrapper = EventpublishHelper.taskFieldChangePublishHelper(Trigger.oldMap, Trigger.newMap, dbTaskDataMapToPublish);
                    taskEventsToPublish.addAll((List<TaskEvent__e>) taskWrapper.eventsobjectList);
                }
                //Send Task Event Finish
                if(parentRecordMap != null && !parentRecordMap.isEmpty()){
                    Case caseTemp;
                    Opportunity oppTemp;
                    
                    for(Id recId : parentRecordMap.keySet()){
                        if(recId.getSObjectType() == Schema.Case.SObjectType){
                            caseTemp = (Case) parentRecordMap.get(recId);
                            if(caseTemp.TechPropertyId__c != null){
                                oppPropertyIdSet.add(caseTemp.TechPropertyId__c);
                            }
                        } else if(recId.getSObjectType() == Schema.Opportunity.SObjectType){
                            oppTemp = (Opportunity) parentRecordMap.get(recId);
                            if(oppTemp.Property__c != null){
                                oppPropertyIdSet.add(oppTemp.Property__c);
                            }
                            
                            if(oppTemp.AccountId != null){
                                accountIdSet.add(oppTemp.AccountId);
                                if(oppTemp.Account.ParentId != null){
                                    accountIdSet.add(oppTemp.Account.ParentId);
                                    
                                    if(oppTemp.Account.Parent.ParentId != null){
                                        accountIdSet.add(oppTemp.Account.Parent.ParentId);
                                    }
                                }
                            }
                        }
                    }
                }
                
                taskOwnerWrap = TaskUtility.getOppAndPropertyTeamMember(oppPropertyIdSet, oppIdSet, accountIdSet);
                
                try{
                    childTaskTemplateMap = DatabaseSOQLBank.getChildTaskTemplate(Constants.TASK, parentTasktemplateIdSet);
                } catch(Exception e){
                    childTaskTemplateMap = null;
                }
                
                if(childTaskTemplateMap != null){
                    dependentTaskTemplateMap = TaskUtility.getDependentTaskTemplate(childTaskTemplateMap.values());
                }
                
                try{
                    if(accountIdSet != null){
                        accountMap = DatabaseSOQLBank.getAccountById(accountIdSet);
                    }
                } catch(Exception e){
                    accountMap = null;
                }
                
                if(adsTaskOppIdSet != null && !adsTaskOppIdSet.isEmpty()){
                    for(Task tas : DatabaseSOQLBank.getPrepareCounterOfferTasks(adsTaskOppIdSet)){
                        if(!Constants.COMPLETED.equalsIgnoreCase(tas.Status)){
                            tas.Status = Constants.CANCELLED;
                            taskForUpdateList.add(tas);
                        }
                    }
                }
            }
        }
    }
    
    /**
* This method is called iteratively for each record to be inserted during a BEFORE
* trigger.
* This or other This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeInsert(SObject so){
        Task newTask  = (Task)so;
        newTask.IsReminderSet=true;
        newTask.ReminderDateTime=System.Now();
        taskRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        if(String.isNotBlank(newTask.WhatId)){
            if(newTask.WhatId.getSObjectType() == Schema.Case.SObjectType && caseMap.containsKey(newTask.WhatId)){
                Case taskCaseTemp = caseMap.get(newTask.WhatId);
                
                if(String.IsBlank(newTask.TECHTaskTemplateId__c) && taskTypeTaskTemplateListMap.containsKey(newTask.TaskType__c)){
                    for(TaskTemplateAndCondition__c taskTemplate : taskTypeTaskTemplateListMap.get(newTask.TaskType__c)){
                        if((taskTemplate.CaseRecordType__c != null && taskTemplate.CaseRecordType__c.equalsIgnoreCase(taskCaseTemp.RecordType.Name)) && (taskTemplate.ApplicableCountry__c != null && taskTemplate.ApplicableCountry__c.contains(taskCaseTemp.TECHPropertyCountry__c))){
                            newTask.TECHTaskTemplateId__c = taskTemplate.Id;
                        }
                    }
                }
            } else if(newTask.WhatId.getSObjectType() == Schema.Opportunity.SObjectType && opportunityMap.containsKey(newTask.WhatId)){
                String oppBusinessUnit;
                Opportunity taskOppTemp = opportunityMap.get(newTask.WhatId);
                newTask.Opportunity__c=newTask.WhatId;
                if(newTask.Subject==Constants.TASK_SUBJECT){
                    newTask.TaskType__c=CONSTANTS.TASK_TYPE_APPROVAL_REJECTED;
                    newTask.ownerId=taskOppTemp.ApprovalSubmitter__c;
                    newTask.RecordTypeId = taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId();
                }
      
                if(Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(taskOppTemp.RecordType.Name)){
                    oppBusinessUnit = Constants.COMMERCIAL;
                } else if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(taskOppTemp.RecordType.Name)){
                    oppBusinessUnit = Constants.RETAIL;
                }else if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(taskOppTemp.RecordType.Name)){
                    oppBusinessUnit = Constants.STOREROOMTYPE;
                }
                
                if(String.IsBlank(newTask.TECHTaskTemplateId__c) && taskTypeTaskTemplateListMap.containsKey(newTask.TaskType__c)){
                    for(TaskTemplateAndCondition__c taskTemplate : taskTypeTaskTemplateListMap.get(newTask.TaskType__c)){
                        if((taskTemplate.BusinessUnit__c != null && taskTemplate.BusinessUnit__c.equalsIgnoreCase(oppBusinessUnit)) 
                           && ((taskOppTemp.SpecialityLeaseType__c != null && taskOppTemp.SpecialityLeaseType__c.equalsIgnoreCase(taskTemplate.SpecialtyLeaseType__c)) 
                               || (String.IsBlank(taskOppTemp.SpecialityLeaseType__c) && Constants.STR_DEFAULT.equalsIgnoreCase(taskTemplate.SpecialtyLeaseType__c)))
                           && (taskTemplate.ApplicableCountry__c != null && taskTemplate.ApplicableCountry__c.contains(taskOppTemp.CurrencyIsoCode))
                           && (taskTemplate.LeaseType__c != null && taskTemplate.LeaseType__c.contains(taskOppTemp.Type))){
                               newTask.TECHTaskTemplateId__c = taskTemplate.Id;
                           }
                    }
                }
            }
        }
        system.debug('propertyTeamMap-->' + propertyTeamMap);
        if(Constants.TASK_TYPE_CONFIRM_JV_APPROVAL.equalsIgnoreCase(newTask.TaskType__c)) {
            newTask.RecordTypeId = taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId();
            if(newTask.WhatId != null && 
               propertyTeamMap.containsKey(newTask.WhatId)) {
                   for(PropertyTeam__c propTeamRec :propertyTeamMap.get(newTask.WhatId)) {
                       if(Constants.TEAM_ROLE_LFA.equalsIgnoreCase(propTeamRec.Role__c)) {
                           newTask.OwnerId = propTeamRec.TeamMember__c;
                           break;
                       }
                   }
               }
        }
    }
    
    /**
* This method is called iteratively for each record to be updated during a BEFORE
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeUpdate(SObject oldSo, SObject so){
        
    }
    
    /**
* This method is called iteratively for each record to be deleted during a BEFORE
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeDelete(SObject so){
        
    }
    
    /**
* This method is called iteratively for each record to be inserted during a AFTER
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void afterInsert(SObject so){
       /* 
        Task newTask = (Task) so; 
        Space__c oppSpace;
        Account oppAccount;
        Opportunity oppoTemp;
        Property__c oppProperty;
        
		if(parentRecordMap != null && parentRecordMap.containsKey(newTask.WhatId)){
            if(newTask.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                oppoTemp = (Opportunity) parentRecordMap.get(newTask.WhatId);
                
                System.debug('oppoTemp===> ' + oppoTemp);
                
                if(accountMap != null && accountMap.containsKey(oppoTemp.AccountId)){
                    oppAccount = accountMap.get(oppoTemp.AccountId);
                }
                
                if(oppoTemp.Space__c != null){
                    oppSpace = oppoTemp.Space__r;
                }
                
                if(oppoTemp.Property__c != null){
                    oppProperty = oppoTemp.Property__r;
                }
            }
            
            system.debug('oppSpace : ' + oppSpace);
            system.debug('oppProperty : ' + oppProperty);
            system.debug('taskOwnerWrap : ' + taskOwnerWrap);
        
        if(newTask.Subject == 'Send Documents to JV for Execution' && newTask.Status == 'Completed'){
            
                if(Constants.COMPLETED.equalsIgnoreCase(newTask.Status)){
                    System.debug('Chen debug ' + dependentTaskTemplateMap.size() + ' ' + dependentTaskTemplateMap.get(newTask.TECHTaskTemplateId__c));
                    System.debug('Chen debug ' + dependentTaskTemplateMap.containsKey(newTask.TECHTaskTemplateId__c));
                    System.debug('Chen debug ' + parentRecordMap.get(newTask.WhatId) );
                    System.debug('Chen debug ' + taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId());
                    System.debug('Chen debug ' + dependentTaskTemplateMap.get(newTask.TECHTaskTemplateId__c));
                    System.debug('Chen debug ' + taskOwnerWrap + '===');
                    System.debug('Chen debug ' + taskOwnerWrap + '===');
                    System.debug('Chen debug ' + oppAccount + '===');
                    System.debug('Chen debug ' + oppProperty + '===');
                    System.debug('Chen debug ' + oppSpace + '===');
                    
                    if(dependentTaskTemplateMap != null && dependentTaskTemplateMap.containsKey(newTask.TECHTaskTemplateId__c)){
                        newTaskForInsertList.addAll(
                            TaskUtility.createTask(
                                parentRecordMap.get(newTask.WhatId), 
                                taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                                dependentTaskTemplateMap.get(newTask.TECHTaskTemplateId__c),
                                taskOwnerWrap,
                                oppAccount,
                                oppProperty,
                                oppSpace
                            )
                        );
                    }
                   system.debug('Data==> ' + newTaskForInsertList.size());
                    system.debug('Data==> ' + newTaskForInsertList);
                    
                    if(newTask.WhatId.getsobjecttype() == Schema.Opportunity.SObjectType){
                        if(Constants.JV_APPROVAL_API.equalsIgnoreCase(newTask.TaskType__c)){
                            oppoTemp.TECHJVCompleted__c = true;
                            oppForUpdateMap.put(oppoTemp.Id, oppoTemp); 
                        }
                    }
                }
        }
            
        }
        */
    }
    
    /**
* This method is called iteratively for each record to be updated during a AFTER
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void afterUpdate(SObject oldSo, SObject so){
        Task newTask = (Task) so;
        Task oldTask = (Task) oldSo;
        
        Space__c oppSpace;
        Account oppAccount;
        Opportunity oppoTemp;
        Property__c oppProperty;
        
         
      /*commented out for 10681  
        //10549 start
        if(newTask.Status=='Completed' && newTask.TaskType__c == '39 - Instruct Solicitor' ){ 
            System.debug('newTask.WhatId' + newTask.WhatId);
            String s1 = String.valueof(newTask.WhatId);
            if(s1.startsWith('006')){ 
                 System.Approval.lock(newTask.WhatId);
                 //Boolean b = System.Approval.lock(newTask.WhatId).isSuccess();
            }  
        }
        //10549 end
        */
        
        
        if(parentRecordMap != null && parentRecordMap.containsKey(newTask.WhatId)){
            if(newTask.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                oppoTemp = (Opportunity) parentRecordMap.get(newTask.WhatId);
                
                System.debug('oppoTemp===> ' + oppoTemp);
                
                if(accountMap != null && accountMap.containsKey(oppoTemp.AccountId)){
                    oppAccount = accountMap.get(oppoTemp.AccountId);
                }
                
                if(oppoTemp.Space__c != null){
                    oppSpace = oppoTemp.Space__r;
                }
                
                if(oppoTemp.Property__c != null){
                    oppProperty = oppoTemp.Property__r;
                }
            }
            
            system.debug('oppSpace : ' + oppSpace);
            system.debug('oppProperty : ' + oppProperty);
            system.debug('taskOwnerWrap : ' + taskOwnerWrap);
            
            //
            
            Opportunity o = new Opportunity();
            //Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            if(newTask.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                o = (Opportunity) parentRecordMap.get(newTask.WhatId);
                //oppMap = new Map<Id,Opportunity>([Select ID, Property__c, Property__r.PropertyOwnershipType__c From Opportunity WHERE ID =:o.Id AND Property__c != null AND Property__r.PropertyOwnershipType__c != 'JV Partner']);
            }
            
            if(!newTask.Status.equalsIgnoreCase(oldTask.Status)){
                if(Constants.COMPLETED.equalsIgnoreCase(newTask.Status)){
                    System.debug('Chen debug ' + dependentTaskTemplateMap + ' ' + dependentTaskTemplateMap.get(newTask.TECHTaskTemplateId__c));
                    if(dependentTaskTemplateMap != null && dependentTaskTemplateMap.containsKey(newTask.TECHTaskTemplateId__c)){                           
                        newTaskForInsertList.addAll(
                            TaskUtility.createTask(
                                parentRecordMap.get(newTask.WhatId), 
                                taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                                dependentTaskTemplateMap.get(newTask.TECHTaskTemplateId__c),
                                taskOwnerWrap,
                                oppAccount,
                                oppProperty,
                                oppSpace
                            )
                        );
                    }
                    
                    if(secondChild.size() > 0)
                    for(Task newTaskCreation : newTaskForInsertList){
                        if(oppMap.ContainsKey(newTaskCreation.whatId)){
                           System.debug('Data==> ' + newTaskCreation); 
                            if(newTaskCreation.Subject == 'Send Documents to JV for Execution'){
                                newTaskCreation.Status = 'Completed';
                                //newTaskCreation.JVFlag__c = true;
                                    System.debug('depTaskGet==> ' + dependentTaskTemplateMap+ ' ====== ' + newTaskCreation.TECHTaskTemplateId__c + ' ===== '+ dependentTaskTemplateMap.get(newTaskCreation.TECHTaskTemplateId__c));
                                //if(dependentTaskTemplateMap != null && dependentTaskTemplateMap.containsKey(newTaskCreation.TECHTaskTemplateId__c)){
                                        newTaskForInsertListFinal.addAll(
                                            TaskUtility.createTask(
                                                parentRecordMap.get(newTaskCreation.WhatId), 
                                                taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                                                secondChild,
                                                //dependentTaskTemplateMap.get(newTaskCreation.TECHTaskTemplateId__c),
                                                taskOwnerWrap,
                                                oppAccount,
                                                oppProperty,
                                                oppSpace
                                            )
                                        );
                                  //  }
                                system.debug('Final Last Task===> ' + newTaskForInsertList);
                            }
                        }
                    }
                    newTaskForInsertList.addAll(newTaskForInsertListFinal);
                    if(newTask.WhatId.getsobjecttype() == Schema.Opportunity.SObjectType){
                        if(Constants.JV_APPROVAL_API.equalsIgnoreCase(newTask.TaskType__c)){
                            oppoTemp.TECHJVCompleted__c = true;
                            oppForUpdateMap.put(oppoTemp.Id, oppoTemp); 
                        }
                    }
                }
            }
        }
    }
    
    /**
* This method is called iteratively for each record to be updated during a AFTER
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void afterDelete(SObject so){
        
    }
    
    public void andFinally(){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(TaskTriggerHandler.class.getName());
        
        //Event Sending
        List<TaskEvent__e> successfullpublishTask = new List<TaskEvent__e>();
        
        if (taskEventsToPublish.size() > 0) {
            List<Database.SaveResult> resultsTasks = EventBus.publish(taskEventsToPublish);
            for(integer i=0; i<resultsTasks.size(); i++){
                if(resultsTasks[i].isSuccess()){
                    successfullpublishTask.add(taskEventsToPublish[i]);
                }
            }
            TaskBL.updateTaskWhenTaskEventSentSuccess(successfullpublishTask);
        }
        //Event Sending Finish
        system.debug('newTaskForInsertList : ' + newTaskForInsertList);
        if(newTaskForInsertList != null && newTaskForInsertList.size() > 0){
            try{
                UpdatePropertyField.updatePropertyOnTask(newTaskForInsertList); //RPP - 10774
                Database.insert(newTaskForInsertList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        if(taskForUpdateList != null && !taskForUpdateList.isEmpty()){
            try{
                Database.update(taskForUpdateList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        //Opportunity Update
        if(oppForUpdateMap != null && !oppForUpdateMap.isEmpty()){
            try{
                Database.update(oppForUpdateMap.values());
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        errorHandler.save();
    }
}