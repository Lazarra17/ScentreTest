/**
@author: Abhishek M.
@desc: This class is responsible for reversing the Opportunity to its previous state when Reverse Opportunity checkbox is checked
**/
public class OpportunityReversal {
    public static ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityReversal.class.getName());
    public static Boolean opptyReversed = FALSE;
    public static List<Task> tasksToUpdate = new List<Task>();
    public static Boolean oppCheck = FALSE;
    public static Response res = new Response();
    public static Boolean isError = FALSE;
    
    public class Response{
        @AuraEnabled
        public String errorMsg;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String errortype;
        
        public Response(){
            this.errorMsg = '';
            this.status = CONSTANTS.SUCCESS;
            this.Errortype = '';
        }
    }
    
    //create Task once Opportunity is reversed.
    public static void createTaskOnnewOpptyReversal(Opportunity newOpp){
        Task dealTermsTask = new Task();
        try{

            dealTermsTask.WhatId = newOpp.Id;
            dealTermsTask.Subject = 'Update Deal Terms and Resubmit for Approval';
            dealTermsTask.Description = 'Update Deal Terms and Resubmit for Approval';
            dealTermsTask.ActivityDate = System.today();
            
            if(newOpp.ApprovalStatus__c == Constants.INI_APPV_REJ)
                dealTermsTask.OwnerId = newOpp.OwnerId;
            else if(newOpp.ApprovalStatus__c == Constants.FINALAPPR_REJ){
                if(newOpp.RMRetailAdmin__c != NULL)
                    dealTermsTask.OwnerId = newOpp.RMRetailAdmin__c;
                else
                    dealTermsTask.OwnerId = newOpp.OwnerId;
            }
        }catch(Exception e){
            errorHandler.createError(e);
        }

        insert dealTermsTask;
    }

    @AuraEnabled
    public static Response reverseOpportunity(Id newOppId){
		Response res = new Response();
        
        
        Opportunity newOpp = [SELECT Id, Type, LatestCompletedMilestone__c, RMRetailAdmin__c, OwnerId, Name, StageName, ApprovalStatus__c, DealAchieved__c, DealAchievedDate__c, Reverse_Opportunity__c,
                              	(SELECT Id, Status, Subject, TaskType__c 
                               	FROM Tasks WHERE Status != 'Completed' AND Status != 'Cancelled')
                               FROM Opportunity WHERE Id =: newOppId];

        if(newOpp.Tasks.size() > 0){
            for(Task tsk : newOpp.Tasks){
                if(tsk.TaskType__c == Constants.TASK_TYPE_INSTRUCT_SOLICITOR && tsk.Status == Constants.COMPLETED){
                    res.status = Constants.FAILED;
                    res.errortype = 'IsISTask';
                    res.errorMsg = 'Instruct Solicitor task is completed. Opportunity cannot be reversed.';
                    return res;
                }
            }
        }
        
        if(newOpp.LatestCompletedMilestone__c == 'Accept Disclosure Statement' || 
          newOpp.LatestCompletedMilestone__c == 'Update Cost Estimate' ||
           newOpp.LatestCompletedMilestone__c == 'Submit for Final Approval'){
               res.status = Constants.FAILED;
               res.errortype = 'ISADSTask';
               res.errorMsg = 'Opportunity cannot be reversed.';
               return res;
           }        

        try{
            if(Constants.INIAPPR_GRANTED.equals(newOpp.ApprovalStatus__c)){
                newOpp.ApprovalStatus__c = Constants.INI_APPV_REJ;
                oppCheck = TRUE;
            }
            else if(Constants.FINALAPPR_GRANT.equals(newOpp.ApprovalStatus__c)){
                newOpp.ApprovalStatus__c = Constants.FINALAPPR_REJ;
                oppCheck = TRUE;
            }
           
            if(Constants.PROPOSE_ACCEPT.equals(newOpp.StageName)){
                newOpp.StageName = Constants.APPROVE;
                oppCheck = TRUE;
            }
            else if(Constants.OPPORTUNITYSTAGE_ISSUE_LEASE.equals(newOpp.StageName)){
                newOpp.StageName = Constants.PROPOSE_ACCEPT;
                oppCheck = TRUE;
            }
           
            if(newOpp.ApprovalStatus__c == Constants.FINALAPPR_REJ && (newOpp.DealAchieved__c || newOpp.DealAchievedDate__c == NULL)){
                newOpp.DealAchieved__c = FALSE;
                newOpp.DealAchievedDate__c = NULL;
                oppCheck = TRUE;
            }
            
            newOpp = cancelTasks(newOpp);
            if(isError == TRUE){
                res.status = Constants.FAILED;
                res.errortype = 'IsJVTask';
                res.errorMsg = 'JV Approval is pending, Opportunity cannot be reversed.';
                return res;
            }
            
            //return TRUE if any of the above statements meets the criteria 
            if(oppCheck == TRUE){
                newOpp.Reverse_Opportunity__c = FALSE;
                opptyReversed = TRUE;
                Database.update(newOpp);
                if(tasksToUpdate.size() > 0)
                    Database.update(tasksToUpdate, FALSE);
                createTaskOnnewOpptyReversal(newOpp);
            }
            return res;
        }catch(Exception e){
            res.status = Constants.FAILED;
            res.errortype = 'unHandeled';
            res.errorMsg = e.getMessage();
            errorHandler.createError(e);
            return res;
        }
    }
    
    @AuraEnabled
    public static Opportunity getOppty(Id opptyId){
        Opportunity opp = [SELECT Id, Name, StageName, ApprovalStatus__c, LatestCompletedMilestone__c FROM Opportunity WHERE Id =: opptyId];
        return opp;
    }
    
    @testVisible
    private static Opportunity cancelTasks(Opportunity newOpp){
        if(newOpp.LatestCompletedMilestone__c == Constants.INITIAL_APPROVAL){
            oppCheck = TRUE;
            newOpp.LatestCompletedMilestone__c = '';
            for(Task tsk : newOpp.Tasks){
                if(tsk.TaskType__c == Constants.SEND_DISCLOSURE_STATEMENT || tsk.TaskType__c == Constants.PRE_DS_REAA_APPROVAL){
                    tsk.Status = 'Cancelled';
                    tasksToUpdate.add(tsk);
                }
            }
        }else if(newOpp.LatestCompletedMilestone__c == Constants.Opp_Send_DISCLOSURE_STATEMENT){
            oppCheck = TRUE;
            newOpp.LatestCompletedMilestone__c = '';
            for(Task tsk : newOpp.Tasks){
                if(tsk.TaskType__c == Constants.RECEIVE_DISCLOSURE_STATEMENT || tsk.TaskType__c == Constants.PRE_DS_REAA_APPROVAL){
                    tsk.Status = 'Cancelled';
                    tasksToUpdate.add(tsk);
                }
            }
        }else if(newOpp.LatestCompletedMilestone__c == Constants.Opp_RECEIVE_DISCLOSURE_STATEMENT){
            oppCheck = TRUE;
            newOpp.LatestCompletedMilestone__c = '';
            for(Task tsk : newOpp.Tasks){
                if(tsk.TaskType__c == Constants.PREPARE_COUNTER_OFFER_API || 
                   tsk.TaskType__c == Constants.UPDATE_DEAL_TERMS || 
                   tsk.TaskType__c == Constants.ACCEPT_DISCLOSURE_STATEMENT_API || 
                   tsk.TaskType__c == Constants.PRE_DS_REAA_APPROVAL){
                    tsk.Status = 'Cancelled';
                    tasksToUpdate.add(tsk);
                }
            }
        }
        else if(newOpp.LatestCompletedMilestone__c == Constants.DEAL_ACHIEVED){
            for(Task tsk : newOpp.Tasks){
                if(tsk.TaskType__c == Constants.JV_APPROVAL && (tsk.Status != 'Completed' && tsk.Status != 'Cancelled')){
                    isError = TRUE;
                    return NULL;
                }
            }
            
            oppCheck = TRUE;
            newOpp.StageName = Constants.PROPOSE_ACCEPT;
            newOpp.DealAchieved__c = FALSE;
            newOpp.DealAchievedDate__c = NULL;
            
            if(newOpp.Type == Constants.OPPTY_STAGENAME_NEWRETAILER)
                newOpp.LatestCompletedMilestone__c = Constants.Opp_UPDATE_COST_ESTIMATE;
            else if(newOpp.Type == Constants.OPPTY_STAGENAME_NEWLEASE)
                newOpp.LatestCompletedMilestone__c = Constants.Opp_ACCEPT_DISCLOSURE_STATEMENT;
            
            for(Task tsk : newOpp.Tasks){
                /*if(tsk.TaskType__c == Constants.GENERATE_ACCEPTANCE || 
                   tsk.TaskType__c == Constants.SEND_ACCEPTANCE || 
                   tsk.TaskType__c == Constants.INSTRUCT_SOLICITOR || 
                   tsk.TaskType__c == Constants.GENERATE_SUBMIT_JV_APPROVAL || 
                   tsk.TaskType__c == Constants.JV_APPROVAL ||
                   tsk.TaskType__c == Constants.PRE_DS_REAA_APPROVAL){*/
                if((tsk.Status != 'Completed' && tsk.Status != 'Cancelled')){
                   tsk.Status = 'Cancelled';
                   tasksToUpdate.add(tsk); 
                }
                //}
            }
        }
        
        return newOpp;
    }
}