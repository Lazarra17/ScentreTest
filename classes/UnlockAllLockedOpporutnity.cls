global class UnlockAllLockedOpporutnity implements Database.Batchable<sObject>{
   global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id 
                                         FROM Opportunity
                                         WHERE IsClosed = false
                                         AND RecordType.DeveloperName !=: Constants.OPP_STORE_ROOM_LEASING_API_NAME]); // RPP - 10840 - Added closed and record type check
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> OppUnlock){
        List<Opportunity> oppToUnlockList = new List<Opportunity>();
        
        for(Opportunity UnlockOpp : OppUnlock){
            if(Approval.islocked(UnlockOpp.Id)){
            	oppToUnlockList.add(UnlockOpp);
            }
        }
        Approval.unlock(oppToUnlockList);
    }
    global void finish(Database.BatchableContext BC){
        
    }
}