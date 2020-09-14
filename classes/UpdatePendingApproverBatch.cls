global class UpdatePendingApproverBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id FROM Opportunity WHERE Pending_Approver__c=null AND (ApprovalStatus__c='Pending Initial Approval' OR ApprovalStatus__c='Pending Risk Approval' OR ApprovalStatus__c='Pending Final Approval' OR ApprovalStatus__c='Pending Licence Approval')]);
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> oppList){
        for(Opportunity op1:oppList){
            NextApprover.getNextApprover(op1.id);  
        }    
    }
    global void finish(Database.BatchableContext BC){
        
    }

}