public without sharing class LeaseVariationOutgoings {
    @InvocableMethod
    public static void recreateOutgoings(List<String> flowArgsList){
        Id oppId;
        Id contractId;
        Date effectiveDate;
        String queryString;
        Boolean isSuccess = false;
        Contract__c contract;
        Opportunity opportunity;
        PriceBookEntry priceBookEntryTemp;
        OpportunityLineItem newOppLineItemTemp;
        List<String> splitArgsList = flowArgsList[0].split(Constants.SEMICOLON);
        List<LeaseVariationOutgoings__mdt> lVOutgoingsMetadata;
        List<String> effDateStrList;
        List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oldOppLineItemList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oldOLIForDeleteList = new List<OpportunityLineItem>();
        Map<String, List<PriceBookEntry>> priceBookEntryListMap = new Map<String, List<PriceBookEntry>>();
        Map<String, List<PriceBookEntry>> prodCategoryPbeListMap = new Map<String, List<PriceBookEntry>>();
            
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(LeaseVariationOutgoings.class.getName());
        
        system.debug('flowArgsList : ' + flowArgsList);
        system.debug('splitArgsList : ' + splitArgsList);
        
        for(String str : splitArgsList){
            if(str.split(Constants.COLON)[0] == Constants.OPPORTUNITYID){
                oppId = str.split(Constants.COLON)[1];
            } else if(str.split(Constants.COLON)[0] == Constants.CONTRACTID){
                contractId = str.split(Constants.COLON)[1];
            } else if(str.split(Constants.COLON)[0] == Constants.EFFECTIVE_DATE){
                effDateStrList = str.split(Constants.COLON)[1].split(Constants.DASH_NO_SPACE);
            }
        }
        
        effectiveDate = Date.newInstance(Integer.valueOf(effDateStrList[0]), Integer.valueOf(effDateStrList[1]), Integer.valueOf(effDateStrList[2]));
        
        opportunity = [SELECT Id, Name, Property__c, TECHPricebookId__c, ProposedRentCommencementDate__c, AnnualMinimumRent__c,
                       Space__r.SpaceProductsApplies__c, Space__r.RentableArea__c, LeaseVariationEffectiveDate__c, DealType__c,
                       ParentOpportunity__c, ParentOpportunity__r.Name, Space__c, Space__r.ApplicableOutgoings__c, CurrencyIsoCode, 
                       Property__r.ApplicableOutgoings__c, Space__r.Type__c, Space__r.BillingCategory__c
                       FROM Opportunity 
                       WHERE Id =: oppId];

        opportunity.LeaseVariationEffectiveDate__c = effectiveDate;
        
        for(PriceBookEntry pBEntry : [SELECT Id, Name, EffectiveFromDate__c, EffectiveToDate__c, Product2Id, UnitPrice,
                                      Product2.DealType__c, Product2.SpaceBillingCategory__c, Product2.SpaceType__c, PBE_CalculationMethod__c,
                                      Product2.OutgoingsCategory__c, CurrencyIsoCode
                                      FROM PriceBookEntry 
                                      WHERE PriceBook2Id =: opportunity.TECHPricebookId__c
                                        AND Product2.IsActive = true 
                                        AND DisclosureStatementOnly__c = false
                                        AND Product2.ProductCode =: Constants.OTG
                                        AND Product2.DealType__c != null
                                        AND Product2.SpaceBillingCategory__c != null
                                        AND Product2.SpaceType__c != null
                                      ORDER BY EffectiveFromDate__c ASC]){
            if(priceBookEntryListMap.containsKey(pBEntry.Name)){
                priceBookEntryListMap.get(pBEntry.Name).add(pBEntry);
            } else {
                priceBookEntryListMap.put(pBEntry.Name, new List<PriceBookEntry>{pBEntry});
            }
            
            if(prodCategoryPbeListMap.containsKey(pBEntry.Product2.OutgoingsCategory__c)){
                prodCategoryPbeListMap.get(pBEntry.Product2.OutgoingsCategory__c).add(pBEntry);
            } else {
                prodCategoryPbeListMap.put(pBEntry.Product2.OutgoingsCategory__c, new List<PriceBookEntry>{pBEntry});
            }
        }
        
        oldOppLineItemList = [SELECT Id, Name, PriceBookEntryId, PriceBookEntry.Name
                              FROM OpportunityLineItem 
                              WHERE OpportunityId =: oppId
                                AND Product2.ProductCode =: Constants.OTG
                                AND ProductFamily__c =: Constants.RECOVERIES];
        
        system.debug('ParentOpportunity__r : ' + opportunity.ParentOpportunity__r);
        system.debug('opportunity.ParentOpportunity__r.Name.containsIgnoreCase(JDE Lease) : ' + opportunity.Name.containsIgnoreCase('JDE Lease'));
        
        if(opportunity.ParentOpportunity__r.Name.containsIgnoreCase(Constants.JDE_LEASE)){
            lVOutgoingsMetadata = [SELECT Id, MasterLabel, FieldReferenceAPIName__c, OutgoingName__c 
                                   FROM LeaseVariationOutgoings__mdt];
            
            queryString = Constants.LV02_QUERY_SELECT; //'SELECT Id, Name, ';
            
            for(LeaseVariationOutgoings__mdt outgoingMDT : lVOutgoingsMetadata){
                queryString += outgoingMDT.FieldReferenceAPIName__c + Constants.COMMA;
            }
            
            queryString = queryString.removeEndIgnoreCase(Constants.COMMA);
            queryString += Constants.DML_FROM + Constants.CONTRACT_API; //' FROM Contract__c';
            queryString += Constants.LV02_QUERY_WHERE + Constants.APOSTROPHE + contractId + Constants.APOSTROPHE; //' WHERE Id = \'' + contractId + '\'';
            
            system.debug('queryString : ' + queryString);
            
            contract = Database.query(queryString);
            
            system.debug('contract : ' + contract);
            
            for(LeaseVariationOutgoings__mdt outgoingMDT : lVOutgoingsMetadata){
                system.debug('contract.get(outgoingMDT.FieldReferenceAPIName__c) : ' + contract.get(outgoingMDT.FieldReferenceAPIName__c));
                
                if(contract.get(outgoingMDT.FieldReferenceAPIName__c) != null
                    && (Decimal) contract.get(outgoingMDT.FieldReferenceAPIName__c) > 0 
                    && prodCategoryPbeListMap.containsKey(outgoingMDT.OutgoingName__c)){
                        
                    system.debug(' prodCategoryPbeListMap.get(outgoingMDT.OutgoingName__c) : ' +  prodCategoryPbeListMap.get(outgoingMDT.OutgoingName__c));
                    
                    newOppLineItemTemp 
                        = generateOutoings(opportunity, prodCategoryPbeListMap.get(outgoingMDT.OutgoingName__c), effectiveDate);
                        
                    if(newOppLineItemTemp != null){
                        newOppLineItemTemp.TechIsClone__c = true;
                        newOppLineItemList.add(newOppLineItemTemp);
                    }
                }
            }
            
            oldOLIForDeleteList = oldOppLineItemList;
            system.debug('newOppLineItemList : ' + newOppLineItemList);
        } else {
            for(OpportunityLineItem oldOppLineItem : oldOppLineItemList){
                priceBookEntryTemp = null;
                
                if(priceBookEntryListMap.containsKey(oldOppLineItem.PriceBookEntry.Name)){
                    newOppLineItemTemp 
                        = generateOutoings(opportunity, priceBookEntryListMap.get(oldOppLineItem.PriceBookEntry.Name), effectiveDate);
                }
                
                if(newOppLineItemTemp != null && newOppLineItemTemp.PriceBookEntryId != oldOppLineItem.PriceBookEntryId){
                    newOppLineItemTemp.TechIsClone__c = true;
                    
                    newOppLineItemList.add(newOppLineItemTemp);
                    oldOLIForDeleteList.add(oldOppLineItem);
                }
            }
        }
        
        try{
            Database.update(opportunity);
            isSuccess = true;
        } catch(Exception e){
            isSuccess = false;
            errorHandler.createError(e);
        }
        
        if(isSuccess && newOppLineItemList != null && newOppLineItemList.size() > 0){
            try{

                Database.insert(newOppLineItemList);
                isSuccess = true;
            } catch(Exception e){
                isSuccess = false;
                errorHandler.createError(e);
            }
        }
        
        if(isSuccess && oldOLIForDeleteList != null && oldOLIForDeleteList.size() > 0){
            try{
                Database.delete(oldOLIForDeleteList);
                isSuccess = true;
            } catch(Exception e){
                isSuccess = false;
                errorHandler.createError(e);
            }
        }
        
        errorHandler.save();
    }
    
    public static OpportunityLineItem generateOutoings(Opportunity opportunity, List<PriceBookEntry> priceBookEntryList, Date effectiveDate){
        Boolean doCreateOutgoing = true;
        PriceBookEntry priceBookEntryTemp = null;
        OpportunityLineItem oppLineItemTemp = null;
        
        for(PriceBookEntry pBEntry : priceBookEntryList){
            if(opportunity.ParentOpportunity__r.Name.containsIgnoreCase(Constants.JDE_LEASE)){
                doCreateOutgoing = doCreateOutgoing(pBEntry, opportunity);
            }
            
            if(doCreateOutgoing){
                if(pBEntry.EffectiveToDate__c != null 
                    && pBEntry.EffectiveFromDate__c != null
                    && effectiveDate >= pBEntry.EffectiveFromDate__c 
                    && effectiveDate <= pBEntry.EffectiveToDate__c){
                    priceBookEntryTemp = pBEntry;
                } else if(pBEntry.EffectiveToDate__c == null
                    && (priceBookEntryTemp == null 
                        || (priceBookEntryTemp.EffectiveToDate__c == null 
                            && effectiveDate >= pBEntry.EffectiveFromDate__c))){
                    priceBookEntryTemp = pBEntry;
                }
            }
        }
        
        if(priceBookEntryTemp != null){
            oppLineItemTemp = OpportunityLineItemController.createOTGOppLineItem(opportunity, priceBookEntryTemp, null);
        }
        
        return oppLineItemTemp;
    }
    
    public static Boolean doCreateOutgoing(PriceBookEntry pBookEntry, Opportunity opportunity){
        Boolean doCreateOutgoing = true;
        
        if(!(String.isNotBlank(opportunity.Property__r.ApplicableOutgoings__c) && opportunity.Property__r.ApplicableOutgoings__c.containsIgnoreCase(pBookEntry.Product2.OutgoingsCategory__c))
            || !(String.isNotBlank(opportunity.Space__r.ApplicableOutgoings__c) && opportunity.Space__r.ApplicableOutgoings__c.containsIgnoreCase(pBookEntry.Product2.OutgoingsCategory__c))
            || !(String.isNotBlank(pBookEntry.Product2.DealType__c) && pBookEntry.Product2.DealType__c.containsIgnoreCase(opportunity.DealType__c))
            || !(String.isNotBlank(pBookEntry.Product2.SpaceBillingCategory__c) && pBookEntry.Product2.SpaceBillingCategory__c.containsIgnoreCase(opportunity.Space__r.BillingCategory__c))
            || !(String.isNotBlank(pBookEntry.Product2.SpaceType__c) && pBookEntry.Product2.SpaceType__c.containsIgnoreCase(opportunity.Space__r.Type__c))
            || pBookEntry.CurrencyIsoCode != opportunity.CurrencyIsoCode){
            doCreateOutgoing = false;
        }
        
        return doCreateOutgoing;
    }
}