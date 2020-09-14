/*
* @author:              Lean Flores
* @description:         Apex Controller for GroupRenewal.cmp
*/

public class GroupRenewalController {
    
    private static Map<String, Schema.RecordTypeInfo> opcRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OPPORTUNITY_CLAUSE_API);
    
    public class initializationDataWrapper {
        @AuraEnabled public List<Contract__c> contracts;
        @AuraEnabled public List<String> dealTypeValues;
        @AuraEnabled public Id oppOwnerId;
    }
    
    public class SavedOppsWrapper {
        @AuraEnabled public List<Opportunity> savedOpps;
    }
    

    
	@AuraEnabled
    public static LightningResponse getData(Id accId) {
        LightningResponse response = new LightningResponse(); 
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(GroupRenewalController.class.getName());
        initializationDataWrapper wrapper = new initializationDataWrapper();
        List<Account> childAccounts = new List<Account>();
        wrapper.dealTypeValues = new List<String>{''};
        
        for(Schema.PicklistEntry ple : Opportunity.DealType__c.getDescribe().getPicklistValues()) {
            wrapper.dealTypeValues.add(ple.getValue());
        }
        
        try {
            
            childAccounts = [SELECT Id FROM Account WHERE ParentId=:accId AND RecordType.DeveloperName=:Constants.PROPERTY_BASED_APINAME];
            
            if (childAccounts.size() > 0) {
                wrapper.contracts = [SELECT Id, Opportunity__c, Account__r.Name, Space__r.Name, Property__r.Name, TECH_OpportunityRecordTypeId__c, LeaseEndDate__c 
                                     FROM Contract__c 
                                     WHERE Account__c IN:childAccounts AND LeaseStatus__c!='E' AND RecordType.DeveloperName !='CON_StoreroomContract' ORDER BY Property__r.Name ASC];
            }           
            
            
            List<AccountTeamMember> leasingLead = [SELECT UserId FROM AccountTeamMember WHERE AccountId=:accId AND TeamMemberRole='Leasing Lead' LIMIT 1];
            
            
            wrapper.oppOwnerId = leasingLead != null && leasingLead.size() > 0 ? leasingLead[0].UserId : UserInfo.getUserId();      
            
            
        } catch(Exception e){
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        

        
        response.returnValue = JSON.serialize(wrapper);
        errorHandler.save();
        return response;
        
    }
    
    @AuraEnabled
    public static LightningResponse saveOpportunities(List<Opportunity> oppList) {
        
        LightningResponse response = new LightningResponse(); 
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(GroupRenewalController.class.getName());
        SavedOppsWrapper wrapper = new SavedOppsWrapper();
           
        List<Opportunity> oppsWithoutClause = new List<Opportunity>();
        List<OpportunityClause__c> newUsageClauses = new List<OpportunityClause__c>(); 
        List<OpportunityClause__c> usageClausesToDelete = new List<OpportunityClause__c>(); 
        Set<Id> parentOppIdSet = new Set<Id>();
        
        
        Map<Id, List<Opportunity>> woClauseOppMapByParentId = new Map<Id, List<Opportunity>>();
        
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            Database.insert(oppList);
            wrapper.savedOpps = [SELECT Name, Account.Name, AccountId, Space__r.Name, Space__c, Property__c,
                                 Property__r.Name, StageName, Type, DealType__c, ParentOpportunity__c, RecordURL__c, RecordType.DeveloperName,
                                 ExistingContract__r.UsageClauseDetails__c, ExistingContract__r.UsageClauseName__c,
                                 (SELECT Id FROM Opportunity_Clauses__r WHERE Type__c=:Constants.USAGE)
                                 FROM Opportunity WHERE Id IN:oppList];
            
            createOppLineItems((new Map<Id, Opportunity>(wrapper.savedOpps)).keySet());            
            
              
            
            for (Opportunity opp : wrapper.savedOpps) {
                // RPP-10601 START LF
                // Create Usage Clause from Existing Contract
                if (!String.isBlank(opp.ExistingContract__r.UsageClauseDetails__c) && !String.isBlank(opp.ExistingContract__r.UsageClauseName__c)) {
                    OpportunityClause__c newOppClause = new OpportunityClause__c(
                        ClauseDetails__c = opp.ExistingContract__r.UsageClauseDetails__c,
                        Name = opp.ExistingContract__r.UsageClauseName__c,
                        Opportunity__c = opp.Id,
                        RecordTypeId = opcRecordTypeMapByName.get(Constants.OC_LEASING_CLAUSE).getRecordTypeId(),
                        Type__c = Constants.USAGE
                    );
                    newUsageClauses.add(newOppClause);
                    if (opp.Opportunity_Clauses__r != null && opp.Opportunity_Clauses__r.size() > 0) {
                        usageClausesToDelete.addAll(opp.Opportunity_Clauses__r);
                    }
                } 
                // Get new Opportunities without Opp Clauses
                else if ((opp.Opportunity_Clauses__r == null || opp.Opportunity_Clauses__r.size() <= 0) &&
                         !String.isBlank(opp.ParentOpportunity__c) &&
                         (opp.RecordType.DeveloperName == Constants.OPP_COMMERCIAL_LEASING_API_NAME || opp.RecordType.DeveloperName == Constants.OPP_RETAIL_LEASING_API_NAME)){
                             oppsWithoutClause.add(opp);
                             parentOppIdSet.add(opp.ParentOpportunity__c);
                         }
                // RPP-10601 END LF
            }
            
            // Create Opp Clause based on Parents Opp Clause
            if (oppsWithoutClause.size() > 0) {  
                List<OpportunityClause__c> parentOpcList = [SELECT ClauseDetails__c, Name, ReferencedClause__c, Opportunity__c
                                                            FROM OpportunityClause__c
                                                            WHERE Opportunity__c IN:parentOppIdSet];
                
                Map<Id, OpportunityClause__c> OpcByParentIdMap = new Map<Id, OpportunityClause__c>();
                
                // Only get 1 Usage Clause as with FLOW:'Renew Contract'
                if (parentOpcList.size() > 0) {
                    for (OpportunityClause__c oppClause : parentOpcList) {
                        if (!OpcByParentIdMap.containsKey(oppClause.Opportunity__c)) {
                            OpcByParentIdMap.put(oppClause.Opportunity__c, oppClause);
                        }
                    }
                }
                // loop on new Opps without clause
                for (Opportunity opp : oppsWithoutClause) {
                    
                    if (OpcByParentIdMap.containsKey(opp.ParentOpportunity__c)) {
                        OpportunityClause__c parentOppClause = OpcByParentIdMap.get(opp.ParentOpportunity__c);
                        OpportunityClause__c newOppClause = new OpportunityClause__c(
                            ClauseDetails__c = parentOppClause.ClauseDetails__c,
                            Name = parentOppClause.Name,
                            Opportunity__c = opp.Id,
                            RecordTypeId = opcRecordTypeMapByName.get(Constants.OC_LEASING_CLAUSE).getRecordTypeId(),
                            Type__c = Constants.USAGE
                        );
                        newUsageClauses.add(newOppClause);
                    }
                }
            }
            // RPP-10601 START LF
            if (usageClausesToDelete.size() > 0) {
                Database.delete(usageClausesToDelete);
                system.debug('Usage Clauses to delete ------ ' + usageClausesToDelete);
            }
            // RPP-10601 END LF
            if (newUsageClauses.size() > 0) {
                Database.insert(newUsageClauses);
                system.debug('New Clauses ------ ' + newUsageClauses);
            }
            

        } catch (Exception e) {
            Database.rollback(sp);
            response.status = Constants.FAILED;
            response.message = e.getMessage();
            errorHandler.createError(e);
        }
        
        response.returnValue = JSON.serialize(wrapper);
        errorHandler.save();
        return response;
    }
    
    
    public static void createOppLineItems(Set<Id> oppsIdSet) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(GroupRenewalController.class.getName());
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([SELECT id, TotalPromotionLevy__c, TechByPassOnClone__c, RecordTypeId,Property__c, AccountId,AnnualMinimumRent__c,
                                                                 ProposedStartDate__c, TermYr__c, SecurityDeposit__c, PromoLevyIncluded__c, pricebook2Id, Property__r.PriceBook__c,
                                                                 Space__c, Space__r.BillingCategory__c, Space__r.Type__c, DealType__c, CurrencyIsoCode, NZProperty__c, NationalAgreement__r.Status__c,
                                                                 NationalAgreement__r.PromoPercentage__c, NationalAgreement__r.CurrentMinimumThreshold__c, NationalAgreement__r.CurrentMaximumThreshold__c
                                                                 from opportunity 
                                                                 where id IN:oppsIdSet]);
        
        Map<Id, List<PriceBookEntry>> promoPbeByPbMap = new Map<Id, List<PriceBookEntry>>();
        Map<Id, List<PriceBookEntry>> rentPbeByPbMap = new Map<Id, List<PriceBookEntry>>();
        Set<Id> priceBookIdSet = new Set<Id>();
        
        Decimal lowestAnnualMinimumRent = null;
        Decimal highestAnnualMinimumRent = null;
        
        // Data preparation
        for (Opportunity opp : oppsMap.values()) {
            priceBookIdSet.add(opp.Property__r.PriceBook__c);
            if (opp.AnnualMinimumRent__c != null) {
                lowestAnnualMinimumRent = lowestAnnualMinimumRent == null || lowestAnnualMinimumRent > opp.AnnualMinimumRent__c ? opp.AnnualMinimumRent__c : lowestAnnualMinimumRent;
                highestAnnualMinimumRent = highestAnnualMinimumRent == null || highestAnnualMinimumRent < opp.AnnualMinimumRent__c ? opp.AnnualMinimumRent__c : highestAnnualMinimumRent;
            }
        }
        
        Map<String, List<PromotionFund__mdt>> promoFundsByTypeMap = new Map<String, List<PromotionFund__mdt>>();
        
        // Disjunction Queries are not supported for MDT 
        List<PromotionFund__mdt> minMatchingPromos = [SELECT Id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c,
                                                      MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c,
                                                      RentRangeMax__c, RentRangeMin__c, Type__c
                                                      FROM PromotionFund__mdt 
                                                      WHERE RentRangeMin__c <= :lowestAnnualMinimumRent];
        
        List<PromotionFund__mdt> maxMatchingPromos = [SELECT Id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c,
                                                      MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c,
                                                      RentRangeMax__c, RentRangeMin__c, Type__c
                                                      FROM PromotionFund__mdt 
                                                      WHERE RentRangeMax__c >= :highestAnnualMinimumRent];
        
        Set<PromotionFund__mdt> matchingPromos = new Set<PromotionFund__mdt>();
        matchingPromos.addAll(minMatchingPromos);
        matchingPromos.addAll(maxMatchingPromos);
        
        for (PromotionFund__mdt promoFundMdt : matchingPromos) {
                                                    
            if (promoFundsByTypeMap.containsKey(promoFundMdt.Type__c)) {
                promoFundsByTypeMap.get(promoFundMdt.Type__c).add(promoFundMdt);
            } else {
                promoFundsByTypeMap.put(promoFundMdt.Type__c, new List<PromotionFund__mdt>{promoFundMdt});
            }
            
        }
        
        // PriceBookEntries by PriceBook, although used list for map values, it is very rare to have more than 1 PROMO_MARKETING PriceBookEntries per PriceBook 
        for (PriceBookEntry pbe : [SELECT Id, Pricebook2Id, Product2Id, Product2.Family,
                                   Product2.SpaceBillingCategory__c, Product2.DealType__c,
                                   CurrencyIsoCode, Product2.SpaceType__c
                                   FROM PriceBookEntry
                                   WHERE Pricebook2Id IN:priceBookIdSet
                                   AND (Product2.Family =:Constants.PROMO_MARKETING OR Product2.Family =:Constants.RENT) AND isActive = true]) {
                                       
                                       if (Constants.PROMO_MARKETING.equalsIgnoreCase(pbe.Product2.Family)) {
                                           if (promoPbeByPbMap.containsKey(pbe.Pricebook2Id)) {
                                               promoPbeByPbMap.get(pbe.Pricebook2Id).add(pbe);
                                           } else {
                                               promoPbeByPbMap.put(pbe.Pricebook2Id, new List<PriceBookEntry>{pbe});
                                           }
                                       } else if (Constants.RENT.equalsIgnoreCase(pbe.Product2.Family)) {
                                           if (rentPbeByPbMap.containsKey(pbe.Pricebook2Id)) {
                                               rentPbeByPbMap.get(pbe.Pricebook2Id).add(pbe);
                                           } else {
                                               rentPbeByPbMap.put(pbe.Pricebook2Id, new List<PriceBookEntry>{pbe});
                                           }                                           
                                       }
                                   }
        
        
        List<OpportunityLineItem> opportunityProductsList = new List<OpportunityLineItem>();
        
        
        // OpportunityLineItem Creation
        for (Id oppId : oppsIdSet) {
            Opportunity opp = oppsMap.get(oppId);
            String oppSpaceBillingCategory = opp.Space__r.BillingCategory__c != null ? opp.Space__r.BillingCategory__c : 'NA';
            
            
            // Base Rent
            if (opp.Property__r.PriceBook__c != null && rentPbeByPbMap.containsKey(opp.Property__r.PriceBook__c)) {
                for(PriceBookEntry rentPbe : rentPbeByPbMap.get(opp.Property__r.PriceBook__c)) {
                    
                    String rentPbeSpaceBillingCategory = rentPbe.Product2.SpaceBillingCategory__c != null ? rentPbe.Product2.SpaceBillingCategory__c : '';
                    String rentPbeProduct2DealType = rentPbe.Product2.DealType__c != null ? rentPbe.Product2.DealType__c : '';
                    String rentPbeProduct2SpaceType = rentPbe.Product2.SpaceType__c != null ? rentPbe.Product2.SpaceType__c : '';                    
                    
                    if (rentPbeSpaceBillingCategory.contains(oppSpaceBillingCategory)
                        && rentPbe.CurrencyIsoCode == opp.CurrencyIsoCode
                        && (opp.DealType__c != null && rentPbeProduct2DealType.contains(opp.DealType__c))
                        && (opp.Space__r.Type__c != null && rentPbeProduct2SpaceType.contains(opp.Space__r.Type__c))) {
                            
                            OpportunityLineItem rentLineItem = new OpportunityLineItem();
                            rentLineItem.Product2Id = rentPbe.Product2Id;             
                            rentLineItem.UnitPrice = opp.AnnualMinimumRent__c;
                            rentLineItem.Quantity = 1;
                            rentLineItem.OpportunityId = oppId;
                            rentLineItem.PricebookEntryId = rentPbe.Id;
                            opportunityProductsList.add(rentLineItem);
                            
                            break; // Only need one matching Pbe
                        }
                }
            }
            
            
            // Promotion Fund
            if (opp.Property__r.PriceBook__c != null && promoPbeByPbMap.containsKey(opp.Property__r.PriceBook__c)) {
                
                Double rent = getRentInfo(opp, promoFundsByTypeMap);
                    
                for(PriceBookEntry promoPbe : promoPbeByPbMap.get(opp.Property__r.PriceBook__c)) {
                    
                    String promoPbeSpaceBillingCategory = promoPbe.Product2.SpaceBillingCategory__c != null ? promoPbe.Product2.SpaceBillingCategory__c : '';
                    String promoPbeProduct2DealType = promoPbe.Product2.DealType__c != null ? promoPbe.Product2.DealType__c : '';
                    String promoPbeProduct2SpaceType = promoPbe.Product2.SpaceType__c != null ? promoPbe.Product2.SpaceType__c : '';
                    
                    if (rent != null && promoPbeSpaceBillingCategory.contains(oppSpaceBillingCategory)
                        && promoPbe.CurrencyIsoCode == opp.CurrencyIsoCode
                        && (opp.DealType__c != null && promoPbeProduct2DealType.contains(opp.DealType__c))
                        && (opp.Space__r.Type__c != null && promoPbeProduct2SpaceType.contains(opp.Space__r.Type__c))) {
                        	
                            OpportunityLineItem promoLineItem = new OpportunityLineItem();
                            promoLineItem.Product2Id = promoPbe.Product2Id;
                            promoLineItem.UnitPrice = rent;
                            promoLineItem.Quantity = 1;
                            promoLineItem.OpportunityId = oppId;
                            promoLineItem.PricebookEntryId = promoPbe.Id;
                            opportunityProductsList.add(promoLineItem);
                            
                            break; // Only need one matching Pbe
                    }
                }
            }
        }
        
        try{
            Database.insert(opportunityProductsList);
        } catch(Exception e){
            errorHandler.createError(e);
        }        
        
        errorHandler.save();
    }
    
    /*
    * @Author: Lean Flores
    * @Parameter: 
    * @Description: This is a bulkified version of OpportunityLineItemController.getRentInfo
    */    
    private static Double getRentInfo(Opportunity opp, Map<String, List<PromotionFund__mdt>> promoFundsMap) {
        Double promoFund = null;
        Decimal currentRent = opp.AnnualMinimumRent__c != null ? opp.AnnualMinimumRent__c : 0;
        
        
        if (opp.NationalAgreement__c != null && opp.NationalAgreement__r.PromoPercentage__c != null && 'Active'.equalsIgnoreCase(opp.NationalAgreement__r.Status__c)) {
            Decimal min = opp.NationalAgreement__r.CurrentMinimumThreshold__c != null ? opp.NationalAgreement__r.CurrentMinimumThreshold__c : 0;
            Decimal max = opp.NationalAgreement__r.CurrentMaximumThreshold__c != null ? opp.NationalAgreement__r.CurrentMaximumThreshold__c : 999999999999.99;
            
            promoFund = currentRent * opp.NationalAgreement__r.PromoPercentage__c / 100 >= min ? currentRent * opp.NationalAgreement__r.PromoPercentage__c / 100 : min;
            promoFund = promoFund <= max ? promoFund : max;
            
        } 
        else if (opp.NZProperty__c == null && currentRent > 0 && opp.DealType__c != null) {
            
            List<PromotionFund__mdt> promoFundMdtList = promoFundsMap.containsKey(opp.DealType__c) ? promoFundsMap.get(opp.DealType__c) : new List<PromotionFund__mdt>();
            PromotionFund__mdt matchedPromoFundMdt = null;
            
            for (PromotionFund__mdt promoFundMdt : promoFundMdtList) {
                
                if (promoFundMdt.Type__c == opp.DealType__c && promoFundMdt.RentRangeMax__c >= currentRent && promoFundMdt.RentRangeMin__c <= currentRent) {
                    matchedPromoFundMdt = promoFundMdt;
                    break; // Should only match one 
                }
            }
            
            if (matchedPromoFundMdt != null) {
                promoFund = calculatePromotionFundBasedOnFund(currentRent, matchedPromoFundMdt);
            }
            
            
        } 
        else if (opp.NZProperty__c != null && currentRent > 0) {
            List<PromotionFund__mdt> promoFundMdtList = new List<PromotionFund__mdt>();
            
            for (List<PromotionFund__mdt> mdtList : promoFundsMap.values()) {
                promoFundMdtList.addAll(mdtList);
            }
            
            PromotionFund__mdt matchedPromoFundMdt = null;
            
            for (PromotionFund__mdt promoFundMdt : promoFundMdtList) {
                if (opp.NZProperty__c != null && opp.NZProperty__c.contains(promoFundMdt.Type__c) &&
                   promoFundMdt.RentRangeMax__c >= currentRent && promoFundMdt.RentRangeMin__c <= currentRent) {
                    
                       matchedPromoFundMdt = promoFundMdt;
                       break;
                       
                }
            }
            
            if (matchedPromoFundMdt != null) {
                promoFund = calculatePromotionFundBasedOnFundNZ(currentRent, true, matchedPromoFundMdt); // promoThresholdApplies checkbox in RentCalculator.cmp default value is true
            }            
            
            
        }
        
        return promoFund;
    }
    
    private static Double calculatePromotionFundBasedOnFund(Decimal currentRent, PromotionFund__mdt promotionFund) {
        Decimal promotion= 0;
        if (promotionFund.MinRequired__c != null && promotionFund.MinRequired__c) {
            promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
        } else if (promotionFund.MaxRequired__c!= null && promotionFund.MaxRequired__c) {
            //promotion =  promotionFund.CategoryAmount__c + (currentRent - promotionFund.RentRangeMin__c + 1) * promotionFund.CategoryPecentage__c / 100 > promotionFund.MaxPromotionFund__c ? promotionFund.MaxPromotionFund__c : promotionFund.CategoryAmount__c + (currentRent - promotionFund.RentRangeMin__c + 1) * promotionFund.CategoryPecentage__c / 100;
            promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
            if (promotion < promotionFund.MinimumPromotionFund__c) {
                promotion = promotionFund.MinimumPromotionFund__c;
            } else if (promotion > promotionFund.MaxPromotionFund__c) {
                promotion = promotionFund.MaxPromotionFund__c;
            }              
        } else {
            //promotion = promotionFund.CategoryAmount__c + (currentRent - promotionFund.RentRangeMin__c + 1) * promotionFund.CategoryPecentage__c / 100;
            //promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
            // minmus should be always checked
            promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
        }
        return promotion;
    }
    
    private static Double calculatePromotionFundBasedOnFundNZ(Decimal currentRent, Boolean isThresholdApplicable, PromotionFund__mdt promotionFund) {
        Decimal promotion= 0;
        if(isThresholdApplicable){
            promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
            promotion = promotion <= promotionFund.MaxPromotionFund__c ? promotion : promotionFund.MaxPromotionFund__c;
        }else{
            promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
        }   
        return promotion;
    }
    
}