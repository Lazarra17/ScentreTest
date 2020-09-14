/*------------------------------------------------------------------------------------
Author:      Aakash Soor
Company:     Arxxus Technology Partners
Description: This batch class is responsible for creating budget records for child spaces
Test Class:  
History
Date            Author             Comments
--------------------------------------------------------------------------------------
04-12-2019      Aakash Soor        Initial Release
--------------------------------------------------------------------------------------*/
global without sharing class SpaceManagementBatch implements Database.Batchable<sObject>, Database.Stateful{

    public Set<Id> processedSpaceIds = new Set<Id>();
    public static SpaceManagementBatchHelper helper = new SpaceManagementBatchHelper();
    public static Map<String,String> budgetFieldApiNameVsModelType = new Map<String,String>();
    public static Map<String,Schema.SObjectField> spaceObjectSchema = Schema.SObjectType.Space__c.fields.getMap();

    global SpaceManagementBatch(){}
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Space__c, Space__r.Active__c, Space__r.Relationship__c, EffectiveDate__c,ModelType__c,
                                                Space__r.No_Of_Space_Groups__c
                                         FROM SpaceBudgetAndForecast__c 
                                         WHERE Space__r.Active__c = true
                                         AND Space__r.Relationship__c !=: Constants.SPACE_REL_CHILD
                                         AND Batch_Process_Status__c IN ('New','Pending')
                                         ORDER BY EffectiveDate__c,CreatedDate DESC]);   
    }

    global void execute(Database.BatchableContext BC, List<SpaceBudgetAndForecast__c> spaceBudgetList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceManagementBatch.class.getName());
        Map<Id,Space__c> spacesToUpdate = new Map<Id,Space__c>();
        Map<Id,SpaceBudgetAndForecast__c> statusUpdateSpaceBudgets = new Map<Id,SpaceBudgetAndForecast__c>();
        Set<Id> parentSpaceIds;
        List<SpaceBudgetAndForecast__c> childSpaceBudgetToInsert = new List<SpaceBudgetAndForecast__c>();
        List<SpaceBudgetAndForecast__c> spaceBudgetForLinking = new List<SpaceBudgetAndForecast__c>();

        for(SpaceBudgetFieldModelType__mdt sbfm : [SELECT MasterLabel, Space_Budget_Field_API_Name__c
                                                    FROM SpaceBudgetFieldModelType__mdt
                                                    WHERE Active__c = true]){
            budgetFieldApiNameVsModelType.put(sbfm.Space_Budget_Field_API_Name__c, sbfm.MasterLabel);
        }
        
        Map<String, List<SpaceBudgetAndForecast__c>> spaceBudgetMap =  helper.updateSpaceBudgetBatchStatus(spaceBudgetList);
        
        try{
            update spaceBudgetMap.get('All');
            if(!spaceBudgetMap.get('NotProcessed').isEmpty()) spaceBudgetForLinking = spaceBudgetMap.get('NotProcessed');

            if(!spaceBudgetMap.get('Pending').isEmpty()){

                String query = helper.getQuery();

                parentSpaceIds = helper.getParentSpaceIds(spaceBudgetMap.get('Pending'), processedSpaceIds);
                processedSpaceIds.addAll(parentSpaceIds);
                List<Space__c> parentSpaces = Database.Query(query);

                Map<Decimal, SpaceManagementController.SpaceBudgetWrapper> sbWrappers = helper.prepareSpaceBudgetWrapper(parentSpaces, budgetFieldApiNameVsModelType);

                for(SpaceManagementController.SpaceBudgetWrapper sbWrapper : sbWrappers.values()){
                    childSpaceBudgetToInsert.addAll(SpaceManagementController.createSpaceBudget(sbWrapper));
                    spacesToUpdate.putAll(sbWrapper.parentSpaces);
                }

                List<Database.SaveResult> saveResults = Database.insert(childSpaceBudgetToInsert,false);
                Integer count = 0;
                Set<Id> processedParentSpaceIds = new Set<Id>();
                for(Database.SaveResult saveResult : saveResults){    
                    if(!saveResult.isSuccess()){
                        for(SpaceManagementController.SpaceBudgetWrapper sbWrapper : sbWrappers.values()){
                            if(sbWrapper.childSpaces.containsKey(childSpaceBudgetToInsert[count].Space__c)){
                                for(SpaceBudgetAndForecast__c sbf : sbWrapper.spaceBudgetMap.values()){
                                    sbf.Batch_Process_Status__c = 'Failed';
                                    sbf.Batch_Process_Status_Reason__c = JSON.serialize(saveResult.getErrors()).left(255);
                                    if(!statusUpdateSpaceBudgets.containsKey(sbf.Id)) statusUpdateSpaceBudgets.put(sbf.Id,sbf);
                                    processedParentSpaceIds.add(sbf.Space__c);
                                }
                                break;
                            }
                        }
                    }else{
                        Set<Id> parentSpaceIdTemp = new Set<Id>(processedParentSpaceIds);
                        for(SpaceManagementController.SpaceBudgetWrapper sbWrapper : sbWrappers.values()){
                            parentSpaceIdTemp.retainAll(sbWrapper.parentSpaces.keySet());
                            if(parentSpaceIdTemp.isEmpty()
                                && sbWrapper.childSpaces.containsKey(childSpaceBudgetToInsert[count].Space__c)){
                                for(SpaceBudgetAndForecast__c sbf : sbWrapper.spaceBudgetMap.values()){
                                    if(!statusUpdateSpaceBudgets.containsKey(sbf.Id)){
                                        sbf.Batch_Process_Status__c = 'Success';
                                        statusUpdateSpaceBudgets.put(sbf.Id,sbf);
                                    }
                                }
                                break;
                            }
                        }
                    }    
                    count++;
                }
            }
			
            spaceBudgetForLinking.addAll(childSpaceBudgetToInsert);
            spacesToUpdate.putAll(helper.updateSpaceWithLatestBudget(spaceBudgetForLinking, budgetFieldApiNameVsModelType, spaceObjectSchema));

            TriggerHandler.bypass('SpaceTriggerHandler');
            if(!spacesToUpdate.isEmpty()) update spacesToUpdate.values();
            if(!statusUpdateSpaceBudgets.isEmpty()) update statusUpdateSpaceBudgets.values();
        }catch(Exception e){
            system.debug('Exception------'+e.getLineNumber()+'--------'+e.getStackTraceString());
            errorHandler.createError(e);
        }

        errorHandler.save();
    }
    
    global void finish(Database.BatchableContext BC){}
}