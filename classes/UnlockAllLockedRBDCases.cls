global class UnlockAllLockedRBDCases implements Database.Batchable<sObject>{
   global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id,Type FROM Case WHERE Type='Retail Design Billing']);
    }
    global void execute(Database.BatchableContext BC, List<Case> CasesRDB){
        List<Case> casesToUnlock = new List<Case>();
        for(Case RDBcase : CasesRDB){
            if(Approval.islocked(RDBcase.Id)){
             casesToUnlock.add(RDBcase);
            }
        }
        Approval.unlock(casesToUnlock);
    }
    global void finish(Database.BatchableContext BC){
        
    }
}