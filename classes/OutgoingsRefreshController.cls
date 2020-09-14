public class OutgoingsRefreshController {
    public class OppLineItemUpdatesWrapper{
        public List<OpportunityLineItem> oppLineItemForInsertList;
        public List<OpportunityLineItem> oppLineItemForDeleteList;
        public List<OpportunityLineItem> oppLineItemForUpdateList;
    }
    
    @AuraEnabled
    public static LightningResponse getOpportunities(Id propertyId){
        LightningResponse res = new LightningResponse();
        Set<String> spacetype;
        Set<String> stageNameSet;
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Opportunity> filteredOpptyList = new List<Opportunity>();
        
        stageNameSet = new Set<String>{
            Constants.UNDERSTAND_NEGOTIATE,
            Constants.APPROVE,
            Constants.PROPOSE_ACCEPT,
            Constants.OPPORTUNITYSTAGE_ISSUE_LEASE // RPP - 10813
        };

        spacetype = new Set<String>{
            Constants.SHOP,
            Constants.SPACETYPEKIOSK
        };

        Set<String> approvalStatus = new Set<String>{ // RPP - 10869
            Constants.FINALAPPR_GRANT,
            Constants.PEND_FINALAPPROV
        };
        
        try{
            opportunityList = [SELECT Id, Name, ProposedRentCommencementDate__c, CreatedBy.Profile.Name, SpecialityLeaseType__c,
                                    (SELECT Id, TaskType__c, Status
                                        FROM Tasks
                                        WHERE TaskType__c =: Constants.TASK_TYPE_INSTRUCT_SOLICITOR
                                        AND Status =: Constants.COMPLETED), // RPP - 10813 - Added tasks inner query to check id Instruct solicitor is completed.
                                    (SELECT Id, OpportunityId 
                                        FROM OpportunityLineItems
                                        WHERE Product2.ProductCode =: Constants.OTG
                                        AND ProductFamily__c =: Constants.RECOVERIES) // RPP - 10813 - Added OLI query to check if there are any OTGs to refresh to.
                                FROM Opportunity 
                                WHERE Property__c =: propertyId
                                AND ProposedRentCommencementDate__c != null
                                AND Tech_SpaceType__c IN: spacetype
                                AND (TechByPassOnClone__c = FALSE
                                    OR (TechByPassOnClone__c = TRUE
                                        AND ApprovalStatus__c NOT IN: approvalStatus
                                        AND SpecialityLeaseType__c != null
                                    ) // RPP - 10869
                                )
                                AND JDESentStatus__c = null // RPP - 10869
                                AND StageName IN: stageNameSet];
            
            for(Opportunity oppty : opportunityList){
                Boolean isInstructSolicitorPassed = false;
                if(oppty.Tasks != null
                    && oppty.Tasks.size() > 0){
                    isInstructSolicitorPassed = true;
                }
                if(oppty.OpportunityLineItems != null
                    && oppty.OpportunityLineItems.size() > 0
                    && !isInstructSolicitorPassed){ // RPP - 10813 - If there are OTGs present and Instruct Solicitor is not passed yet, oppty is eligible for refresh
                    filteredOpptyList.add(oppty);
                }
            }	
        } catch(Exception e){
            res.status = Constants.FAILED;
            res.message = 'ERROR : ' + e.getMessage();
        }

        try{
            res.returnValue = JSON.serialize(filteredOpptyList);
        } catch(Exception e){
            res.status = Constants.FAILED;
            res.message = 'ERROR : ' + e.getMessage();
        }
        
        return res;
    }
    
    @AuraEnabled
    public static Id refreshOutgoings(String opportunityListJSON){
        Id batchId;
        LightningResponse res = new LightningResponse();
        Set<Id> opportunityIdSet = new Set<Id>();
        List<Opportunity> opportunityList;
        
        opportunityList = (List<Opportunity>) JSON.deserialize(opportunityListJSON, List<Opportunity>.class);
        
        for(Opportunity opp : opportunityList){
            opportunityIdSet.add(opp.Id);
        }
        
        OutgoingsRefreshBatch refreshBatch = new OutgoingsRefreshBatch(opportunityIdSet);
        batchId = Database.executeBatch(refreshBatch);
        
        return batchId;
    }
    
    @AuraEnabled
    public static Boolean isBatchComplete(Id batchId){
        Boolean isComplete = false;
        AsyncApexJob apexJob;
        Set<String> jobStatus;
        
        jobStatus = new Set<String>{
            'Aborted',
            'Completed',
            'Failed'
        };
        
        apexJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                   FROM AsyncApexJob 
                   WHERE Id =: batchId];
                   
        if(jobStatus.contains(apexJob.Status)){
            isComplete = true;
        }
        
        return isComplete;
    }
    
    @AuraEnabled
    public static Map<Id, List<OpportunityLineItem>> refreshOpportunityLineItem(List<Opportunity> opportunityList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OutgoingsRefreshController.class.getName());
        Integer counter = 0;
        OpportunityLineItem oppLineItemTemp;
        OppLineItemUpdatesWrapper oppLineItemUpdateWrap = new OppLineItemUpdatesWrapper();
        List<Id> opportunityIdList = new List<Id>();
        List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();
        Set<Id> oppLiIdSetToRemove = new Set<Id>();
        
        for(Opportunity opp : opportunityList){
            opportunityIdList.add(opp.Id);
        }
        
        List<Id> errorInsertIdLst = new List<Id>();
        Map<Id, List<OpportunityLineItem>> successOliUpdateByOppIdMap = new Map<Id, List<OpportunityLineItem>>();
        
        newOppLineItemList = OpportunityLineItemController.AddOutgoings(opportunityIdList);
        oppLineItemUpdateWrap = filterOppLineItemForRefresh(opportunityList, newOppLineItemList);
        
        List<Database.SaveResult> sResultList;
        if(oppLineItemUpdateWrap != null){
            if(oppLineItemUpdateWrap.oppLineItemForUpdateList != null && oppLineItemUpdateWrap.oppLineItemForUpdateList.size() > 0){
                TriggerHandler.bypass(OpportunityTriggerHandler.class.getName());
                TriggerHandler.bypass(OpportunityLineItemTriggerHandler.class.getName());
                
                sResultList = Database.update(oppLineItemUpdateWrap.oppLineItemForUpdateList, false);
                
                counter = 0;
                for(Database.SaveResult sResult : sResultList){
                    oppLineItemTemp = oppLineItemUpdateWrap.oppLineItemForUpdateList[counter];
                    if(!sResult.isSuccess()){
                        errorHandler.createError(sResult, oppLineItemTemp.Id);
                    } else {
                        if(successOliUpdateByOppIdMap.containsKey(oppLineItemTemp.OpportunityId)){
                            successOliUpdateByOppIdMap.get(oppLineItemTemp.OpportunityId).add(oppLineItemTemp);
                        } else {
                            successOliUpdateByOppIdMap.put(
                                oppLineItemTemp.OpportunityId, 
                                new List<OpportunityLineItem>{oppLineItemTemp}
                            );
                        }
                    }
                    counter++;
                }
            }  
        }

        errorHandler.createError('Successfully refreshed: Updated Line Items: ' + JSON.serialize(successOliUpdateByOppIdMap.keySet()), null);
        
        errorHandler.save();
        
        return successOliUpdateByOppIdMap;
    }
    
    public static OppLineItemUpdatesWrapper filterOppLineItemForRefresh(List<Opportunity> opportunityList, 
        List<OpportunityLineItem> newOppLineItemList){
        PriceBookEntry pbEntryTemp;
        OpportunityLineItem oldOppLineItemTemp;
        OppLineItemUpdatesWrapper oppLineItemUpdateWrap = new OppLineItemUpdatesWrapper();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> priceBookEntryIdSet = new Set<Id>();
        Map<Id, PriceBookEntry> priceBookEntryMap = new Map<Id, PriceBookEntry>();
        Map<Id, Map<String, OpportunityLineItem>> oppIdPBNameOppLineItemMapMap = new Map<Id, Map<String, OpportunityLineItem>>();
        
        oppLineItemUpdateWrap.oppLineItemForInsertList = new List<OpportunityLineItem>();
        oppLineItemUpdateWrap.oppLineItemForDeleteList = new List<OpportunityLineItem>();
        oppLineItemUpdateWrap.oppLineItemForUpdateList = new List<OpportunityLineItem>();
        
        for(Opportunity opp : opportunityList){
            opportunityIdSet.add(opp.Id);
        }
        
        oppIdPBNameOppLineItemMapMap = getOpportunityLineItem(opportunityIdSet);
        
        for(OpportunityLineItem oppLine : newOppLineItemList){
            priceBookEntryIdSet.add(oppLine.PriceBookEntryId);
        }
        
        priceBookEntryMap = new Map<Id, PriceBookEntry>(
            [SELECT Id, Name 
             FROM PriceBookEntry 
             WHERE Id IN: priceBookEntryIdSet]
        );
        
        for(OpportunityLineItem newOppLine : newOppLineItemList){
            if(priceBookEntryMap.containsKey(newOppLine.PriceBookEntryId)){
                pbEntryTemp = priceBookEntryMap.get(newOppLine.PriceBookEntryId);
            }
            
            if(oppIdPBNameOppLineItemMapMap.containsKey(newOppLine.OpportunityId) 
                && oppIdPBNameOppLineItemMapMap.get(newOppLine.OpportunityId).containsKey(pbEntryTemp.Name)){
                oldOppLineItemTemp = oppIdPBNameOppLineItemMapMap.get(newOppLine.OpportunityId).get(pbEntryTemp.Name);
                
                Decimal newQuantity = newOppLine.Quantity; // RPP - 10813
                Decimal newApplicableArea = newOppLine.ApplicableArea__c; // RPP - 10813

                newOppLine.Quantity = oldOppLineItemTemp.Quantity;
                newOppLine.ApplicableArea__c = oldOppLineItemTemp.ApplicableArea__c;
                
                oppLineItemUpdateWrap.oppLineItemForInsertList.add(newOppLine);
                oppLineItemUpdateWrap.oppLineItemForDeleteList.add(oldOppLineItemTemp);
                
                oldOppLineItemTemp.UnitPrice = newOppLine.UnitPrice;
                oldOppLineItemTemp.Quantity = newQuantity; // RPP - 10813
                oldOppLineItemTemp.ApplicableArea__c = newApplicableArea; // RPP - 10813
                oppLineItemUpdateWrap.oppLineItemForUpdateList.add(oldOppLineItemTemp);
            }
        }
        
        system.debug('priceBookEntryMap : ' + priceBookEntryMap);
        system.debug('oppLineItemUpdateWrap : ' + oppLineItemUpdateWrap);
        system.debug('oppIdPBNameOppLineItemMapMap : ' + oppIdPBNameOppLineItemMapMap);
        
        return oppLineItemUpdateWrap;
    }
    
    private static Map<Id, Map<String, OpportunityLineItem>> getOpportunityLineItem(Set<Id> opportunityIdSet){
        Map<Id, Map<String, OpportunityLineItem>> oppIdPBNameOppLineItemMapMap = new Map<Id, Map<String, OpportunityLineItem>>();
        
        for(OpportunityLineItem oppLine : [SELECT Id, Name, OpportunityId, PriceBookEntry.Name, ApplicableArea__c, Quantity,
                                           PriceBookEntryId
                                           FROM OpportunityLineItem 
                                           WHERE OpportunityId IN: opportunityIdSet 
                                                AND Product2.ProductCode =: Constants.OTG]){
            if(oppIdPBNameOppLineItemMapMap.containsKey(oppLine.OpportunityId)){
                oppIdPBNameOppLineItemMapMap.get(oppLine.OpportunityId).put(oppLine.PriceBookEntry.Name, oppLine);
            } else {
                oppIdPBNameOppLineItemMapMap.put(
                    oppLine.OpportunityId, 
                    new Map<String, OpportunityLineItem>{
                        oppLine.PriceBookEntry.Name => oppLine
                    }
                );
            }
        }
        
        return oppIdPBNameOppLineItemMapMap;
    }
}