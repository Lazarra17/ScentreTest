/**
* @author:         Lean Flores
* @desc:           RPP-10622: Custom Object class for LV02 Cases
**/
public class LV02CaseBL {
    
    private static Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByDeveloperName  = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OBJECT_CASE);

    /**
* @author:         Lean Flores
* @parameter:	   List<Case> Rejected LV02 Cases
* @desc:           RPP-10577  
**/    
    public static List<Case> unlockVariationOpps(List<Case> cases) {
        // Initialization
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(CaseBL.class.getName());
        List<Id> lockedVarOppsSet = new List<Id>();
        List<Case> rejectedCases = new List<Case>();
        
        for (Case cse : cases) {
            if (cse.RecordTypeId == caseRecordTypeMapByDeveloperName.get(Constants.LV02_SPECIALTY_VARIATION).getRecordTypeId()
                && cse.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED_REJECTED)) {
                    if (Approval.isLocked(cse.Opportunity__c)) {
                        lockedVarOppsSet.add(cse.Opportunity__c);
                        rejectedCases.add(cse);
                    }
                }
        }
        
        if (lockedVarOppsSet.size() > 0) {
            try {
                Approval.unlock(lockedVarOppsSet);
            }  catch(Exception e) {
                errorHandler.createError(e);
                system.debug('RPP-10577 FAILED: ' + e);
            }
        }
        
        return rejectedCases;
    }
    
    /**
* @author:         Lean Flores
* @parameter:	   List<Case> approvedLV02List Approved LV02 Cases
* @desc:           RPP-10622  
**/
    public static List<Opportunity> updateOriginalOpps(List<Case> cases){
        
        // Initialization
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(CaseBL.class.getName());
        List<OpportunityLineItem> variationCapitalProducts = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oldCapitalProducts = new List<OpportunityLineItem>();
        List<OpportunityLineItem> newCapitalProducts = new List<OpportunityLineItem>();
        Map<Id, Id> origOppByVarOppIdMap = new Map<Id, Id>();
        List<Case> completedLV02Cases = new List<Case>();
        List<Opportunity> origOpps = new List<Opportunity>();
        List<Opportunity> oppsToUnlockList = new List<Opportunity>();
        
        
        // Validate if LV02 Cases meet the criteria 
        for (Case cse: cases) {
            if (cse.OldOpportunity__c != null && cse.Opportunity__c != null && cse.Status.equalsIgnoreCase(Constants.CASE_STATUS_COMPLETED)
                && cse.RecordTypeId == caseRecordTypeMapByDeveloperName.get(Constants.LV02_SPECIALTY_VARIATION).getRecordTypeId()
                && (cse.Capital__c)) {
                    
                    origOppByVarOppIdMap.put(cse.Opportunity__c, cse.OldOpportunity__c);
                    completedLV02Cases.add(cse);
                    
                }
        }
        
        // Opportunity Map
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AnnualMinimumRent__c, FitoutContribution__c, TotalForecastCapital__c
                                                                FROM Opportunity
                                                                WHERE Id IN: origOppByVarOppIdMap.keySet() OR Id IN:origOppByVarOppIdMap.values()]);
        
        Map<Id, List<OpportunityLineItem>> capitalProductsByOppMap = new Map<Id, List<OpportunityLineItem>>();
        
        // Get Capital Products for Original and Variation Opportunities
        for(OpportunityLineItem capitalProduct : [SELECT Id, Name, TotalPrice, OpportunityId, TechProductFamily__c, Product2Id,
                                                  CapitalCategory__c, ProductFamily__c, IsActive__c, CurrencyIsoCode
                                                  FROM OpportunityLineItem
                                                  WHERE (OpportunityId IN:origOppByVarOppIdMap.keySet() OR OpportunityId IN:origOppByVarOppIdMap.values())
                                                  AND TechProductFamily__c=:Constants.CAPITAL]) {
                                                      
                                                      if(capitalProductsByOppMap.containsKey(capitalProduct.OpportunityId)) {
                                                          capitalProductsByOppMap.get(capitalProduct.OpportunityId).add(capitalProduct);
                                                      } else {
                                                          capitalProductsByOppMap.put(capitalProduct.OpportunityId, new List<OpportunityLineItem>{capitalProduct});
                                                      }
                                                      
                                                  }
        
        
        if (completedLV02Cases.size() > 0) {
            for (Case lv02Case : completedLV02Cases) {
                Opportunity origOpp = oppMap.get(lv02Case.OldOpportunity__c);
                Opportunity varOpp = oppMap.get(lv02Case.Opportunity__c);
                
                origOpp.Tech_isUpdateFromLV02__c = true;
                
                // TODO: Unlock records if needed
                if (Approval.isLocked(origOpp)) {
                    oppsToUnlockList.add(origOpp);
                }
                
                CompletedLV02Case completedLV02 = 
                    new CompletedLV02Case(lv02Case, origOpp, varOpp)
                    //.changedRentUpdates()
                    .changedCapitalUpdates(capitalProductsByOppMap);
                
                
                origOpps.add(completedLV02.originalOpp);
                //oldCapitalProducts.addAll(completedLV02.oldCapitalProducts);
                newCapitalProducts.addAll(completedLV02.newCapitalProducts);
            }
        }
        
        system.debug('RPP-10622 Old Capital Products: ' + oldCapitalProducts);
        system.debug('RPP-10622 New/Variation Capital Products: ' + newCapitalProducts);
        system.debug('RPP-10622 Original Opps: ' + origOpps);
        system.debug('RPP-10622 Locked Opps: ' + oppsToUnlockList);
        
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        Savepoint sp = Database.setSavepoint();
        
        if (origOpps.size() > 0) {
            try {
                
                // Unlock locked Opportunities
                if (oppsToUnlockList.size() > 0) {
                    Approval.unlock(oppsToUnlockList);
                }
                
                Database.update(origOpps);
                
                // Delete Old Capital Products
                /*if (oldCapitalProducts.size() > 0) {
                    Database.delete(oldCapitalProducts); 
                }*/
                
                // Upsert new Capital Products
                if (newCapitalProducts.size() > 0) {
                    Database.upsert(newCapitalProducts);
                }
                // Set Tech_isUpdateFromLV02__c to false
                for (Opportunity opp : origOpps) {
                    opp.Tech_isUpdateFromLV02__c = false;
                }
                
                if (origOpps.size() > 0) {
                    Database.update(origOpps);
                }
                
                // re-lock locked Opportunities
                if (oppsToUnlockList.size() > 0) {
                    Approval.lock(oppsToUnlockList);
                }               
                
                
            } catch(Exception e) {
                Database.rollback(sp);
                errorHandler.createError(e);
                system.debug('RPP-10622 FAILED: ' + e);
            }
        }
        
        errorHandler.save();
        return origOpps;
    }
    
    public class CompletedLV02Case { 
        
        public Case lv02Case {get;set;}
        public List<OpportunityLineItem> oldCapitalProducts {get;set;}
        public List<OpportunityLineItem> newCapitalProducts {get;set;}
        public Opportunity originalOpp {get;set;}
        public Opportunity variationOpp {get;set;}
        
        // Constructor
        public CompletedLV02Case(Case lv02Case, Opportunity originalOpp, Opportunity variationOpp) {
            this.lv02Case = lv02Case;
            this.originalOpp = originalOpp;
            this.variationOpp = variationOpp;
            oldCapitalProducts = new List<OpportunityLineItem>();
            newCapitalProducts = new List<OpportunityLineItem>();
            
        }
        
        
        // Chainable Update methods for LV02 changes
        /*
        public CompletedLV02Case changedRentUpdates() {
            
            if (!this.lv02Case.Rent__c) {
                return this;
            }
            
            this.originalOpp.AnnualMinimumRent__c = this.variationOpp.AnnualMinimumRent__c;
            this.originalOpp.ForecastRent__c = this.variationOpp.AnnualMinimumRent__c;
            
            return this;
        }
        */
        
        public CompletedLV02Case changedCapitalUpdates(Map<Id, List<OpportunityLineItem>> capitalProductsByOppMap) {
            
            if (!this.lv02Case.Capital__c) {
                return this;
            }
            
            // Capital Changes
            this.originalOpp.FitoutContribution__c = this.variationOpp.FitoutContribution__c;
            this.originalOpp.TotalASRForecastCapital__c = this.variationOpp.TotalForecastCapital__c;
            
            Map<String, OpportunityLineItem> oldCapitalProductsMap = new Map<String, OpportunityLineItem>();
            
            if (capitalProductsByOppMap.containsKey(this.originalOpp.Id)) {
                //this.oldCapitalProducts.addAll(capitalProductsByOppMap.get(this.originalOpp.Id));
                for (OpportunityLineItem oldCapProduct : capitalProductsByOppMap.get(this.originalOpp.Id)) {
                    oldCapitalProductsMap.put(oldCapProduct.Product2Id, oldCapProduct);
                }
            }
            
            if (capitalProductsByOppMap.containsKey(this.variationOpp.Id)) {
                
                // Copy Variation Capital Products and fields to Original Opp
                for (OpportunityLineItem variationCapitalProduct : capitalProductsByOppMap.get(this.variationOpp.Id)) {
                    
                    OpportunityLineItem newCapitalProduct;
                    
                    if (oldCapitalProductsMap.containsKey(variationCapitalProduct.Product2Id)) {
                        newCapitalProduct = oldCapitalProductsMap.get(variationCapitalProduct.Product2Id);
                        newCapitalProduct.TotalPrice = variationCapitalProduct.TotalPrice;
                    } else {
                        newCapitalProduct = variationCapitalProduct.clone(false, true, false, false);
                        newCapitalProduct.OpportunityId = this.originalOpp.Id;
                    }
                    
                    this.newCapitalProducts.add(newCapitalProduct);
                }
            }
            
            return this;
            
        }        
    }    
}