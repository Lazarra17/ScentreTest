global class UpdatePrimaryContactFirstNameBatch implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name,PrimaryContact__r.FirstName, Tech_PrimaryContactFirstName__c FROM Opportunity where Stagename != \'Closed - Cancelled\' AND Account.Type != \'Forecast\' AND (PrimaryContact__r.FirstName != null OR PrimaryContact__r.FirstName != \'\')';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp : scope){
            opp.Tech_PrimaryContactFirstName__c = opp.PrimaryContact__r.FirstName;
            oppList.add(opp);
        }
        update oppList;
    }
    global void finish(Database.BatchableContext BC){}
}