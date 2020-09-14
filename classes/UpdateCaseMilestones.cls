global class UpdateCaseMilestones implements Database.Batchable<sObject>, Schedulable {
    
    global void execute(SchedulableContext sc){
        UpdateCaseMilestones schedulableBatch = new UpdateCaseMilestones();
        Database.executeBatch(schedulableBatch);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator('SELECT Id, SubType__c , Milestone__c, Status, Is_Lease_Variation_Required__c, '+
                                        '(SELECT Id, Status, TaskType__c FROM Tasks ORDER BY CreatedDate) '+
                                        'FROM Case WHERE SubType__c = \'COVID-19 Rent Request\' '
                                       );
        
    }
    
   global void execute(Database.BatchableContext BC, List<Case> scope){
        List<Case> casesToUpdate = new List<Case>();
        for(Case cs : scope){
            
            
            String finalMilestone;
            
                for(Task tsk : cs.Tasks){                    
                    if(tsk.TaskType__c == Constants.TASKTEMPLATE_GENERATE_OFFER_LETTER && tsk.Status == Constants.COMPLETED)
                        finalMilestone = Constants.CASE_MILESTONE_OFFER_LETTER_GENERATED;
                    
                    if(tsk.TaskType__c == Constants.TASKTEMPLATE_ISSUE_OFFER_LETTER && tsk.Status == Constants.COMPLETED)
                        finalMilestone = Constants.CASE_MILESTONE_OFFER_LETTER_ISSUED;
                    
                    if(tsk.TaskType__c == Constants.TASKTEMPLATE_RECEIVE_SIGNED_OFFER_LETTER && tsk.Status == Constants.COMPLETED && cs.Is_Lease_Variation_Required__c != 'Yes')
                        finalMilestone = Constants.CASE_MILESTONE_OFFER_LETTER_RECEVIED;
                    
                    if(tsk.TaskType__c == Constants.TASKTEMPLATE_RECEIVE_SIGNED_OFFER_LETTER && tsk.Status == Constants.COMPLETED && cs.Is_Lease_Variation_Required__c == 'Yes')
                        finalMilestone = Constants.CASE_MILESTONE_PENDING_RETAIL_ADMIN_REVIEW;
                                
                    if(tsk.TaskType__c == Constants.TASKTEMPLATE_RETAIL_ADMINISTRATOR_REVIEW && tsk.Status == Constants.COMPLETED && cs.Is_Lease_Variation_Required__c == 'Yes')
                        finalMilestone = Constants.CASE_MILESTONE_RETAIL_ADMIN_REVIEW_COMPLETED;
                    
                    if(tsk.TaskType__c == Constants.TASKTEMPLATE_ACCEPT_OFFER_LETTER && tsk.Status == Constants.COMPLETED)
                        finalMilestone = Constants.CASE_MILESTONE_OFFER_LETTER_ACCEPTED;
                }
            
            if(cs.Status == 'Pending Approval')
                finalMilestone = 'Pending Internal Approval';
            if(cs.Status == 'Approved')
                finalMilestone = 'Internal Approval Granted';
            if(cs.Status == 'Rejected')
                finalMilestone = 'Internal Approval Rejected';
            
            if(finalMilestone == NULL || finalMilestone == '')
                finalMilestone = 'Case Initiated';
            
            cs.Milestone__c = finalMilestone;
            
            casesToUpdate.add(cs);
        }
        
        Database.update(casesToUpdate, FALSE);
    }    
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}