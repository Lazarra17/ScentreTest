public class OpportunityBL {
    
    private static Map<String, Schema.RecordTypeInfo> opcRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OPPORTUNITY);
    
    public class OppLineItemWrapper {
        public Opportunity opportunityRecord;
        public Opportunity oldOpportunityRecord; // RPP-10674
        public String opportunityRecordtypeName;
        public Map<Id, Property__c> propertyMap;
        public Map<Id, PrecedentClause__c> nationalAgreementClauseMap;
        public Map<Id, Id> topParentAccountMap;
        public Map<String, PricebookEntry> productNameandPricebookEntryMap;
        public OppLineItemWrapper() {
            opportunityRecordtypeName = CONSTANTS.EMPTY;
            OpportunityRecord = new Opportunity();
        }
        public List<OpportunityLineItem> oppLineItemDel;
        public List<OpportunityLineItem> oppLineItemIns;
        public Decimal PromoMarketingPrice;
    }
    
    /*
*  @author:         Kyle Tan
*  @parameters:      opportunityRecord           - used to get opportunity details for the opportunity clause
*                 precedentClauseRecord       - contains precedent record details to be copied to opportunity clause
*  @description:    This method is used to create the opportunity clause record from the precedent clauses of record
*/
    public static OpportunityClause__c createOpportunityClause (Opportunity opportunityRecord, PrecedentClause__c precedentClauseRecord, Id opportunityClauseRecTypeId) {
        OpportunityClause__c opportunityClauseRecord = new OpportunityClause__c();
        opportunityClauseRecord.Opportunity__c = opportunityRecord.Id;
        opportunityClauseRecord.Name = precedentClauseRecord.Name;
        opportunityClauseRecord.Type__c = precedentClauseRecord.Type__c;
        opportunityClauseRecord.ClauseDetails__c = precedentClauseRecord.Description__c;
        //opportunityClauseRecord.LeasingComment__c = precedentClauseRecord.Comments__c;
        opportunityClauseRecord.EffectiveToDate__c = precedentClauseRecord.EffectiveToDate__c;
        opportunityClauseRecord.TechPrecedentClauseId__c = precedentClauseRecord.Id;
        opportunityClauseRecord.RecordTypeId = opportunityClauseRecTypeId;
        opportunityClauseRecord.IsAutomated__c = true;
        //START : KT RPP-7761 11.7.2018
        
        if(precedentClauseRecord.ReferencedClause__c != null) {
            opportunityClauseRecord.ReferencedClause__c = precedentClauseRecord.ReferencedClause__c;
            opportunityClauseRecord.RiskApplies__c = precedentClauseRecord.ReferencedClause__r.RiskApplies__c;
            opportunityClauseRecord.ReasonRecommendation__c = precedentClauseRecord.ReferencedClause__r.ReasonRecommendation__c;
        }
        //END : KT RPP-7761 11.7.2018
        return opportunityClauseRecord;
    }
    /*
*  @author:        pkumarlg
*  @parameters:    opportunity 
*  @description:   method to calculate proposed end date based on proposedstartdate and terms (year, month and day)
*/
    public static Date CalculateProposedEndDate(Opportunity newOpportunity){
        Date proposedenddate=newOpportunity.ProposedStartDate__c;
        if(newOpportunity.ProposedStartDate__c!=null){
            
            if(newOpportunity.TermYr__c!=null){
                proposedenddate=proposedenddate.addYears(newOpportunity.TermYr__c.intValue());
            }
            if(newOpportunity.TermMonths__c!=null){
                proposedenddate=proposedenddate.addMonths(newOpportunity.TermMonths__c.intValue());
            }
            if(newOpportunity.TermDays__c!=null){
                proposedenddate=proposedenddate.addDays(newOpportunity.TermDays__c.intValue());
            }
            if(proposedenddate>newOpportunity.ProposedStartDate__c){
                proposedenddate = proposedenddate.addDays(-1);
            }
        }
        return proposedenddate;
    }
    /*
*  @author:        Kyle Tan
*  @parameters:    accountIdSet               - used to query the accounts of the opportunity
*                  RecordTypeId               - used to get the property level records
*  @description:   This method is used to create the map that contains the property level account as key
*                  and the group level account as value
*/
    public static Map<Id, Id> buildTopParentAccountMap (Set<Id> accountIdSet, Id recordTypeId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityBL.class.getName());
        Map<Id, Id> topParentAccountMap = new Map<Id, Id>();
        
        try{
            for(Account accountRecord : DatabaseSOQLBank.getAccount(accountIdSet, recordTypeId)) {
                if(accountRecord.ParentId != null) {
                    topParentAccountMap.put(accountRecord.Id, accountRecord.ParentId);
                }
            }
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        
        errorHandler.save();
        return topParentAccountMap;
    }
    
    /*
*  @author:        Kyle Tan
*  @parameters:    topParentAccountMap               - used to get the group level accounts from the property level
*  @description:   This method is used to create the map that contains the precedent clause of the group level account
*/
    public static Map<Id, List<PrecedentClause__c>> buildAccountPrecedentClauseMap (Map<Id, Id> topParentAccountMap, Id recordTypeId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityBL.class.getName());
        Map<Id, List<PrecedentClause__c>> accountPrecedentClauseMap = new Map<Id, List<PrecedentClause__c>>();
        try{
            for(PrecedentClause__c precedentClauseRecord : DatabaseSOQLBank.getPrecedentClauseOfAccount(topParentAccountMap.values(), recordTypeId)) {
                if(accountPrecedentClauseMap.containsKey(precedentClauseRecord.Account__c)) {
                    accountPrecedentClauseMap.get(precedentClauseRecord.Account__c).add(precedentClauseRecord);
                } else {
                    accountPrecedentClauseMap.put(precedentClauseRecord.Account__c, new List<PrecedentClause__c>{precedentClauseRecord});
                }
            }
        }catch(Exception e) {
            errorHandler.createError(e);
        }
        
        errorHandler.save();
        return accountPrecedentClauseMap;
    }

    /*  Author : Aakash Soor
        // RPP - 5521 - Update the Tech Budget fields if opportunity is not yet Deal Achieved or is not yet (submitted for approval)/ approved.
    */
    public static void populateTechBudgetFields(Opportunity newOppty){
        if(!(Constants.BUDGET_LOCK_APPROVAL_STATUS.contains(newOppty.ApprovalStatus__c)
            || newOppty.DealAchieved__c)){
            newOppty.Tech_JV_Budget_Capital__c = newOppty.JVBudgetCapital__c;
            newOppty.Tech_JV_Budget_Rent__c = newOppty.JVBudgetRent__c;
            newOppty.Tech_Budget_Rent__c = newOppty.BudgetRent__c;
            newOppty.Tech_Budget_Capital__c = newOppty.BudgetCapital__c;
        }
    }

    public static List<OpportunityLineItem> createOpportunityProducts(Opportunity opportunityRecord, List<Product2> productsList, String opportunitySpaceType, Decimal opportunitySpaceUsableArea, Map<Id,Map<Id,PriceBookEntry>> priceBookProductIdMap) {
        List<OpportunityLineItem> opportunityProductsList = new List<OpportunityLineItem>();
        OpportunityLineItem opportunityProductRecord;
        for(Product2 productRecord : productsList) {
            opportunityProductRecord = new OpportunityLineItem();
            opportunityProductRecord.OpportunityId = opportunityRecord.Id;
            opportunityProductRecord.Product2Id = productRecord.Id;
            opportunityProductRecord.UnitPrice = productRecord.DefaultPrice__c;
            if(priceBookProductIdMap.containsKey(productRecord.Id)){
                Map<Id,PriceBookEntry> pbpbEntryMap = priceBookProductIdMap.get(productRecord.Id);
                
                
                if(pbpbEntryMap.containsKey(opportunityRecord.pricebook2id)){
                    opportunityProductRecord.PricebookEntryId = pbpbEntryMap.get(opportunityRecord.pricebook2id).id;
                    opportunityProductRecord.UnitPrice = pbpbEntryMap.get(opportunityRecord.pricebook2id).UnitPrice;
                }
            }
            opportunityProductRecord.IsActive__c = productRecord.IsActive;
            opportunityProductRecord.Description = productRecord.Description;
            
            
            if (opportunitySpaceUsableArea != NULL && opportunitySpaceUsableArea > 0) {
                opportunityProductRecord.Quantity = opportunitySpaceUsableArea;
            }
            if (!(opportunitySpaceType == CONSTANTS.NUMBER_TWO && productRecord.Name.contains(CONSTANTS.PRODUCT_AIR_CON))) {
                opportunityProductsList.add(opportunityProductRecord);
            }
        }
        return opportunityProductsList;
    }
    
    public static Map<String, List<Product2>> mapProductByDealType(Set<String> opportunityDealTypeSet, List<Product2> productList) {
        Map<String, List<Product2>> productMap  = new Map<String, List<Product2>>();
        
        for (String opportunityDealType : opportunityDealTypeSet) {
            List<Product2> productListTemp = new List<Product2>();
            for (Product2 productRecord : productList) {
                if (productRecord.Name.contains(CONSTANTS.DASH_NO_SPACE +CONSTANTS.BLANK_SPACE+opportunityDealType)) {
                    productListTemp.add(productRecord);
                }
            }
            productMap.put(opportunityDealType, productListTemp);
        }
        return productMap;
    }

    public static Map<Id,PriceBookEntry> filterPriceBookEntryByName(List<PricebookEntry> pbEntryList, String entryName){
        Map<Id,PriceBookEntry> priceBookEntryMap = new Map<Id,PriceBookEntry>();
        for(PricebookEntry pbe : pbEntryList){
            if(pbe.Name == entryName){
                priceBookEntryMap.put(pbe.Pricebook2Id, pbe);
            }
        }
        return priceBookEntryMap;
    }
    
    public static Map<Id,Map<Id,PriceBookEntry>> mapPBEntryByProduct(List<Product2> productList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityBL.class.getName());
        List<PriceBookEntry> pbEntryList = new List<PriceBookEntry>();
        try{
            pbEntryList = DatabaseSOQLBank.getPriceBookEntry(productList);
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        Map<Id,Map<Id,PriceBookEntry>> productPBEntryIdMap = new Map<Id,Map<Id,PriceBookEntry>>();
        for(Product2 prd : productList){
            for(PriceBookEntry pbentry : pbEntryList){
                if(pbentry.product2id == prd.id){
                    if(productPBEntryIdMap.containsKey(prd.id)){
                        productPBEntryIdMap.get(prd.id).put(pbentry.pricebook2id,pbentry);   
                    }else{
                        productPBEntryIdMap.put(prd.id, new Map<Id, PriceBookEntry>());
                        productPBEntryIdMap.get(prd.id).put(pbentry.pricebook2id,pbentry);
                    }
                }
            }
        }
        errorHandler.save();
        return productPBEntryIdMap;
    }
    
    /*
*  @author:        Kyle Tan
*  @parameters:    topParentAccountMap               - used to get the national agreement precedent clauses
*                  RecordTypeId                      - contains the record type of the precedent clause to be queried
*  @description:   This method builds the map that contains national agreement of the parent account
*/
    public static Map<Id, PrecedentClause__c> buildNationalAgreementClauseMap(Map<Id, Id> topParentAccountMap, Id recordTypeId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityBL.class.getName());
        Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
        
        try{
            for(PrecedentClause__c precedentClauseRecord : DatabaseSOQLBank.getPrecedentClauseOfAccount(topParentAccountMap.values(), recordTypeId)) {
                // if(String.isNotBlank(precedentClauseRecord.StandardReviewTypes__c)) {
                nationalAgreementClauseMap.put(precedentClauseRecord.Account__c, precedentClauseRecord);
                // }
            }
            System.debug('DEBUG');
        } catch(Exception e) {
            errorHandler.createError(e);
        } 
        errorHandler.save();
        return nationalAgreementClauseMap;
    }

    /*
    *  @author:             Kyle Tan
    *  @parameters:         productName             -used to determine which product to create
    *                       wrapperRecord        -contains fields of the opportunity line item
    *                       pbEntry              - contains PriceBookEntry for Product // LF RPP-10151 9.5.2019
    *  @description:        this method creates opportunity line item records based on the term year of the opportunity inserted               
    */
    public static List<OpportunityLineItem> createReviewsforOpportunity(Map<Id, Double> opptyWithRent, OppLineItemWrapper wrapperRecord, String productName, PriceBookEntry pbEntry) {
        // RPP - 10674 moved the whole method under method createUpdateReviewsforOpportunity.
        return createUpdateReviewsforOpportunity(opptyWithRent.get(wrapperRecord.opportunityRecord.Id), wrapperRecord, productName, pbEntry, null);
    }

    // RPP - 10674
    public static List<OpportunityLineItem> getFilteredOpptyLineItems( List<OpportunityLineItem> opptyLineItems , String productName){
        List<OpportunityLineItem> filteredList = new List<OpportunityLineItem>();
        if(opptyLineItems != null){
            for(OpportunityLineItem item : opptyLineItems){
                if(item.ProductFamily__c == productName){
                    filteredList.add(item);
                }
            }
        }
        return filteredList;
    }
    
    public static Integer getCounter(Integer years,Integer months, Integer days, String oppPropName, String storeRoomRecordTypeId, String oppRecordTypeId){
        Integer counter = 0;
        if(years > 1 
            || (years == 1 
                && (months > 0 || days > 0)) ){
            counter = Integer.valueOf(years);
            if(months > 0 || days > 0){
                counter++;
            }
        }else if(oppPropName == Constants.AUSTRALIA  
            && storeRoomRecordTypeId == oppRecordTypeId){
            if((years == 0 
                    && (months > 0 || days > 0)) 
                || (years == 1 
                    && (months == 0 || days == 0))){
                counter = 2;
            }
        }
        return counter;
    }

    //RPP-10674
    /*
    *  @author:             Aakash Soor
    *  Ticket:              RPP-10674
    *  @description:        this method updates/inserts existing opportunity line item records based on Annual Minimum rent, Proposed Start Date and Term.
    */
    public static List<OpportunityLineItem> createUpdateReviewsforOpportunity(Double rentAmount, OppLineItemWrapper wrapperRecord, String productName, PriceBookEntry pbEntry, List<OpportunityLineItem> opptyVsLineItems){
        //Check if this is an upsert request or insert
        List<OpportunityLineItem> existingOLI = getFilteredOpptyLineItems(opptyVsLineItems,productName);
        system.debug('existingOLI------------'+existingOLI.size());
        Boolean isUpsert = false;
        if(!existingOLI.isEmpty()) isUpsert = true;

        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        if(wrapperRecord.opportunityRecord.TermYr__c != NULL || wrapperRecord.opportunityRecord.TermMonths__c != NULL || wrapperRecord.opportunityRecord.TermDays__c != NULL ) {
            Decimal amortizedRent=0;
            Date proposedStartDate = wrapperRecord.OpportunityRecord.ProposedStartDate__c;
            String reviewType = null;
            String standReviewType = null;
            String cpiType = null;
            /*//Added by Abhishek M: RPP-10527
            Map<String, Double> rentInfo = OpportunityLineItemController.getRentInfo(wrapperRecord.opportunityRecord.Id, 
                                                        wrapperRecord.opportunityRecord.AnnualMinimumRent__c,
                                                        0,
                                                        0,
                                                        Constants.YES.equalsIgnoreCase(wrapperRecord.opportunityRecord.PromoLevyIncluded__c) ? TRUE : FALSE,
                                                        wrapperRecord.opportunityRecord.DealType__c,
                                                        String.isNotEmpty(wrapperRecord.opportunityRecord.NZProperty__c) ? TRUE : FALSE,
                                                        wrapperRecord.opportunityRecord.NZProperty__c,
                                                        TRUE
                                                    );
            System.debug('rentInfo: '+rentInfo);*/

            if(wrapperRecord.opportunityRecord.AnnualMinimumRent__c!=null&&wrapperRecord.opportunityRecord.AnnualMinimumRent__c!=0){
                // amortizedRent=wrapperRecord.opportunityRecord.AnnualMinimumRent__c+((wrapperRecord.opportunityRecord.AnnualMinimumRent__c)*(Decimal.valueOf(Label.VICAmortizationPercent)));
                if(productName == Constants.PRODUCT_PROMO_REVIEW){

                   //Added by Abhishek M: RPP-10527
                   //if(wrapperRecord.opportunityRecord.TotalPromotionLevy__c == 0 && rentInfo.get('PromotionFund') != NULL && rentInfo.get('PromotionFund') != 0)
                        //wrapperRecord.PromoMarketingPrice = rentInfo.get('PromotionFund');

                    System.debug('wrapperRecord.opportunityRecord.Id: '+wrapperRecord.opportunityRecord.Id);
                    System.debug('wrapperRecord.opportunityRecord.TotalPromotionLevy__c: '+wrapperRecord.opportunityRecord.TotalPromotionLevy__c);
                    if(wrapperRecord.opportunityRecord.TotalPromotionLevy__c == 0 && rentAmount != NULL && rentAmount != 0){
                        wrapperRecord.PromoMarketingPrice = rentAmount;
                    }

                    if(wrapperRecord.PromoMarketingPrice != null && wrapperRecord.PromoMarketingPrice != 0){
                       amortizedRent=wrapperRecord.PromoMarketingPrice;
                    }else{
                        amortizedRent=wrapperRecord.opportunityRecord.TotalPromotionLevy__c;
                    }
                }else{
                    amortizedRent=wrapperRecord.opportunityRecord.AnnualMinimumRent__c;
                }
            }
            Integer years = wrapperRecord.opportunityRecord.TermYr__c != null ? wrapperRecord.opportunityRecord.TermYr__c.intValue() : 0;
            Integer months = wrapperRecord.opportunityRecord.TermMonths__c != null ? wrapperRecord.opportunityRecord.TermMonths__c.intValue() : 0;
            Integer days = wrapperRecord.opportunityRecord.TermDays__c != null ? wrapperRecord.opportunityRecord.TermDays__c.intValue() : 0;

            String oppPropName; 
            if(OpportunityTriggerHandler.opportunityMapById.containsKey(wrapperRecord.opportunityRecord.Id)){
                oppPropName = OpportunityTriggerHandler.opportunityMapById.get(wrapperRecord.opportunityRecord.Id).Property__r.Country__c;
            }
            Id oppRecordTypeId = wrapperRecord.opportunityRecord.RecordTypeId;
            Id storeRoomRecordTypeId = opcRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING_API_NAME).getRecordTypeId();  
            
            if(years > 0 || months > 0 || days > 0){
                Integer counter = 0;
                //RPP - 10674
                counter = getCounter(years, months, days, oppPropName, storeRoomRecordTypeId, oppRecordTypeId);
                system.debug('counter-----'+counter);
                //RPP - 10674
                for(Integer i = 0; i < (counter - 1); i++) {
                    OpportunityLineItem oppLineItemRec = new OpportunityLineItem();

                    // If existing records are present, update the records.
                    // If the counter is greater than the size of existing records, i.e. term has been increased, update the existing records and insert the delta term records.
                    if(isUpsert
                        && i < existingOLI.size()){
                        oppLineItemRec = existingOLI[i];
                    }else{
                        oppLineItemRec.OpportunityId = wrapperRecord.opportunityRecord.Id;
                        //10674  oppLineItemRec.CPIType__c = cpiType;
                        oppLineItemRec.Flexi_Rent__c = false;
                        oppLineItemRec.IsActive__c = true;
                        // START LF RPP-10151 9.5.2019
                        if (pbEntry != null) {
                            oppLineItemRec.PricebookEntryId = pbEntry.Id;
                            oppLineItemRec.Product2Id = pbEntry.Product2Id;
                        }
                        /*
                        if(wrapperRecord.productNameandPricebookEntryMap.containsKey(priceBookEntryMapKey)) {
                            if(wrapperRecord.productNameandPricebookEntryMap.get(priceBookEntryMapKey).Id != null || wrapperRecord.productNameandPricebookEntryMap.get(priceBookEntryMapKey).Product2Id != null) {
                                oppLineItemRec.PricebookEntryId = wrapperRecord.productNameandPricebookEntryMap.get(priceBookEntryMapKey).Id;
                                oppLineItemRec.Product2Id = wrapperRecord.productNameandPricebookEntryMap.get(priceBookEntryMapKey).Product2Id;
                            }
                        } 
                        */
                        // END LF RPP-10151 9.5.2019
                        
                        if(wrapperRecord.nationalAgreementClauseMap.containsKey(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId))) {
                            if(Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(productName)) {
                                if(wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).RentReviewDescription__c != null) {
                                    oppLineItemRec.Description = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).RentReviewDescription__c;
                                }
                                if(wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).RentReviewCappedPercent__c != null) {
                                    oppLineItemRec.CappedPercent__c = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).RentReviewCappedPercent__c;
                                }
                            } else if(Constants.PRODUCT_PROMO_REVIEW.equalsIgnoreCase(productName)) {
                                if(wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).PromoReviewDescription__c != null) {
                                    oppLineItemRec.Description = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).PromoReviewDescription__c;
                                }
                                if(wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).PromoReviewCappedPercent__c != null) {
                                    oppLineItemRec.CappedPercent__c = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).PromoReviewCappedPercent__c;
                                }
                            }
                        }
                        
                        //10674
                        system.debug('wrapperRecord.propertyMap-----------'+wrapperRecord.propertyMap.keySet());
                        system.debug('wrapperRecord.OpportunityRecord.Property__c-----------'+wrapperRecord.OpportunityRecord.Property__c);
                        if((wrapperRecord.nationalAgreementClauseMap.containsKey(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId))) 
                            && ((wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).StandardReviewTypes__c != null 
                                    && Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(productName)) 
                                || (wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).StandardPromoReviewType__c != null
                                    && Constants.PRODUCT_PROMO_REVIEW.equalsIgnoreCase(productName)))) {
                            
                            if(Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(productName)) {
                                standReviewType = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).StandardReviewTypes__c;
                                reviewType = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).RentReviewType__c;
                                System.debug('Test1'+standReviewType +'--' +reviewType);
                            } else if(Constants.PRODUCT_PROMO_REVIEW.equalsIgnoreCase(productName)) {
                                standReviewType = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).StandardPromoReviewType__c;
                                reviewType = wrapperRecord.nationalAgreementClauseMap.get(wrapperRecord.topParentAccountMap.get(wrapperRecord.OpportunityRecord.AccountId)).PromoReviewType__c;
                                System.debug('Test2'+standReviewType +'--' +reviewType);
                            }
                            cpiType = Constants.NATIONAL;
                        }else if(wrapperRecord.propertyMap.containsKey(wrapperRecord.OpportunityRecord.Property__c)
                                && ((String.isNotEmpty(wrapperRecord.propertyMap.get(wrapperRecord.OpportunityRecord.Property__c).RentReviewType__c) 
                                        && Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(productName)) 
                                    || (String.isNotEmpty(wrapperRecord.propertyMap.get(wrapperRecord.OpportunityRecord.Property__c).StandardPromoReviewType__c) 
                                        && Constants.PRODUCT_PROMO_REVIEW.equalsIgnoreCase(productName)))) {
                            
                            if(Constants.PRODUCT_RENT_REVIEW.equalsIgnoreCase(productName)) {
                                standReviewType = wrapperRecord.propertyMap.get(wrapperRecord.OpportunityRecord.Property__c).RentReviewType__c;
                                System.debug('Test3'+standReviewType +'--'+reviewType);
                            } else if(Constants.PRODUCT_PROMO_REVIEW.equalsIgnoreCase(productName)) {
                                standReviewType = wrapperRecord.propertyMap.get(wrapperRecord.OpportunityRecord.Property__c).StandardPromoReviewType__c;
                                System.debug('Test4'+standReviewType +'--' +reviewType);
                            }
                            cpiType = Constants.NATIONAL;
                        }
                        if(wrapperRecord.opportunityRecordtypeName == Constants.OPP_STORE_ROOM_LEASING) {
                            oppLineItemRec.StandardReviewType__c = Constants.FIXED_FIVE_PERCENT;
                        } else if (String.isNotBlank(standReviewType)){
                            if(Constants.NON_STANDARD.equalsIgnoreCase(standReviewType)) {
                                oppLineItemRec.StandardReviewType__c = Constants.NON_STANDARD;
                                oppLineItemRec.ReviewType__c = reviewType;
                                System.debug('Test5'+standReviewType +'--' +reviewType);
                            } else {
                                oppLineItemRec.StandardReviewType__c = standReviewType;
                                System.debug('Test6'+standReviewType +'--' +reviewType);
                            }
                        }
                        
                        oppLineItemRec.CPIType__c = cpiType;
                    }// else end

                    if(proposedStartDate != null) {
                        oppLineItemRec.EffectiveFromDate__c = proposedStartDate.addYears(i + 1);
                        if(i == (counter - 1) && (wrapperRecord.opportunityRecord.TermMonths__c > 0 || wrapperRecord.opportunityRecord.TermDays__c > 0)) {
                            oppLineItemRec.EffectiveToDate__c = proposedStartDate.addYears(i + 1);
                            oppLineItemRec.EffectiveToDate__c = oppLineItemRec.EffectiveToDate__c.addDays(-1);
                            if(wrapperRecord.opportunityRecord.TermMonths__c > 0) {
                                oppLineItemRec.EffectiveToDate__c = oppLineItemRec.EffectiveToDate__c.addMonths(Integer.valueOf(wrapperRecord.opportunityRecord.TermMonths__c));
                            }
                            if(wrapperRecord.opportunityRecord.TermDays__c > 0) {
                                oppLineItemRec.EffectiveToDate__c = oppLineItemRec.EffectiveToDate__c.addDays(Integer.valueOf(wrapperRecord.opportunityRecord.TermDays__c));
                            }
                        } else {
                            oppLineItemRec.EffectiveToDate__c = proposedStartDate.addYears(i + 2);
                            oppLineItemRec.EffectiveToDate__c = oppLineItemRec.EffectiveToDate__c.addDays(-1);
                        }
                    }
                    if(amortizedRent!=null&&amortizedRent!=0){
                        amortizedRent=amortizedRent+((amortizedRent)*(Decimal.valueOf(Label.VICAmortizationPercent)));
                    }
                    oppLineItemRec.AmortizedRent__c=amortizedRent;
                    system.debug('oppLineItemRec.CPIType__c--------'+oppLineItemRec.CPIType__c);
                    if(String.isNotEmpty(oppLineItemRec.CPIType__c)) {
                        opportunityLineItemList.add(oppLineItemRec);
                    }
                }
            }
        }
        return opportunityLineItemList;
    }
    /**
* @Author: Chen Chen
* @Parameter: successfullpublish successfull publish opportunity event
* @Description: according to the successful publish event, update the opportunity dispatch verison and timestamp
*/
    public static void updateOppoWhenOppoEventSentSuccess(List<OpportunityEvent__e> successfullpublish) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        List<Opportunity> oppoToUpdateDispatchDetailsList=new List<Opportunity>(); 
        if(!successfullpublish.isEmpty() && successfullpublish.size()>0){
            for(OpportunityEvent__e publishedEvent: successfullpublish){
                // get values from pubished event payload to update parent records
                Opportunity oppoToUpdateDispatchDetails = new Opportunity();
                Map<String, Object> publishedOppoEvents;
                try {
                    publishedOppoEvents = (Map<String, Object>)JSON.deserializeUntyped(publishedEvent.OpportunityPayload__c);
                    System.debug('publishedOppoEvents === '+publishedOppoEvents);
                } catch (Exception e) {
                    publishedOppoEvents = NULL;
                }
                
                if (publishedOppoEvents != NULL && !publishedOppoEvents.isEmpty()) {
                    oppoToUpdateDispatchDetails.id=(id)publishedOppoEvents.get(Constants.DML_ID.toUpperCase());
                    String dispatchtimestampstr=(String)publishedOppoEvents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                    oppoToUpdateDispatchDetails.TechDispatchedTimeStamp__c =DateTime.valueOf(dispatchtimestampstr);
                    String dispatchversionstr=(String)publishedOppoEvents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                    oppoToUpdateDispatchDetails.TechDispatchedVersion__c=Decimal.valueOf(dispatchversionstr);
                    oppoToUpdateDispatchDetailsList.add(oppoToUpdateDispatchDetails);
                }
            }
        }
        if(!oppoToUpdateDispatchDetailsList.isEmpty() && oppoToUpdateDispatchDetailsList.size()>0){
            try {
                Database.update(oppoToUpdateDispatchDetailsList);    
            } catch (Exception e) {
                errorHandler.createError(e);
            }
        }
    }
    
    /**
* @Author: Chen Chen
* @Parameter: payloads List of oppo payloads
* @Description: according to the successful publish event, update the opportunity dispatch verison and timestamp
*/
    public static List<OpportunityEvent__e> generateOppoEvents(List<String> payloads) {
        List<OpportunityEvent__e> oppoEvents = new List<OpportunityEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                OpportunityEvent__e oppoE = new OpportunityEvent__e();
                oppoE.OpportunityPayload__c = payload;
                oppoEvents.add(oppoE);
            }
        }
        return oppoEvents;
    }
    
    /**
* @Author: Chen Chen
* @Parameter: trigger new map
* @Description: when stage is issue lease, put it into map
*/
    public static Map<Id, Opportunity> oppoEventTriggerCriteriaCheck(Map<Id,Sobject> oppoNewMap) {
        Map<Id, Opportunity> dbOppoDataMapToPublish = new Map<Id, Opportunity>();
        //Map<Id, Opportunity> dbOppodataMap = new Map<Id, Opportunity>([Select id, StageName, JDESentStatus__c from Opportunity where id IN :oppoNewMap.keySet()]); //SOQL FIX - 12
        Map<Id, Opportunity> dbOppodataMap = (Map<Id, Opportunity>) oppoNewMap; //SOQL FIX - 12
        for(Opportunity oppoRecord: dbOppodataMap.values()){
            if(oppoRecord.StageName != null && oppoRecord.JDESentStatus__c == Constants.OPPO_JDE_STATUS_READY){
                dbOppoDataMapToPublish.put(oppoRecord.id, oppoRecord);
            }
        }
        
        return dbOppoDataMapToPublish;
    }
    
    public static List<OpportunityClause__c> updateOpportunityClause(Map<Id,Opportunity> opportunityMap){
        List<OpportunityClause__c> clausetoupdateList=new List<OpportunityClause__c>();
        for(OpportunityClause__c opportunityClauseRecord: [select Id,RiskApplies__c from OpportunityClause__c where Opportunity__c in:opportunityMap.keySet()]){
            //if(opportunityClauseRecord.RiskApplies__c){
            opportunityClauseRecord.Approved__c=true;
            clausetoupdateList.add(opportunityClauseRecord);
            //}
        }
        return clausetoupdateList;
    }
    public static Opportunity getUpdatedRoleOpportunity(Set<String> thresholdApprStatusSet,
                                                        Opportunity opp,OpportunityApprovalMatrix__mdt oppAppMatr,Map<String, Id> roleUserMap,Set<String> allowedRetTypes,Set<String> roleSet, 
                                                        String rectypeName, Set<String> initFinalAttrTypes){
                                                            Map<Id, Schema.RecordTypeInfo> oppRecordTypeById;       
                                                            oppRecordTypeById = RecordTypeUtil.getAllRecordTypesById(Constants.OPPORTUNITY);
                                                            String newOppRecordTypeName;
                                                            List<String> rangeRentDigits = new List<String>();
                                                            List<String> rangeCapitalDigits = new List<String>();
                                                            List<Id> propIdLst = new List<Id>();
                                                            Decimal cmRentfirst;
                                                            Decimal cmRentSecond;
                                                            Decimal cmCapfirst;
                                                            Decimal cmCapSecond;    
                                                            Decimal oppRentVariance;
                                                            Decimal oppRentVariancePlus = 0;
                                                            Decimal oppRentVarianceField = 0;
                                                            Decimal oppCapitalVariance;
                                                            
                                                            Boolean addToOpportunityField = false;
                                                            Set<String> finalStatusSet = new Set<String>{constants.INIAPPR_GRANTED,constants.RSKAPPR_GRANTED,constants.RMAPPR_GRANTED,constants.RMRISK_APPRGRANTED, constants.PEND_FINALAPPROV,constants.FINALAPPR_REJ};
                                                                List<String> rangeRentAmtDigits = new List<String>();
                                                            List<String> rangeCapitalAmtDigits = new List<String>();
                                                            Decimal cmRentAmtfirst;
                                                            Decimal cmRentAmtSecond;
                                                            Decimal cmCapAmtfirst;
                                                            Decimal cmCapAmtSecond;    
                                                            Decimal oppRentVarianceAmount;
                                                            Decimal oppCapitalVarianceAmount;
                                                            
                                                            if(opp.DealAchieved__c != true && ((opp.AcceptedDisclosureStatement__c == false && (String.isBlank(opp.approvalStatus__c) || opp.approvalStatus__c == constants.INI_APPV_REJ)) 
                                                                                               || opp.AcceptedDisclosureStatement__c == true) && (opp.Property__r.Tier__c == oppAppMatr.Tier__c || oppAppMatr.Tier__c == constants.TIER_ALL) && 
                                                               (thresholdApprStatusSet.contains(opp.approvalStatus__c) || String.isBlank(opp.approvalStatus__c)) && 
                                                               
                                                               (((opp.approvalStatus__c == constants.INI_APPV_REJ || String.isBlank(opp.approvalStatus__c)) && 
                                                                 (oppAppMatr.type__c == constants.RETAILINITAPPROVAL || oppAppMatr.type__c == constants.COMMINITAPPROVAL)) ||
                                                                ((finalStatusSet.contains(opp.approvalStatus__c)) && 
                                                                 (oppAppMatr.type__c == constants.RET_FINALAPPROVAL || oppAppMatr.type__c == constants.COMMFINALAPPROVAL))) && 
                                                               
                                                               (initFinalAttrTypes.contains(oppAppMatr.type__c)) && roleUserMap.containskey(oppAppMatr.role__c)){
                                                                   rangeRentDigits.clear();
                                                                   rangeCapitalDigits.clear();
                                                                   cmRentfirst = 0;
                                                                   cmRentSecond = 0;
                                                                   cmCapfirst = 0;
                                                                   cmCapSecond = 0;
                                                                   rangeRentAmtDigits.clear();
                                                                   rangeCapitalAmtDigits.clear();
                                                                   cmRentAmtfirst = 0;
                                                                   cmRentAmtSecond = 0;
                                                                   cmCapAmtfirst = 0;
                                                                   cmCapAmtSecond = 0;
                                                                   oppRentVariance = opp.RentVariance__c;
                                                                   oppCapitalVariance = opp.CapitalVariance__c;
                                                                   if(String.isNotBlank(oppAppMatr.rentRange__c)){
                                                                       rangeRentDigits = ((oppAppMatr.rentRange__c).replaceAll( '\\s+', '')).split('to');
                                                                       if(rangeRentDigits.size()>0){
                                                                           cmRentfirst = decimal.valueof(rangeRentDigits[0]);
                                                                           cmRentSecond = decimal.valueof(rangeRentDigits[1]);
                                                                       }
                                                                   }
                                                                   if(String.isNotBlank(oppAppMatr.capitalRange__c)){
                                                                       rangeCapitalDigits = ((oppAppMatr.capitalRange__c).replaceAll( '\\s+', '')).split('to');
                                                                       if(rangeCapitalDigits.size()>0){
                                                                           cmCapfirst = decimal.valueof(rangeCapitalDigits[0]);
                                                                           cmCapSecond = decimal.valueof(rangeCapitalDigits[1]);
                                                                       }
                                                                   }
                                                                   
                                                                   oppRentVarianceAmount = opp.RentVarianceAmount__c;
                                                                   oppCapitalVarianceAmount = opp.CapitalVarianceAmount__c;
                                                                   if(String.isNotBlank(oppAppMatr.rentAmountRange__c)){
                                                                       rangeRentAmtDigits = ((oppAppMatr.rentAmountRange__c).replaceAll( '\\s+', '')).split('to');
                                                                       if(rangeRentAmtDigits.size()>0){
                                                                           cmRentAmtfirst = decimal.valueof(rangeRentAmtDigits[0]);
                                                                           cmRentAmtSecond = decimal.valueof(rangeRentAmtDigits[1]);
                                                                       }
                                                                   }
                                                                   if(String.isNotBlank(oppAppMatr.capitalAmountRange__c)){
                                                                       rangeCapitalAmtDigits = ((oppAppMatr.capitalAmountRange__c).replaceAll( '\\s+', '')).split('to');
                                                                       if(rangeCapitalAmtDigits.size()>0){
                                                                           cmCapAmtfirst = decimal.valueof(rangeCapitalAmtDigits[0]);
                                                                           cmCapAmtSecond = decimal.valueof(rangeCapitalAmtDigits[1]);
                                                                       }
                                                                   }
                                                                   
                                                                   if((rangeRentDigits.size()>0 &&  oppRentVariance >= cmRentfirst && oppRentVariance <= cmRentSecond) ||
                                                                      (rangeCapitalDigits.size()>0 && oppCapitalVariance >= cmCapfirst && oppCapitalVariance <= cmCapSecond) ||
                                                                      (rangeRentAmtDigits.size()>0 &&  oppRentVarianceAmount >= cmRentAmtfirst && oppRentVarianceAmount <= cmRentAmtSecond) ||
                                                                      (rangeCapitalAmtDigits.size()>0 && oppCapitalVarianceAmount >= cmCapAmtfirst && oppCapitalVarianceAmount <= cmCapAmtSecond)){
                                                                          //opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.role__c));
                                                                          addToOpportunityField = true;  
                                                                      }
                                                                   
                                                               }else if(opp.NoofUnApprovedClause__c > 0 && allowedRetTypes.contains(oppAppMatr.type__c) && roleSet.contains(oppAppMatr.role__c) && roleUserMap.containskey(oppAppMatr.role__c)){
                                                                   addToOpportunityField = true;
                                                               }/*else if(!(thresholdApprStatusSet.contains(opp.approvalStatus__c)) && oppAppMatr.type__c.contains(rmtype) && roleUserMap.containskey(oppAppMatr.role__c)){
addToOpportunityField = true;
}*/
                                                            
                                                            if(addToOpportunityField){
                                                                if(opp.Space__r.Status__c == constants.SPACE_STATUS_PROJECT && roleUserMap.containskey(oppAppMatr.projectrole__c)){
                                                                    opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.projectrole__c));
                                                                }else if (roleUserMap.containskey(oppAppMatr.role__c)){
                                                                    opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.role__c));
                                                                }
                                                            }
                                                            return opp;
                                                        }
    
    public static Opportunity getRoleStoreRoomOpportunity(Opportunity opp,OpportunityApprovalMatrix__mdt oppAppMatr,Map<String, Id> roleUserMap, String usrrolename, String usrProfilename){
        if(oppAppMatr.type__c == CONSTANTS.SRMLCNSAPPROV && roleUserMap.containskey(oppAppMatr.role__c)){
            
            
            if(roleUserMap.containskey(constants.TEAM_ROLE_RETAILMANAGER) && roleUserMap.get(constants.TEAM_ROLE_RETAILMANAGER) == userinfo.getuserid() && oppAppMatr.fieldAPIName__c == CONSTANTS.API_CENTREMGR){
                opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.role__c));
            }else if(!(roleUserMap.containskey(constants.TEAM_ROLE_RETAILMANAGER) && roleUserMap.get(constants.TEAM_ROLE_RETAILMANAGER) == userinfo.getuserid()) && oppAppMatr.fieldAPIName__c == CONSTANTS.API_RETMGR){
                opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.role__c));
            }
            //system.assertnotequals(2,2);
            
            
            /* if(usrrolename == CONSTANTS.TEAM_ROLE_LEASMGR && (oppAppMatr.fieldAPIName__c == CONSTANTS.API_RETMGR || oppAppMatr.fieldAPIName__c == CONSTANTS.API_CENTREMGR)){
opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.role__c));
}else if(usrProfilename == CONSTANTS.SCGRETCENTREMGT && oppAppMatr.fieldAPIName__c == CONSTANTS.API_CENTREMGR){
opp.put(oppAppMatr.fieldAPIName__c,roleUserMap.get(oppAppMatr.role__c));
}   */
        }
        return opp;
    }
    
    public static List<OpportunityLineItem> updateOppLineItemDate(Opportunity newOpportunity, Opportunity oldOpportunity, Map<Id, List<OpportunityLineItem>> OpportunityLineItemMap) {
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        if(newOpportunity.ProposedRentCommencementDate__c!=null && newOpportunity.ProposedRentCommencementDate__c != oldOpportunity.ProposedRentCommencementDate__c){
            if(opportunityLineItemMap.containsKey(newOpportunity.Id)) {
                List<OpportunityLineItem> oppLineItemtoUpdateList = new List<OpportunityLineItem>();
                for(OpportunityLineItem oppLineItemRec : opportunityLineItemMap.get(newOpportunity.Id)) {
                    if(oppLineItemRec.Product2.Family==Constants.RECOVERIES){
                        oppLineItemtoUpdateList.add(oppLineItemRec);
                    }
                }
                oppLineItemList.addAll(OpportunityLineItemBL.updateOppLineItems(newOpportunity, oppLineItemtoUpdateList));
            }
        }
        return oppLineItemList;
    }

    //SOQL FIX - 5
    public static Map<Id,Account> getAccountMap(Map<Id, Opportunity> opportunityMapById){
        Map<Id,Account> accountMap = new Map<Id,Account>();
        for(Opportunity opp : opportunityMapById.values()){
            accountMap.put(opp.AccountId,(Account)opp.getSobject('Account'));
        }
        return accountMap;
    }

    public static Set<Id> opptyWithSecurityDepositUpdationRequired(Map<Id, Opportunity> oldOpps, Map<Id, Opportunity> newOpps){
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity newOpp : newOpps.values()){ 
            if(((newOpp.AnnualMinimumRent__c != oldOpps.get(newOpp.Id).AnnualMinimumRent__c 
                        && newOpp.AnnualMinimumRent__c > 0) 
                    || (newOpp.SecurityDepositMonths__c != oldOpps.get(newOpp.Id).SecurityDepositMonths__c 
                        && newOpp.SecurityDepositMonths__c > 0) 
                    || (newOpp.SecurityDepositWeeks__c != oldOpps.get(newOpp.Id).SecurityDepositWeeks__c 
                        && newOpp.SecurityDepositWeeks__c > 0) 
                    || (newOpp.SecurityDepositDays__c != oldOpps.get(newOpp.Id).SecurityDepositDays__c 
                        && newOpp.SecurityDepositDays__c > 0))
                && (newOpp.SecurityDepositMonths__c > 0 
                    || newOpp.SecurityDepositWeeks__c > 0 
                    || newOpp.SecurityDepositDays__c > 0)
                && !newOpp.DealAchieved__c){
                
                oppIds.add(newOpp.Id);
           }
        }
        return oppIds;
    }
    
    public static Decimal updateSecurityDeposit(Opportunity updateOpportunity, Map<Id, Id> topParentAccountMap, Map<Id, PrecedentClause__c> nationalAgreementClauseMap, Map<Id, Account> accountMap, Map<Id, Property__c> propertyMap, List<GST__mdt> GSTList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityBL.class.getName());
        Boolean calculate = false;
        Decimal securityDeposit = 0;
        if(topParentAccountMap.containsKey(updateOpportunity.AccountId) && nationalAgreementClauseMap.containsKey(topParentAccountMap.get(updateOpportunity.AccountId))) {
            if(Constants.YES.equalsIgnoreCase(nationalAgreementClauseMap.get(topParentAccountMap.get(updateOpportunity.AccountId)).SecurityDepositRequired__c)||String.isBlank(nationalAgreementClauseMap.get(topParentAccountMap.get(updateOpportunity.AccountId)).SecurityDepositRequired__c)){
                calculate = true;
            }
        } else {
            if(accountMap.containsKey(updateOpportunity.AccountId)) {
                calculate = true;
            }
        }
        if(calculate) {
            Decimal holder = 0;
            Decimal sum = 0;
            Decimal totalPromoLevy = (updateOpportunity.TotalPromotionLevy__c != null) ? updateOpportunity.TotalPromotionLevy__c : 0;
            Decimal totalOutgoings = (updateOpportunity.TotalOutgoings__c != null) ? updateOpportunity.TotalOutgoings__c : 0;
            Decimal annualMinimumRent = (updateOpportunity.AnnualMinimumRent__c != null) ? updateOpportunity.AnnualMinimumRent__c : 0;
            Decimal GST = 0;
            if(propertyMap.containsKey(updateOpportunity.Property__c) && GSTList != null && GSTList.size() > 0) {
                for(GST__mdt tempGST :GSTList) {
                    if(Constants.AUSTRALIA.equalsIgnoreCase(propertyMap.get(updateOpportunity.Property__c).Country__c) && Constants.GST.equalsIgnoreCase(tempGST.DeveloperName)) {
                        GST = tempGST.GSTAmount__c / 100;
                    } else if(Constants.NEW_ZEALAND.equalsIgnoreCase(propertyMap.get(updateOpportunity.Property__c).Country__c) && Constants.GST_NEW_ZEALAND.equalsIgnoreCase(tempGST.DeveloperName)) {
                        GST = tempGST.GSTAmount__c / 100;
                    }
                }
            }
            if(updateOpportunity.SecurityDepositMonths__c != null && updateOpportunity.SecurityDepositMonths__c > 0) {
                holder = updateOpportunity.SecurityDepositMonths__c / 12.00;
            } else if(updateOpportunity.SecurityDepositWeeks__c != null && updateOpportunity.SecurityDepositWeeks__c > 0) {
                holder = updateOpportunity.SecurityDepositWeeks__c / 52.00;
            } else if(updateOpportunity.SecurityDepositDays__c != null && updateOpportunity.SecurityDepositDays__c > 0) {
                holder = updateOpportunity.SecurityDepositDays__c / 365.00;
            }
            if(holder != null && holder > 0) {
                sum = ((annualMinimumRent + totalPromoLevy + totalOutgoings) * holder);
            }
            if(sum > 0 && sum != null) {
                securityDeposit = sum + (sum * GST);
            } else {
                securityDeposit = 0;
            }
        } else {
            securityDeposit = 0;
        }
        securityDeposit = securityDeposit.setScale(2);
        errorHandler.save();
        return securityDeposit;
    }
    
    public static List<OpportunityContactRole> createOppContactRoles(Opportunity newOpportunity, Map<Id, List <Affiliation__c>> affiliationsMap) {
        List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
        if(affiliationsMap.containsKey(newOpportunity.AccountId)) {
            for(Affiliation__c affRec : affiliationsMap.get(newOpportunity.AccountId)) {
                if((affRec.Contact__c != null) && (Constants.CURRENT.equalsIgnoreCase(affRec.Status__c)) && (Constants.COMP_PERSONAL_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.COMP_PARENT_GUARANTEES.equalsIgnoreCase(affRec.Type__c) || Constants.PERSONAL_GUARANTEES_FRANCHISEE.equalsIgnoreCase(affRec.Type__c))) {
                    oppContactRoleList.add(SecurityController.createOpportunityContactRole(affRec.Type__c, affRec.Contact__c, newOpportunity.Id));
                }
            }
        }
        return oppContactRoleList;
    }
    
    public static Boolean checkForecastFieldChanges(Opportunity newOpp, Opportunity oldOpp, Set<String> forecastFieldSet) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityBL.class.getName());
        Boolean isChanged = false;
        if(forecastFieldSet != null && forecastFieldSet.size() > 0) {
            for(String field :forecastFieldSet) {
                Double temp = Double.valueOf(newOpp.get(field));
                if(newOpp.get(field) != oldOpp.get(field) && 
                   (temp != 0 && temp != null)) {
                       isChanged = true;
                   }
            }
        }
        return isChanged;
    }
    
    public static Map<Id,String> getConcatenatedSpaces(List<Id> oppidLst) {
        Map<Id,Id> oppIdSpaceIdMap = new Map<Id,Id>();
        Map<Id, List<Id>> childspaceParentSpacesMap = new Map<Id, List<Id>>();
        Map<Id,List<Id>> oppIdSpacesLstMap = new Map<Id,List<Id>>();
        String concatenatedString = '';
        Map<Id,String> oppIdConcatenatedStrMap = new Map<Id,String>();
        
        
        for(Opportunity opp : [Select id, Space__c from Opportunity where id in: oppidLst]){
            oppIdSpaceIdMap.put(opp.id, opp.Space__c);
        }
        for(SpaceGroup__c spaceGrp : [Select id, ParentSpace__c, Childspace__c from spacegroup__c where childspace__c in : oppIdSpaceIdMap.values()]){
            if(childspaceParentSpacesMap.containskey(spaceGrp.ChildSpace__c)){
                childspaceParentSpacesMap.get(spaceGrp.ChildSpace__c).add(spaceGrp.ParentSpace__c);
            }else{
                childspaceParentSpacesMap.put(spaceGrp.ChildSpace__c, new List<Id> {spaceGrp.ParentSpace__c});
            }
        }
        
        for(Id oppid: oppIdSpaceIdMap.keyset()){
            if(childspaceParentSpacesMap.containskey(oppIdSpaceIdMap.get(oppid))){
                oppIdSpacesLstMap.put(oppid,childspaceParentSpacesMap.get(oppIdSpaceIdMap.get(oppid)));
            }else{
                oppIdSpacesLstMap.put(oppid, new List<Id> {oppIdSpaceIdMap.get(oppid)});
            }
        }
        
        for(Id oppid: oppIdSpacesLstMap.keyset()){
            for(Id parentSpaceID : oppIdSpacesLstMap.get(oppid)){
                concatenatedString = concatenatedString + '\'' + parentSpaceID + '\'|';
            }
            if(concatenatedString != null){
                concatenatedString = concatenatedString.removeEnd('|');
                oppIdConcatenatedStrMap.put(oppid,concatenatedString);
            }
            
            concatenatedString = null;
        }
        return oppIdConcatenatedStrMap;
        
    }
    
    // START : RPP-6061 Yana Navarro 9.12.2018
    public static Map<String, Set<String>> getClauseSubTypeToCreateDelete(Opportunity newOpp, Opportunity oldOpp, Space__c oppSpace, Set<String> existingOppClauseSubTypeSet, List<OpportunityRCA__mdt> opportunityRCAList, PrecedentClause__c nationalAgreement){
        Decimal day;
        Decimal year;
        Decimal month;
        Decimal securityPoints = 0;
        Boolean isNationalAgreementMatched = true;
        Map<String, Set<String>> subTypeMap 
            = new Map<String, Set<String>>{
            Constants.CREATE => new Set<String>(),
            Constants.REMOVE => new Set<String>()
        };

        //system.debug('existingOppClauseSubTypeSet : ' + existingOppClauseSubTypeSet);
        //system.debug('opportunityRCAList' + opportunityRCAList);

        for(OpportunityRCA__mdt oppRCA : opportunityRCAList){
            if(Constants.ANNUAL_RENT_75M.equalsIgnoreCase(oppRCA.Condition__c)){
                if(newOpp.AnnualMinimumRent__c > Decimal.valueOf(oppRCA.ConditionValue__c) && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                } else if(newOpp.AnnualMinimumRent__c <= Decimal.valueOf(oppRCA.ConditionValue__c) && existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.RECOVERABLE_AREA_2500SQM.equalsIgnoreCase(oppRCA.Condition__c)){
                if(newOpp.TECH_RecoverableArea__c > Decimal.valueOf(oppRCA.ConditionValue__c) && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                } else if(newOpp.TECH_RecoverableArea__c <= Decimal.valueOf(oppRCA.ConditionValue__c) && existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.CAPITAL_5M.equalsIgnoreCase(oppRCA.Condition__c)){
                if(newOpp.TotalForecastCapital__c > Decimal.valueOf(oppRCA.ConditionValue__c) && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                } else if(newOpp.TotalForecastCapital__c <= Decimal.valueOf(oppRCA.ConditionValue__c) && existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.RECOVERABLE_AREA_NOT_EQUAL_RENTABLE_AREA.equalsIgnoreCase(oppRCA.Condition__c)){
                //RPP-10150 - 'newOpp.DealType__c != Constants.GROSS' condition added 
                if(oppSpace != null && newOpp.DealType__c != Constants.GROSS && newOpp.TECH_RecoverableArea__c != oppSpace.RentableArea__c && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                } else if(oppSpace != null && newOpp.TECH_RecoverableArea__c == oppSpace.RentableArea__c && existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.CHANGE_IN_FITOUT_DAYS.equalsIgnoreCase(oppRCA.Condition__c)){
                if(oldOpp != null && newOpp.FitoutDays__c != oldOpp.FitoutDays__c && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.SECURITY_POSITION_COUNT_4.equalsIgnoreCase(oppRCA.Condition__c)){
                Decimal naDepositDays;
                Decimal naDepositWeeks;
                Decimal naDepositMonths;
                Decimal oppDepositDays = newOpp.SecurityDepositDays__c != null ? newOpp.SecurityDepositDays__c : 0;
                Decimal oppDepositWeeks = newOpp.SecurityDepositWeeks__c != null ? newOpp.SecurityDepositWeeks__c : 0;
                Decimal oppDepositMonths = newOpp.SecurityDepositMonths__c != null ? newOpp.SecurityDepositMonths__c : 0;
                
                if(nationalAgreement != null){
                    naDepositDays = nationalAgreement.RequiredSecurityDepositDays__c != null ? nationalAgreement.RequiredSecurityDepositDays__c : 0;
                    naDepositWeeks = nationalAgreement.RequiredSecurityDepositWeeks__c != null ? nationalAgreement.RequiredSecurityDepositWeeks__c : 0;
                    naDepositMonths = nationalAgreement.RequiredSecurityDepositMonths__c != null ? nationalAgreement.RequiredSecurityDepositMonths__c : 0;
                }
                
                if(nationalAgreement == null 
                   || (nationalAgreement != null && String.isEmpty(nationalAgreement.Account__r.PartnershipSegmentation__c)) 
                   || (nationalAgreement != null && !String.isEmpty(nationalAgreement.Account__r.PartnershipSegmentation__c)
                        && (naDepositDays != oppDepositDays 
                        || naDepositWeeks != oppDepositWeeks 
                        || naDepositMonths != oppDepositMonths))){
                    isNationalAgreementMatched = false;
                }
                
                if(newOpp.NumberofGuarantors__c != null && newOpp.NumberofGuarantors__c != 0){
                    securityPoints = newOpp.NumberofGuarantors__c;
                }
                if(newOpp.SecurityDepositMonths__c != null && newOpp.SecurityDepositMonths__c != 0){
                    securityPoints = securityPoints + newOpp.SecurityDepositMonths__c;
                }
                if(newOpp.SecurityDepositDays__c != null && newOpp.SecurityDepositDays__c != 0){
                    securityPoints = securityPoints + (newOpp.SecurityDepositDays__c / 30);
                }
                if(newOpp.SecurityDepositWeeks__c != null && newOpp.SecurityDepositWeeks__c != 0){
                    securityPoints = securityPoints + (newOpp.SecurityDepositWeeks__c / 4);
                }
                
                system.debug('isNationalAgreementMatched : ' + isNationalAgreementMatched);
                
                
                if(!isNationalAgreementMatched && securityPoints < Integer.valueOf(oppRCA.ConditionValue__c) 
                    && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                } else if((isNationalAgreementMatched || securityPoints >= Integer.valueOf(oppRCA.ConditionValue__c))
                    && existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.ATLEAST_ONE_NUM_OF_OPTIONS.equalsIgnoreCase(oppRCA.Condition__c)){
                if(newOpp.NumberOfOptions__c > Integer.valueOf(oppRCA.ConditionValue__c) && !existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                } else if(newOpp.NumberOfOptions__c <= Integer.valueOf(oppRCA.ConditionValue__c) && existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                    subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                }
            } else if(Constants.FITOUT_CONTRIBUTION_LESS_THAN_A_YEAR.equalsIgnoreCase(oppRCA.Condition__c)){
                day = (newOpp.TermDays__c != null) ? newOpp.TermDays__c : 0;
                month = (newOpp.TermMonths__c != null) ? (newOpp.TermMonths__c * 30.417) : 0;
                year = (newOpp.TermYr__c != null) ? (newOpp.TermYr__c * 365) : 0;

                if(newOpp.FitoutContribution__c > 0 && ((year + month + day) < 365)){
                    if(!existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                        subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                    }
                } else {
                    if(existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                        subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                    }
                }
            } else if(Constants.TERM_MORE_THAN_10_YEARS.equalsIgnoreCase(oppRCA.Condition__c)){
                if(newOpp.TermYr__c > 10 || (newOpp.TermYr__c == 10 && (newOpp.TermMonths__c > 0 || newOpp.TermDays__c > 0))){
                    if(!existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                        subTypeMap.get(Constants.CREATE).add(oppRCA.ClauseSubType__c);
                    }
                } else {
                    if(existingOppClauseSubTypeSet.contains(oppRCA.ClauseSubType__c)){
                        subTypeMap.get(Constants.REMOVE).add(oppRCA.ClauseSubType__c);
                    }
                }
            }
        }

        system.debug('subTypeMap'+subTypeMap);
        return subTypeMap;
    }
    
    public static List<OpportunityClause__c> createOpportunityClause(Id recordTypeId, Opportunity opportunity, List<ClauseLibrary__c> clauseLibraryList){
        OpportunityClause__c oppClauseTemp;
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        
        if(clauseLibraryList != null){
            for(ClauseLibrary__c cLibrary : clauseLibraryList){
                oppClauseTemp = new OpportunityClause__c();
                oppClauseTemp.Opportunity__c = opportunity.Id;
                oppClauseTemp.Name = cLibrary.Name;
                oppClauseTemp.Type__c = cLibrary.Type__c;
                oppClauseTemp.SubType__c = cLibrary.SubType__c;
                oppClauseTemp.ClauseDetails__c = cLibrary.ClauseDetails__c;
                oppClauseTemp.ReasonRecommendation__c = cLibrary.ReasonRecommendation__c;
                oppClauseTemp.ReferencedClause__c = cLibrary.Id;
                oppClauseTemp.RiskApplies__c = cLibrary.RiskApplies__c;
                oppClauseTemp.RecordTypeId = recordTypeId;
                oppClauseTemp.IsAutomated__c = true;
                
                opportunityClauseList.add(oppClauseTemp);
            }
        }
        
        system.debug('opportunityClauseList '+ opportunityClauseList);
        return opportunityClauseList;
    }
    // END : RPP-6061 Yana Navarro 9.12.2018
    
    // RPP-10553 Lean Flores June 19 2019
    public static void virtualVacancyUpdates(Opportunity opp) {
        
        if (opp == null) {
            return;
        }
        
        if(!Constants.NO.equalsIgnoreCase(opp.CurrentLeaseVirtualVacancy__c) && !String.isBlank(opp.CurrentLeaseVirtualVacancy__c)) {
            
            if(opp.VirtualVacancyEndDate__c == null && opp.VirtualVacancyRent__c == null && opp.VirtualVacancyStartDate__c == null) {
                opp.VirtualVacancyEndDate__c = opp.ForecastRentCommencementDate__c != null ? opp.ForecastRentCommencementDate__c.addDays(-1) : null;
                opp.VirtualVacancyRent__c = opp.ForecastRent__c;
                opp.VirtualVacancyStartDate__c = opp.ForecastedRentTerminationDate__c != null ? opp.ForecastedRentTerminationDate__c.addDays(1) : null;  
            }
            
        } else {
            
            opp.VirtualVacancyEndDate__c = null;
            opp.VirtualVacancyRent__c = null;
            opp.VirtualVacancyStartDate__c = null;               
        }
        
    } 
}