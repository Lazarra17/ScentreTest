/*
*       author: Miguel Paguio
*       created date: May 9, 2018
*       description: Batch class for SpaceOccupancyUpdateHelper
*       history: May 9, 2018 Miguel Paguio- Created
*
*/

global class SpaceOccupancyUpdateBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, CurrentLease__c,HeldVacantSpace__c, CurrentLeaseExpiryDate__c,  Status__c, OccupancyStatus__c, 
                                         LatestAchievedOpportunity__c, LatestAchievedOpportunity__r.Type, LatestForecast__c,
                                         CurrentForecastedOpportunity__r.CurrentLeaseVirtualVacancy__c,
                                         LatestBudget__r.PromotionalAllowance__c,
                                         LatestForecast__r.CapitalSiteEstablishment__c,
                                         CurrentLease__r.Opportunity__c
                                         FROM Space__c order by Property__c]);
    }
    
    global void execute(SchedulableContext sc){
        SpaceOccupancyUpdateBatch schedulableBatch = new SpaceOccupancyUpdateBatch();
        Database.executeBatch(schedulableBatch);
    }

    global void execute(Database.BatchableContext BC, List<Space__c> spaceList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceOccupancyUpdateBatch.class.getName());
        Set<Id> spaceidsSet = (new Map<Id,Space__c>(spaceList)).keySet();
        Map<Id,Space__c> spacemap= SpaceOccupancyUpdateHelper.updateOccupancyStatus(spaceidsSet ,spaceList,null);
        spaceList.clear();
        spaceList.addAll(spacemap.values());
        // bypass space trigger for batch run
        TriggerHandler.bypass('SpaceTriggerHandler');
        if(!spaceList.IsEmpty()){
            Integer counter = 0;
            List<Database.SaveResult> saveResultList = Database.update(spaceList, false);      
            for(Database.SaveResult saveResult : saveResultList){
                for(Database.Error err : saveResult.getErrors()) {
                    errorHandler.createError(err, spaceList[counter++].Id);
                }
            }
            errorHandler.save();
            system.debug('spaceList' + spaceList);
        }   
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}