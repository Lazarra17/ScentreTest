global class NewLeaseStatusUpdateBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
	global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([select id, TechNewLeaseSentDate__c, ProposedStartDate__c, JDESentStatus__c, TechReadyForBatch__c, type from Opportunity where TechNewLeaseSentDate__c <= Today and type =: Constants.OPPTY_STAGENAME_NEWLEASE and TechReadyForBatch__c = TRUE and JDESentStatus__c = '']);
    }
    
    global void execute(SchedulableContext sc){
        NewLeaseStatusUpdateBatch schedulableBatch = new NewLeaseStatusUpdateBatch();
        Database.executeBatch(schedulableBatch);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> oppoList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(NewLeaseStatusUpdateBatch.class.getName());
        List<Opportunity> updateOppoList = new List<Opportunity>();
        for (Opportunity oppo : oppoList) {
            oppo.JDESentStatus__c = Constants.OPPO_JDE_STATUS_READY;
            updateOppoList.add(oppo);
        }
        List<Database.SaveResult> saveResultList = Database.update(updateOppoList, false);
        Integer counter = 0;
        for(Database.SaveResult saveResult : saveResultList){
            for(Database.Error err : saveResult.getErrors()) {
                errorHandler.createError(String.valueOf(err));
                System.debug('ERROR IN NewLeaseStatusUpdateBatch: '+ err);
            }
        }                
        errorHandler.save();
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}