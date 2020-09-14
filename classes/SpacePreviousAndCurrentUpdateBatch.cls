/**
* @author:     Kyle Tan
* @desc:       batch class that updates the current retailer and previous tenant of the space
**/
global class SpacePreviousAndCurrentUpdateBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        //date d = system.today().addDays(1); //added as changes for RPP-10741
        return Database.getQueryLocator([SELECT Id, Account__c, LeaseStatus__c, Opportunity__r.ActualShopOpenedDate__c, 
                                         Account__r.Name, LeaseStartDate__c, Space__c, ActualVacateDate__c, 
                                         Opportunity__r.TradeFlag__c, Opportunity__r.TechTradeFlagChangedDate__c 
                                         FROM Contract__c
                                         WHERE Opportunity__r.TradeFlag__c = true 
                                           AND Opportunity__r.TechTradeFlagChangedDate__c =: date.today()
                                         ]);
        
//This is a backup before implementing RPP-11035 
        /*WHERE (Opportunity__r.TradeFlag__c = true AND Opportunity__r.ActualShopOpenedDate__c <= :d 
AND ((Opportunity__r.TechTradeFlagChangedDate__c = :date.today())
OR Tech_ActualVacateModifiedDate__c = :date.today()
OR CreatedDate =:date.today()
OR TechStatusChanged__c = true))]);*/
    }
    global void execute(SchedulableContext sc){
        SpacePreviousAndCurrentUpdateBatch schedulableBatch = new SpacePreviousAndCurrentUpdateBatch();
        Database.executeBatch(schedulableBatch);
    }
    global void execute(Database.BatchableContext bc, List<Contract__c> contractList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpacePreviousAndCurrentUpdateBatch.class.getName());
        List<Space__c> spaceToUpdateList = new List<Space__c>();
        TriggerHandler.bypass('SpaceTriggerHandler');
        spaceToUpdateList = SpaceBL.updateCurrentAndPreviousTenant(contractList);
        if(spaceToUpdateList != null && spaceToUpdateList.size() > 0) {
            List<Database.SaveResult> saveResultList = Database.update(spaceToUpdateList, false);
            Integer counter = 0;
            for(Database.SaveResult saveResult : saveResultList){
                counter++;
                if(!saveResult.isSuccess()) {
                    for(Database.Error error : saveResult.getErrors()) {
                        errorHandler.createError(error, spaceToUpdateList[counter].Id);
                    }
                }
            }
        }
        List<Contract__c> untickBox = [Select Id, TechStatusChanged__c From Contract__c Where TechStatusChanged__c = True];
        if (untickBox.size() > 0) {
            for (Contract__c contract : untickBox) {
                contract.TechStatusChanged__c = false;
            }
            try{
                Database.update(untickBox);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
    global void finish(Database.BatchableContext bc){
    }
}