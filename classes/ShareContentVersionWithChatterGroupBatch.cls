global class ShareContentVersionWithChatterGroupBatch implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, contentdocumentId, DocumentType__c from ContentVersion where DocumentType__c='Lease Plan' or DocumentType__c='Sketch Plan']);
    }
    global void execute(Database.BatchableContext BC, List<ContentVersion> ConVerList){
        update ConVerList;
    }
    global void finish(Database.BatchableContext BC){
        
    }
}