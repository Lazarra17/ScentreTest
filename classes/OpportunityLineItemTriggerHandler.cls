/**
* Class OpportunityLineItemTriggerHandler
*
* Trigger Handler for the OpportunityLineItem SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class OpportunityLineItemTriggerHandler extends TriggerHandler
implements ITrigger {
    
    private List<Opportunity> opportunitiesToUpdateList = new List<Opportunity> ();
    private List<Opportunity> opportunitiesToUpdateListOutgoing = new List<Opportunity> ();
    private Set<Id> opportunityIds = new Set<Id>();
    // START : RPP-6061 YN 9.12.2018
    private List<OpportunityClause__c> newOpportunityClauseList = new List<OpportunityClause__c>();
    private Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    private Map<Id, List<OpportunityClause__c>> oppIdOppClauseListMap = new Map<Id, List<OpportunityClause__c>>();
    private Map<String, List<ClauseLibrary__c>> subTypeClauseLibraryListMap = new Map<String, List<ClauseLibrary__c>>();
    private Map<Id, List<OpportunityClause__c>> oppIdRentReviewOppClauseListMap = new Map<Id, List<OpportunityClause__c>>();
    private static Map<String,Schema.RecordTypeInfo> oppClauseRecordTypeByName = new Map<String,Schema.RecordTypeInfo>();
    // END : RPP-6061 YN 9.12.2018
    
    private List<OpportunityClause__c> oppClauseForDeleteList = new List<OpportunityClause__c>();
    private Map<Id, List<OpportunityLineItem>> oppIdRentReviewOppLineListMap = new Map<Id, List<OpportunityLineItem>>();
    private Map<Id,Opportunity> opportunityupdateMap=new Map<Id,Opportunity>();
    // Constructor
    public OpportunityLineItemTriggerHandler()
    {
        
    }
    
    /**
* bulkBefore
*
* This method is called prior to execution of a BEFORE trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    
    public void bulkBefore()
    {
        oppClauseRecordTypeByName = RecordTypeUtil.getAllRecordTypesByName('OpportunityClause__c'); // START-END : RPP-6061 YN 9.12.2018
        
        if(Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> opportunityIdSet = new Set<Id>();
            for(OpportunityLineItem newOppLineItem : (List<OpportunityLineItem>) Trigger.new){
                opportunityIdSet.add(newOppLineItem.OpportunityId);
            }
            opportunityMap = DatabaseSOQLBank.getOpportunityMap(opportunityIdSet);
        }
        if(Trigger.isInsert) {
            
        }
        
        if(Trigger.isUpdate) {
            
        }
    }
    
    public void bulkAfter(){
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        
        if(Trigger.isInsert || Trigger.isUpdate){
            Set<Id> opportunityIdSet = new Set<Id>();
            Set<String> cLibrarySubTypeSet = new Set<String>{
                Constants.PRODUCT_RENT_REVIEW
                    };
                        
                        for(OpportunityLineItem newOppLineItem : (List<OpportunityLineItem>) Trigger.new){
                            opportunityIdSet.add(newOppLineItem.OpportunityId);
                        }
            
            if(Trigger.isInsert) {
                
            }
            
            if(Trigger.isUpdate) {
                
            }
            
            if(Trigger.isInsert || Trigger.isUpdate){
                if(opportunityMap==null||opportunityMap.isEmpty()){
                    opportunityMap = DatabaseSOQLBank.getOpportunityMap(opportunityIdSet);
                }
                
                subTypeClauseLibraryListMap = DatabaseSOQLBank.getHighRiskClauseLibraryBySubType(cLibrarySubTypeSet);
                oppIdOppClauseListMap = DatabaseSOQLBank.getHightRiskOpportunityClause(opportunityIdSet);
                
                for(Id oppId : oppIdOppClauseListMap.keySet()){
                    for(OpportunityClause__c oppClause : oppIdOppClauseListMap.get(oppId)){
                        if(oppClause.SubType__c == Constants.PRODUCT_RENT_REVIEW){
                            if(oppIdRentReviewOppClauseListMap.containsKey(oppId)){
                                oppIdRentReviewOppClauseListMap.get(oppId).add(oppClause);
                            } else {
                                oppIdRentReviewOppClauseListMap.put(
                                    oppId, 
                                    new List<OpportunityClause__c>{
                                        oppClause
                                            }
                                );
                            }
                        }
                    }
                }
                
                for(List<OpportunityLineItem> oppLineItemList : DatabaseSOQLBank.getOpportunityLineItem(opportunityIdSet).values()){
                    for(OpportunityLineItem oppLineItem : oppLineItemList){
                        if(Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(oppLineItem.Product2.Family)){
                            if(oppIdRentReviewOppLineListMap.containsKey(oppLineItem.OpportunityId)){
                                oppIdRentReviewOppLineListMap.get(oppLineItem.OpportunityId).add(oppLineItem);
                            } else {
                                oppIdRentReviewOppLineListMap.put(
                                    oppLineItem.OpportunityId, 
                                    new List<OpportunityLineItem>{oppLineItem}
                                );
                            }
                        }
                    }
                }
            }
        }
        
        // Start -- RPP-2705 DJ Policarpio 05/09/2018
        if(Trigger.isDelete) {
            opportunityLineItemList = Trigger.old;
            // this is used to track delete change on outgoings
            for(OpportunityLineItem newOppLineItem : (List<OpportunityLineItem>) Trigger.old){
                if (newOppLineItem.ProductFamily__c == Constants.RECOVERIES) {
                    opportunityIds.add(newOppLineItem.OpportunityId);
                }
            }
            if (opportunityIds.size() > 0) {
                opportunitiesToUpdateListOutgoing = [select id, TechOutgoingsChanged__c, TechByPassOnClone__c from opportunity where id in:opportunityIds];
                if (opportunitiesToUpdateListOutgoing.size() > 0) {
                    for (Opportunity opp : opportunitiesToUpdateListOutgoing) {
                        if(opportunityupdateMap.containsKey(opp.Id)){
                            opportunityupdateMap.get(opp.Id).TechOutgoingsChanged__c=true;
                        }else{
                            opportunityupdateMap.put(opp.Id, opp);
                            opportunityupdateMap.get(opp.Id).TechOutgoingsChanged__c=true;
                        }
                        //opp.TechOutgoingsChanged__c = true;
                    }
                }
            }
            
        } else {
            opportunityLineItemList = Trigger.new;
        }
        
        //opportunitiesToUpdateList = OpportunityLineItemBL.getOpportunitySecurityDeposit(opportunityLineItemList);
        // End -- RPP-2705 DJ Policarpio 05/09/2018
    }
    
    public void beforeInsert(SObject so)
    {
        OpportunitylineItem newOpportunitylineitem  = (OpportunitylineItem)so;
        Opportunity opportunityRecord=new Opportunity();
        
        if(!newOpportunitylineitem.TechIsClone__c
           && opportunityMap.get(newOpportunitylineitem.OpportunityId) != null
           && opportunityMap.get(newOpportunitylineitem.OpportunityId).TechByPassOnClone__c != null
           && opportunityMap.get(newOpportunitylineitem.OpportunityId).TechByPassOnClone__c
           &&(newOpportunitylineitem.TechProductFamily__c==Constants.RECOVERIES
              ||newOpportunitylineitem.TechProductFamily__c==Constants.FEES_CHARGES
              ||newOpportunitylineitem.TechProductFamily__c==Constants.CAPITAL)){
                  opportunityRecord.id=newOpportunitylineitem.OpportunityId;
                  if(opportunityupdateMap.containsKey(newOpportunitylineitem.OpportunityId)){
                      if (newOpportunitylineitem.TechProductFamily__c==Constants.RECOVERIES) {
                          opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechOutgoingsChanged__c=true;
                      } else if (newOpportunitylineitem.TechProductFamily__c==Constants.FEES_CHARGES) {
                          opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechFeeChargesChanged__c=true;
                      } else if (newOpportunitylineitem.TechProductFamily__c==Constants.CAPITAL) {
                          opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechCapitalChanged__c=true;
                      }
                  }else{ 
                      opportunityupdateMap.put(newOpportunitylineitem.OpportunityId, opportunityRecord);
                      //Added to resolve issues with adding 1 Outgoing for LV02 24.01.2019 NG - Start
                      if (newOpportunitylineitem.TechProductFamily__c==Constants.RECOVERIES) {
                          opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechOutgoingsChanged__c=true;
                      } else if (newOpportunitylineitem.TechProductFamily__c==Constants.FEES_CHARGES) {
                          opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechFeeChargesChanged__c=true;
                      } else if (newOpportunitylineitem.TechProductFamily__c==Constants.CAPITAL) {
                          opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechCapitalChanged__c=true;
                      }
                      //NG - End
                  }
                  newOpportunitylineitem.TechIsChanged__c=true;
              }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
        Opportunity opportunityRecord=new Opportunity();
        OpportunitylineItem newOpportunitylineitem  = (OpportunitylineItem)so;
        //START -- RPP-2762 MDC 5/23/2018
        OpportunitylineItem oldOpportunitylineitem  = (OpportunitylineItem)oldSo;
        
        If((newOpportunitylineitem.TechProductFamily__c==Constants.PRODUCT_RENT_REVIEW||newOpportunitylineitem.TechProductFamily__c==Constants.PRODUCT_PROMO_REVIEW)
           &&(newOpportunitylineitem.StandardReviewType__c!=oldOpportunitylineitem.StandardReviewType__c||
              newOpportunitylineitem.CPIType__c!=oldOpportunitylineitem.CPIType__c||                               
              newOpportunitylineitem.EffectiveFromDate__c!=oldOpportunitylineitem.EffectiveFromDate__c||
              newOpportunitylineitem.EffectiveToDate__c!=oldOpportunitylineitem.EffectiveToDate__c||
              newOpportunitylineitem.Description!=oldOpportunitylineitem.Description||
              newOpportunitylineitem.CappedPercent__c!=oldOpportunitylineitem.CappedPercent__c)
           && opportunityMap.get(newOpportunitylineitem.OpportunityId).TechByPassOnClone__c 
          ){
              newOpportunitylineitem.TechIsChanged__c=true;
              opportunityRecord.Id=newOpportunitylineitem.OpportunityId;
              opportunityRecord.TechReviewItemsChanged__c=true;
              if(opportunityupdateMap.containsKey(newOpportunitylineitem.OpportunityId)){
                  opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechReviewItemsChanged__c=true;
              }else{
                  opportunityupdateMap.put(newOpportunitylineitem.OpportunityId, opportunityRecord);
              }
          }
        If (newOpportunitylineitem.TechProductFamily__c==Constants.RECOVERIES
            && newOpportunitylineitem.isActive__c!=oldOpportunitylineitem.isActive__c
            && newOpportunitylineitem.unitprice!=oldOpportunitylineitem.unitprice){
                newOpportunitylineitem.TechIsChanged__c=true;
                opportunityRecord.Id=newOpportunitylineitem.OpportunityId;
                if(opportunityupdateMap.containsKey(newOpportunitylineitem.OpportunityId)){
                    opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechOutgoingsChanged__c=true;
                }else{
                    opportunityupdateMap.put(newOpportunitylineitem.OpportunityId, opportunityRecord);
                }
            }
        
        If (newOpportunitylineitem.TechProductFamily__c==Constants.FEES_CHARGES
            && newOpportunitylineitem.isActive__c!=oldOpportunitylineitem.isActive__c
            && newOpportunitylineitem.unitprice!=oldOpportunitylineitem.unitprice){
                newOpportunitylineitem.TechIsChanged__c=true;
                opportunityRecord.Id=newOpportunitylineitem.OpportunityId;
                if(opportunityupdateMap.containsKey(newOpportunitylineitem.OpportunityId)){
                    opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechFeeChargesChanged__c=true;
                }else{
                    opportunityupdateMap.put(newOpportunitylineitem.OpportunityId, opportunityRecord);
                }
            }
        
        If (newOpportunitylineitem.TechProductFamily__c==Constants.CAPITAL
            && newOpportunitylineitem.isActive__c!=oldOpportunitylineitem.isActive__c
            && newOpportunitylineitem.totalprice!=oldOpportunitylineitem.totalprice){
                newOpportunitylineitem.TechIsChanged__c=true;
                opportunityRecord.Id=newOpportunitylineitem.OpportunityId;
                if(opportunityupdateMap.containsKey(newOpportunitylineitem.OpportunityId)){
                    opportunityupdateMap.get(newOpportunitylineitem.OpportunityId).TechCapitalChanged__c=true;
                }else{
                    opportunityupdateMap.put(newOpportunitylineitem.OpportunityId, opportunityRecord);
                }
            }
    }
    
    /**
* beforeDelete
*
* This method is called iteratively for each record to be deleted during a BEFORE
* trigger.
*/
    public void beforeDelete(SObject so)
    {
        
    }
    
    public void afterInsert(SObject so)
    {
    }
    
    public void afterUpdate(SObject oldSo, SObject so){
        Decimal cappedPercent;
        String standardRevType;
        Boolean isDiffFromNatAgreement = false;
        Opportunity opportunity;
        OpportunityLineItem newOppLineItem = (OpportunityLineItem) so;
        OpportunityLineItem oldOppLineItem = (OpportunityLineItem) oldSo;
        Set<String> partnershipSegmentationSet;
        List<OpportunityLineItem> existingRentReviewOppLineList = new List<OpportunityLineItem>();
        
        if(opportunityMap.containsKey(newOppLineItem.OpportunityId)){
            opportunity = opportunityMap.get(newOppLineItem.OpportunityId);
        }
        
        partnershipSegmentationSet = new Set<String>{
            Constants.GROWTH_PARTNER,
                Constants.STRATEGIC_PARTNER
                };
                    
                    if(Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(newOppLineItem.ProductFamily__c)
                       && Constants.OPP_RETAIL_LEASING_API_NAME.equalsIgnoreCase(opportunity.RecordType.DeveloperName)
                       && (newOppLineItem.StandardReviewType__c != oldOppLineItem.StandardReviewType__c 
                           || newOppLineItem.CappedPercent__c != oldOppLineItem.CappedPercent__c)){
                               
                               if(opportunity.NationalAgreement__c != null 
                                  && (
                                      (opportunity.NationalAgreement__r.Account__c != null 
                                       && partnershipSegmentationSet.contains(opportunity.NationalAgreement__r.Account__r.PartnershipSegmentation__c)) 
                                      || (opportunity.AccountId != null 
                                          &&  partnershipSegmentationSet.contains(opportunity.Account.PartnershipSegmentation__c))
                                  )
                                 ){
                                     if(oppIdRentReviewOppLineListMap.containsKey(newOppLineItem.OpportunityId)){
                                         existingRentReviewOppLineList = oppIdRentReviewOppLineListMap.get(newOppLineItem.OpportunityId);
                                         cappedPercent = newOppLineItem.CappedPercent__c;
                                         standardRevType = newOppLineItem.StandardReviewType__c;
                                         
                                         for(OpportunityLineItem oppLine : existingRentReviewOppLineList){
                                             if(newOppLineItem.Id != oppLine.Id && (cappedPercent != oppLine.CappedPercent__c
                                                                                    || standardRevType != oppLine.StandardReviewType__c)){
                                                                                        isDiffFromNatAgreement = true;
                                                                                    }
                                         }
                                     }
                                     
                                     if(isDiffFromNatAgreement && !oppIdRentReviewOppClauseListMap.containsKey(newOppLineItem.OpportunityId)){
                                         if(subTypeClauseLibraryListMap.containsKey(Constants.PRODUCT_RENT_REVIEW)){
                                             newOpportunityClauseList.addAll(
                                                 OpportunityBL.createOpportunityClause(
                                                     oppClauseRecordTypeByName.get(Constants.LEASING_CLAUSE).getRecordTypeId(),
                                                     opportunity,
                                                     subTypeClauseLibraryListMap.get(Constants.PRODUCT_RENT_REVIEW)
                                                 )
                                             );
                                         }
                                     } else if(!isDiffFromNatAgreement && oppIdRentReviewOppClauseListMap.containsKey(newOppLineItem.OpportunityId) 
                                               && ((newOppLineItem.CappedPercent__c != oldOppLineItem.CappedPercent__c 
                                                    && opportunity.NationalAgreement__r.RentReviewCappedPercent__c == cappedPercent) 
                                                   || (newOppLineItem.StandardReviewType__c != oldOppLineItem.StandardReviewType__c 
                                                       && opportunity.NationalAgreement__r.StandardReviewTypes__c == standardRevType))){
                                                           oppClauseForDeleteList.addAll(oppIdRentReviewOppClauseListMap.get(newOppLineItem.OpportunityId));
                                                       }
                                 }
                           }
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    /**
* andFinally
*
* This method is called once all records have been processed by the trigger. Use this
* method to accomplish any final operations such as creation or updates of other records.
*/
    public void andFinally()
    {
        // Start -- RPP-2705 DJ Policarpio 05/09/2018
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityLineItemTriggerHandler.class.getName());        
        if(opportunityupdateMap.size() > 0){
            try{
                database.update(opportunityupdateMap.values());
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        if(opportunitiesToUpdateListOutgoing.size() > 0){
            try{
                //database.update(opportunitiesToUpdateListOutgoing);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // START : RPP-6061 YN 9.12.2018
        if(newOpportunityClauseList != null && newOpportunityClauseList.size() > 0){
            try{
                database.insert(newOpportunityClauseList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : RPP-6061 YN 9.12.2018
        
        if(oppClauseForDeleteList != null && oppClauseForDeleteList.size() > 0){
            try{
                database.delete(oppClauseForDeleteList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        if(Trigger.isAfter){
            errorHandler.save();
        }
        // End -- RPP-2705
    }
}