/*------------------------------------------------------------------------------------
Author:      Aakash Soor
Company:     Arxxus Technology Partners
Description: This is a helper class for SpaceManagementBatch Class
Test Class:  
History
Date            Author             Comments
--------------------------------------------------------------------------------------
04-12-2019      Aakash Soor        Initial Release
--------------------------------------------------------------------------------------*/
public without sharing class SpaceManagementBatchHelper{

    public Set<Id> getParentSpaceIds(List<SpaceBudgetAndForecast__c> spaceBudgets, Set<Id> processedSpaceIds){
        Set<Id> parentSpaceIds = new Set<Id>();

        for(SpaceBudgetAndForecast__c sbf : spaceBudgets){
            if(sbf.Space__c != null
                && !processedSpaceIds.contains(sbf.Space__c)) 
            parentSpaceIds.add(sbf.Space__c);
        }
        return parentSpaceIds;
    }

    public String getQuery(){
        Set<String> spaceFieldsToQuery = new Set<String>();
        Set<String> spaceBudgetFieldsToQuery = new Set<String>();
        Set<String> spaceGroupFieldsToQuery = new Set<String>();

        spaceFieldsToQuery.add('Id');
        spaceFieldsToQuery.add('Name');
        spaceFieldsToQuery.addAll(new Set<String>(Label.SpaceReconfig_BudgetToSplit.split(Constants.SEMICOLON)));
        spaceFieldsToQuery.add('Type__c');
        spaceFieldsToQuery.add('Property__c');
        spaceFieldsToQuery.add('Property__r.JDEPropertyNumber__c');
        spaceFieldsToQuery.add('RentableArea__c');
        spaceFieldsToQuery.add('CurrencyIsoCode');
        spaceFieldsToQuery.add('No_Of_Space_Groups__c');
        spaceFieldsToQuery.add('Status__c'); 
        spaceFieldsToQuery.add('Active__c'); 

        spaceBudgetFieldsToQuery.add('Id');
        spaceBudgetFieldsToQuery.addAll(new Set<String>(Label.SpaceReconfig_BudgetSplitFields.split(Constants.SEMICOLON)));
        spaceBudgetFieldsToQuery.add('ModelType__c');
        spaceBudgetFieldsToQuery.add('BudgetedDealType__c');
        spaceBudgetFieldsToQuery.add('EffectiveDate__c');

        spaceGroupFieldsToQuery.add('Id');
        spaceGroupFieldsToQuery.add('Active__c');
        spaceGroupFieldsToQuery.add('ChildSpace__c');
        spaceGroupFieldsToQuery.add('SpaceGroupNumber__c');

        String query = 'SELECT ' + String.join(new List<String>(spaceFieldsToQuery),',');
        query = query + ', (SELECT ' 
                        + String.join(new List<String>(getSpaceParentFields(spaceFieldsToQuery,'ChildSpace__r')),',')
                        + ','
                        + String.join(new List<String>(spaceGroupFieldsToQuery),',') 
                        +' FROM Space_Groups3__r)';
        query = query + ', (SELECT ' + String.join(new List<String>(spaceBudgetFieldsToQuery),',') +' FROM Space_Budget_and_Forecast__r WHERE Space__r.Active__c = true AND Space__r.Relationship__c = \''+ Constants.SPACE_REL_PARENT +'\' AND Batch_Process_Status__c IN (\'New\',\'Pending\') ORDER BY EffectiveDate__c,CreatedDate DESC)';
        query = query + ' FROM Space__c WHERE ID IN: parentSpaceIds';

        system.debug('query------------'+query);
        return query;
    }

    private Set<String> getSpaceParentFields(Set<String> spaceFieldsToQuery, String lookupAPIName) {
        Set<String> parentFields = new Set<String>();
        for(String field : new List<String>(spaceFieldsToQuery)){
            parentFields.add(lookupAPIName + '.' +field);
        }
        return parentFields;
    }

    public Map<String, List<SpaceBudgetAndForecast__c>> updateSpaceBudgetBatchStatus(List<SpaceBudgetAndForecast__c> spaceBudgetList){
        Map<String, List<SpaceBudgetAndForecast__c>> spaceBudgetMap = new Map<String, List<SpaceBudgetAndForecast__c>>{
                                                                                'Pending' => new List<SpaceBudgetAndForecast__c>(),
                                                                                'NotProcessed' => new List<SpaceBudgetAndForecast__c>(), 
                                                                                'All' => new List<SpaceBudgetAndForecast__c>()};
        for(SpaceBudgetAndForecast__c sbf : spaceBudgetList){
            if(sbf.Space__r.No_Of_Space_Groups__c > 0){
                sbf.Batch_Process_Status__c = 'Pending';
                spaceBudgetMap.get('Pending').add(sbf);
            }else{
                sbf.Batch_Process_Status__c = 'Not Processed';
                sbf.Batch_Process_Status_Reason__c = 'No Reconfiguration found.';
                spaceBudgetMap.get('NotProcessed').add(sbf); 
            }
            spaceBudgetMap.get('All').add(sbf);
        }
        return spaceBudgetMap;
    }

    public Map<Decimal, SpaceManagementController.SpaceBudgetWrapper> prepareSpaceBudgetWrapper(List<Space__c> parentSpaces, Map<String,String> budgetFieldApiNameVsModelType){
        Map<Decimal, SpaceManagementController.SpaceBudgetWrapper> sbWrappers = new Map<Decimal, SpaceManagementController.SpaceBudgetWrapper>();
        SpaceManagementController.SpaceBudgetWrapper sbWrapper;
        Map<Id,List<Space__c>> propertyVsSpaces = new Map<Id,List<Space__c>>();
        Map<String,Schema.SObjectField> spaceObjectSchema = Schema.SObjectType.Space__c.fields.getMap();
        Set<Decimal> invalidGroupNumbers = new Set<Decimal>(); 

        for(Space__c space : parentSpaces){
            system.debug('space.No_Of_Space_Groups__c-------------'+space.No_Of_Space_Groups__c);
            if(space.No_Of_Space_Groups__c > 0){
                Decimal groupNumber = 0;
                sbWrapper = new SpaceManagementController.SpaceBudgetWrapper();
                system.debug('space.Space_Groups3__r-------------'+space.Id+'----------'+space.Space_Groups3__r.size());
                for(SpaceGroup__c spaceGrp : space.Space_Groups3__r){
                    groupNumber = spaceGrp.SpaceGroupNumber__c;

                    if(!spaceGrp.Active__c
                        || !space.Active__c
                       	|| spaceGrp.ChildSpace__c == null
                        || !spaceGrp.ChildSpace__r.Active__c
                       	|| invalidGroupNumbers.contains(groupNumber)){
                        invalidGroupNumbers.add(groupNumber);
                        sbWrappers.remove(groupNumber);
                        continue;
                    }
                    if(sbWrappers.containsKey(groupNumber)){
                        sbWrapper = sbWrappers.get(groupNumber);
                    }
                    system.debug('spaceGrp.ChildSpace__r---------'+spaceGrp.ChildSpace__c+'------------'+spaceGrp.ChildSpace__r);
                    sbWrapper.childSpaces.put(spaceGrp.ChildSpace__c,spaceGrp.ChildSpace__r);
                }
				
                if(!invalidGroupNumbers.contains(groupNumber)){ 
                    sbWrapper.property = space.Property__r;
                    sbWrapper.property.Id = space.Property__c;
                    sbWrapper.parentSpaces.put(space.Id,space);
                    for(String budgetField : budgetFieldApiNameVsModelType.keySet()){
                        if(spaceObjectSchema.containsKey(budgetField)){
                            for(SpaceBudgetAndForecast__c sbf : space.Space_Budget_and_Forecast__r){
                                if(budgetFieldApiNameVsModelType.get(budgetField) == sbf.ModelType__c){
                                    space.put(budgetField,sbf.Id);
                                    sbWrapper.spaceBudgetMap.put(sbf.Id,sbf);
                                }
                            }
                        }
                    }
                    System.debug('sbWrapper---------------'+sbWrapper);
                    sbWrappers.put(groupNumber,sbWrapper);
                }
            }
            
        }
        return sbWrappers;
    }

    public Map<Id,Space__c> updateSpaceWithLatestBudget(List<SpaceBudgetAndForecast__c> spaceBudgetForLinking, 
                                                                Map<String,String> budgetFieldApiNameVsModelType, 
                                                                Map<String,Schema.SObjectField> spaceObjectSchema){
        Map<Id,Space__c> spacesToUpdate = new Map<Id,Space__c>();

        if(!spaceBudgetForLinking.isEmpty()){
            for(String budgetField : budgetFieldApiNameVsModelType.keySet()){
                if(spaceObjectSchema.containsKey(budgetField)){
                    for(SpaceBudgetAndForecast__c sbf : spaceBudgetForLinking){
                        if(budgetFieldApiNameVsModelType.get(budgetField) == sbf.ModelType__c
                          	&& sbf.Id != null){
                            if(spacesToUpdate.containsKey(sbf.Space__c)){
                                Space__c space = spacesToUpdate.get(sbf.Space__c);
                                space.put(budgetField,sbf.Id);
                                spacesToUpdate.put(space.id,space);
                            }else{
                                Space__c space = new Space__c();
                                space.Id = sbf.Space__c;
                                space.put(budgetField,sbf.Id);
                                spacesToUpdate.put(space.id,space);
                            }
                            
                        }
                    }
                }
            }
        }
        return spacesToUpdate;
    }

    @AuraEnabled
    public static string checkLatestBatchStatus(){

        List<AsyncApexJob> sMJobs = [SELECT Id, ApexClass.Name, NumberOfErrors, Status , CompletedDate
                                    FROM AsyncApexJob 
                                    WHERE JobType = 'BatchApex'
                                    AND ApexClass.Name = 'SpaceManagementBatch'
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];
        
        if(sMJobs.isEmpty()) return null;

        return JSON.serialize(sMJobs);
    } 

    @AuraEnabled
    public static string runSpaceManagementBatch(){

        SpaceManagementBatch spaceMagBatch = new SpaceManagementBatch();
        Id batchprocessid = Database.executeBatch(spaceMagBatch);

        AsyncApexJob sMJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CompletedDate 
                            FROM AsyncApexJob WHERE ID =: batchprocessid ];
        return JSON.serialize(sMJob);
    }
}