public class OpportunityLineItemController {
    
    public class Response {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String spaceType;
        @AuraEnabled
        public String nzProperty;
        @AuraEnabled
        public decimal percentageRent;
        @AuraEnabled
        public decimal rentableArea;
        @AuraEnabled
        public List<Opportunity> oppos;
        @AuraEnabled
        public List<opportunityLineItemWrapper> lineItemList;
        @AuraEnabled
        public String lineItemList2;
        @AuraEnabled
        public String userUITheme;
        @AuraEnabled
        public decimal totalPromoLevy;
        @AuraEnabled
        public decimal securitydeposit;
        @AuraEnabled
        public decimal totalOutgoings;
        @AuraEnabled
        public boolean hasEditAccess;
        @AuraEnabled
        public User Userinfo;
        @AuraEnabled
        public Boolean isPromoLevy;
        @AuraEnabled
        public Boolean dealAchieved;        
        public Response(){
            this.message = CONSTANTS.EMPTY;
            this.returnValue = CONSTANTS.EMPTY;
            this.status = CONSTANTS.SUCCESS;
            this.percentageRent = 0;
            this.securitydeposit = 0;
            this.spaceType = CONSTANTS.EMPTY;
            this.oppos = new List<Opportunity>();
            this.lineItemList = new List<opportunityLineItemWrapper>();
            this.lineItemList2 = CONSTANTS.EMPTY;
            this.rentableArea = 0;
            this.userUITheme=CONSTANTS.EMPTY;
            this.Userinfo=null;
        }
    }
    /**********************/
    public class opportunityLineItemWrapper {
        public Boolean isActive {get; set;}
        public Decimal listPrice {get; set;}
        public String itemName {get; set;}
        public Decimal totalPrice {get; set;}    
        public Id pricebookEntryId {get; set;} 
        public Id recordId {get; set;}
    }
    
    public class budgetDataWrapper{
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String BudgetType {get;set;}
        @AuraEnabled
        public Date EffectiveDate{get;set;}
        @AuraEnabled
        public Double Budget{get;set;}
        @AuraEnabled
        public Double Variance{get;set;}
    }   
    @AuraEnabled
    public static Map<String, Object> updateOppos(List<Opportunity> draftValues) {
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> errors = new Map<String, Object>();
        System.debug('opp ' + draftValues);
        update draftValues;
        response.put('code', 'SUCCESS');
        response.put('errors', errors);
        response.put('message', 'Your changes are saved.');
        
        return response;
    }
    
    @AuraEnabled
    public static Response updateOppoLineItem(String draftValues, Id oppoId, Decimal recoverableArea) {
        Response res = new Response();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityLineItemController.class.getName());
        res.userUITheme=Userinfo.getUiThemeDisplayed();
        List<Id> oppoIds = new List<Id>();
        oppoIds.add(oppoId);
        List<OpportunityLineItem> oppoNewLineItems = AddOutgoings(oppoIds);
        List<opportunityLineItemWrapper> listToSave;
        Map<Id,OpportunityLineItem> pricebookentryIdandItemMap=new Map<Id,OpportunityLineItem>();
        for (OpportunityLineItem oppoLineItem : oppoNewLineItems) {
            pricebookentryIdandItemMap.put(oppoLineItem.PricebookEntryId,oppoLineItem);
        }
        try {
            listToSave = (List<opportunityLineItemWrapper>)JSON.deserialize(draftValues, List<opportunityLineItemWrapper>.class);
        } catch (Exception e) {
            listToSave = NULL;
        }
        
        System.debug(recoverableArea+ 'listToSave ' + listToSave);
        List<OpportunityLineItem> deletedLineItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> newAndUpdateLineItems = new List<OpportunityLineItem>();
        for (opportunityLineItemWrapper item : listToSave) {
            OpportunityLineItem eItem=new OpportunityLineItem();
            // create/update to existing record
            if(item.isActive){
                if(item.recordId!=null){
                    eItem.Id=item.recordId;
                }else{
                    eItem.OpportunityId=pricebookentryIdandItemMap.get(item.pricebookEntryId).OpportunityId;
                    eItem.Product2Id=pricebookentryIdandItemMap.get(item.pricebookEntryId).Product2Id;
                    eItem.pricebookEntryId=item.pricebookEntryId;
                }    
                eItem.UnitPrice = item.listPrice;
                if(pricebookentryIdandItemMap.get(item.pricebookEntryId).CalculationMethod__c==Constants.SP_PSM||String.IsBlank(pricebookentryIdandItemMap.get(item.pricebookEntryId).CalculationMethod__c)){
                    eItem.Quantity = recoverableArea;
                    eItem.ApplicableArea__c=recoverableArea;
                }
                eItem.EffectiveFromDate__c=pricebookentryIdandItemMap.get(item.pricebookEntryId).EffectiveFromDate__c;
                newAndUpdateLineItems.add(eItem);
            }
            // if row is inactive then delete the record
            if(item.recordId != null && !item.isActive){
                eItem.Id = item.recordId;
                deletedLineItems.add(eItem);
            }
        }
        oppoItemList(oppoId);
        Opportunity opptyrecord=new Opportunity();
        opptyrecord.id=oppoId;
        opptyrecord.TECH_RecoverableArea__c=recoverableArea;
        Boolean lineitemsupdated=false;       
        try{
            delete deletedLineItems;
            Database.upsert(newAndUpdateLineItems);
            lineitemsupdated=true;
        }catch(Exception e){
            res.status = Constants.FAILED;
            res.message = e.getMessage();
            errorHandler.createError(e);
            system.debug('EXCEPTION: '+ res.message);
        }
        
        if(lineitemsupdated){
            try{
                TriggerHandler.clearBypass(OpportunityTriggerHandler.class.getName());
                //updateOpp updateJob = new updateOpp(opptyrecord);
                //ID jobID = System.enqueueJob(updateJob);
                update opptyrecord;  
            }catch(Exception e){
                res.status = Constants.FAILED;
                res.message = e.getMessage();
                errorHandler.createError(e);
            }  
        }
        errorHandler.save();
        return res;
    }
    /**********************
*
* Get lease finance oppos
*/
    @AuraEnabled
    public static Response getJeffOppoList() {
        Response res = new Response();
        res.userUITheme=Userinfo.getUiThemeDisplayed();
        List<RecordType> oppRecordType = [Select Id from RecordType Where Name =: Constants.OPP_RETAIL_LEASING];
        if (oppRecordType.size() > 0) {
            List<Opportunity> oppos = [Select Id, Space__r.Name, Space__c, StageName, CurrentPreviousTenant__c, Name, OccupancyStatus__c, ForecastedRentTerminationDate__c, AnnualMinimumRent__c From Opportunity Where recordTypeId =: oppRecordType.get(0).Id And BestBet__c = TRUE];   
            if (oppos.size() > 0) {
                res.oppos = oppos;
            }
        } else {
            res.status = CONSTANTS.FAILED;
            res.message = CONSTANTS.OPP_LINEITEM_RES_MESSAGE;
        }
        return res;
    }
    
    /*
* Add different product based on type
*/
    @AuraEnabled    
    public static Response createOPPLineItemWithRent(Id opportunityId, Decimal rent, Decimal grossRent, Decimal pecentageOfRent, String leaseType, Boolean isPromoIncluded, Boolean tresholdApplies, Boolean isNZProperty, String nzProperty) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityLineItemController.class.getName());
        Response res = new Response();
        Map<Id, Id> topParentAccountMap  = new Map<Id,Id>();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        
        Set<Id> propertyIdSet = new Set<Id>();
        Set<Id> opportunityAccountIdSet = new Set<Id>();
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
        Set<Id> priceBookIdSet = new Set<Id>();
        Map<String, PriceBookEntry> productNameandPricebookEntryMap = new Map<String, PriceBookEntry>();
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();     
        List<String> productToDeletefamiltLst = new List<String>{CONSTANTS.RENT,Constants.PROMO_MARKETING};
        String oldPromoLevy;
        List<OpportunityLineItem> opportunityProductsList = new List<OpportunityLineItem>();
        Opportunity oppo = [SELECT Id,TotalPromotionLevy__c,TechByPassOnClone__c,RecordTypeId,Property__c,AccountId,AnnualMinimumRent__c,ProposedStartDate__c,
                            TermYr__c, TermMonths__c, TermDays__c, SecurityDeposit__c,PromoLevyIncluded__c,Reason_for_No_Promo_Levy__c, pricebook2Id,Property__r.PriceBook__c,
                            Space__c,Space__r.BillingCategory__c,Space__r.Type__c,DealType__c,CurrencyIsoCode 
                            FROM opportunity 
                            WHERE Id = :opportunityId limit 1];
        oldPromoLevy = oppo.PromoLevyIncluded__c;
        Decimal oldRent;
        String spacebillingcategory='NA';
        String isPromoInc = 'No';
        
        PriceBookEntry promoRevPbe = new PriceBookEntry(); // LF RPP-10151 9.5.2019
        
        if (!isPromoIncluded){
            oppo.PromoLevyIncluded__c='No'; // RPP - 10674
            productToDeletefamiltLst.add(Constants.PRODUCT_PROMO_REVIEW);
        }else{
            oppo.PromoLevyIncluded__c='Yes';
            isPromoInc = 'Yes'; 
        }
        if(String.isNotBlank(oppo.Space__r.BillingCategory__c)){
            spacebillingcategory=oppo.Space__r.BillingCategory__c;
        }
        List<PricebookEntry> promotionpriceBookEntry = [SELECT Id, Product2Id from PricebookEntry where Pricebook2Id =:oppo.Property__r.PriceBook__c AND Product2.Family =:Constants.PROMO_MARKETING AND isActive = true AND Product2.SpaceBillingCategory__c INCLUDES (:spacebillingcategory) AND Product2.DealType__c INCLUDES (:oppo.DealType__c) AND CurrencyIsoCode=:oppo.CurrencyIsoCode AND Product2.SpaceType__c INCLUDES (:oppo.Space__r.Type__c) Limit 1];
        PricebookEntry baserentpriceBookentry = [SELECT id,Product2Id from PricebookEntry where  Pricebook2Id =:oppo.Property__r.PriceBook__c AND Product2.Family =:Constants.RENT AND isActive = true AND Product2.SpaceBillingCategory__c INCLUDES (:spacebillingcategory) AND Product2.DealType__c INCLUDES (:oppo.DealType__c) AND CurrencyIsoCode=:oppo.CurrencyIsoCode AND Product2.SpaceType__c INCLUDES (:oppo.Space__r.Type__c) Limit 1];
        
        Map<String, Decimal> rentInfoMap = getRentInfo(opportunityId, rent, grossRent, pecentageOfRent, isPromoIncluded, leaseType,  isNZProperty, nzProperty, tresholdApplies);
        if(promotionpriceBookEntry != null
           && promotionpriceBookEntry.size()>0 
           && rentInfoMap.containskey('PromotionFund') 
           && isPromoIncluded){
            
           OpportunityLineItem lineItemPromotion = new OpportunityLineItem();
            lineItemPromotion.Product2Id = promotionpriceBookEntry[0].Product2Id;
            lineItemPromotion.UnitPrice = rentInfoMap.get('PromotionFund');
            lineItemPromotion.Quantity = 1;
            lineItemPromotion.OpportunityId = opportunityId;
            lineItemPromotion.PricebookEntryId = promotionpriceBookEntry[0].id;
            opportunityProductsList.add(lineItemPromotion);
            
            //Add Promo Review
            if((oppo.TechByPassOnClone__c && oldPromoLevy != isPromoInc) || !oppo.TechByPassOnClone__c){
                
                priceBookIdSet.add(oppo.Pricebook2Id);
                pbEntryList = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet);
				List<OpportunityLineItem> existingOLI = [SELECT Id, OpportunityId, Product2Id, ProductFamily__c, CPIType__c
                                                            FROM OpportunityLineItem 
                                                            WHERE OpportunityId =: opportunityId
                                                            AND Product2.Family =: Constants.PRODUCT_PROMO_REVIEW
                                                            AND Flexi_Rent__c = false
                                                            ORDER BY EffectiveFromDate__c];                
                // START LF RPP-10151 9.5.2019
                Map<Id, PriceBookEntry> promoRevByPriceBookMap = new Map<Id, PriceBookEntry>();
                promoRevByPriceBookMap = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet, Constants.PRODUCT_PROMO_REVIEW);
                promoRevPbe = promoRevByPriceBookMap.get(oppo.Pricebook2Id);
                // END LF RPP-10151 9.5.2019
                
                opportunityAccountIdSet.add(oppo.AccountId);
                if(oppo.Property__c != null){
                    propertyIdSet.add(oppo.Property__c);
                }
                Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet));
                topParentAccountMap = OpportunityBL.buildTopParentAccountMap(opportunityAccountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
                nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
                
                Map<Id, Double> opptyWithRent = new Map<Id, Double>();
                
                oppLineItemWrapper.PromoMarketingPrice = rentInfoMap.get('PromotionFund');
                oppLineItemWrapper.opportunityRecord = oppo;
                oppLineItemWrapper.opportunityRecordtypeName = RecordTypeUtil.getAllRecordTypesById(Constants.OPPORTUNITY).get(oppo.RecordTypeId).getName();
                oppLineItemWrapper.propertyMap = propertyMap;
                oppLineItemWrapper.nationalAgreementClauseMap = nationalAgreementClauseMap;
                oppLineItemWrapper.topParentAccountMap = topParentAccountMap;
                oppLineItemWrapper.productNameandPricebookEntryMap = productNameandPricebookEntryMap;
                opportunityProductsList.addAll(OpportunityBL.createUpdateReviewsforOpportunity(null, oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, promoRevPbe,existingOLI)); // LF RPP-10151 9.5.2019 //RPP-10674 - Changed the method
                
            }
            
        }
        
        //Add base rent
        OpportunityLineItem lineItem = new OpportunityLineItem();
        lineItem.Product2Id = baserentpriceBookentry.Product2Id;
        lineItem.UnitPrice = rent;
        lineItem.Quantity = 1;
        lineItem.OpportunityId = opportunityId;
        lineItem.PricebookEntryId = baserentpriceBookentry.id;
        opportunityProductsList.add(lineItem);
        
        //pkumarlg logic to update Amortized Rent, used on discloser statement.
        List<OpportunityLineItem> existinglineItemsList=[Select Flexi_Rent__c,id,AmortizedRent__c,CalculationMethod__c,Percentage__c,Opportunity.AnnualMinimumRent__c from OpportunityLineItem where OpportunityId=: opportunityId AND ((Product2.Family=:Constants.PRODUCT_RENT_REVIEW AND Flexi_Rent__c=false) OR (Product2.Family=:Constants.RECOVERIES AND CalculationMethod__c=:Constants.SP_PERCENTAGE)) order by EffectiveFromDate__c ASC];
        Decimal amortizedRent=0;
        if(rent!=null&&rent!=0){   
            amortizedRent=rent;
            for(OpportunityLineItem lineitemRecord: existinglineItemsList){
                if(lineitemRecord.Flexi_Rent__c==false){
                    lineitemRecord.AmortizedRent__c=amortizedRent+((amortizedRent)*(Decimal.valueOf(Label.VICAmortizationPercent)));
                    amortizedRent=amortizedRent+((amortizedRent)*(Decimal.valueOf(Label.VICAmortizationPercent)));
                }
                if(lineitemRecord.CalculationMethod__c==Constants.SP_PERCENTAGE&&rent!=null){    
                    lineitemRecord.UnitPrice=(lineitemRecord.Percentage__c*rent)/100;
                }
                opportunityProductsList.add(lineitemRecord);
            }
        }
        
        
        List<OpportunityLineItem> OppLineItmsToDelete = [Select Id from OpportunityLineItem WHERE Opportunityid =: opportunityId AND (Product2.Family in: productToDeletefamiltLst)];
        
        //Database.insert(opportunityProductsList,false);
        Integer counter = 0;
        Boolean doDelete = true;
        OpportunityLineItem oppLineItemTemp;
        List<Database.UpsertResult> upsertResultList = Database.upsert(opportunityProductsList, false);
        
        for(Database.UpsertResult uResult : upsertResultList){
            if(!uResult.isSuccess()){
                res.status = Constants.FAILED;
                oppLineItemTemp = opportunityProductsList[counter];
                
                if(promotionpriceBookEntry != null && promotionpriceBookEntry.size() > 0 
                   && oppLineItemTemp.Product2Id == promotionpriceBookEntry[0].Product2Id){
                       doDelete = false;
                       oppo.PromoLevyIncluded__c = oldPromoLevy;
                   }
                
                errorHandler.createError(uResult, null);
            }
            
            counter++;
        }
        
        try{
            Database.update(oppo);
        } catch(Exception e){
            errorHandler.createError(e);
        }
        
        if(doDelete && OppLineItmsToDelete != null && OppLineItmsToDelete.size() > 0){
            system.debug('OppLineItmsToDelete : ' + OppLineItmsToDelete);
            try{
                Database.delete(OppLineItmsToDelete);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        res.securityDeposit = getOppSecDeposit(opportunityId).securityDeposit;
        res.isPromoLevy = (Constants.YES.equalsIgnoreCase(oppo.PromoLevyIncluded__c) ? true : false);
        
        //oppo.SecurityDeposit__c = res.securitydeposit;
        errorHandler.save();
        return res;
    }
    @AuraEnabled    
    public static Response getNewLineItemTotals (Id opportunityId, Decimal rent, Decimal grossRent, Decimal pecentageOfRent, String leaseType) {
        
        Savepoint sp = Database.setSavepoint();
        createOPPLineItemWithRent(opportunityId, rent, grossRent, pecentageOfRent, leaseType, true, true, false, null);
        List<Opportunity> oppLst = [Select id,TotalPromotionLevy__c,TotalOutgoings__c from Opportunity where id =: opportunityId limit 1];
        Response res = new Response();
        res.totalPromoLevy = oppLst[0].TotalPromotionLevy__c;
        res.totalOutgoings = oppLst[0].TotalOutgoings__c;
        Database.rollback(sp);  
        return res;
    }   
    /*
* @Author: Chen Chen
* @Parameter:
* @Description:
*/
    public static List<OpportunityLineItem> AddOutgoings (List<Id> opportunityIds) {
        Date oppDateTemp;
        SpaceProduct__c spaceProductTemp;
        OpportunityLineItem oppoLineItemTemp = new OpportunityLineItem();
        Set<Id> pbIds = new Set<Id>();
        List<OpportunityLineItem> oppLineItemsNew = new List<OpportunityLineItem>();
        
        List<Opportunity> oppotunityList = [SELECT Id,Opportunity.Property__c, Space__r.Property__r.PriceBook__c,
                                            Property__r.ApplicableOutgoings__c, Space__c, Space__r.ApplicableOutgoings__c, 
                                            Space__r.Property__c, DealType__c,Space__r.RentableArea__c, TECH_RecoverableArea__c, //RPP-10905
                                            Space__r.SpaceProductsApplies__c, ProposedRentCommencementDate__c, 
                                            Space__r.BillingCategory__c, Space__r.Type__c,CurrencyIsoCode,AnnualMinimumRent__c,
                                            LeaseVariationEffectiveDate__c, TechByPassOnClone__c
                                            FROM Opportunity 
                                            WHERE Id =: opportunityIds];
        List<Id> spaceIds = new List<Id>();
        List<Id> propertyIds = new List<Id>();
        Map<String, OpportunityLineItem> pbEntryNameOppLineItemMap = new Map<String, OpportunityLineItem>();
        
        for (Opportunity oppo : oppotunityList) {
            spaceIds.add(oppo.Space__c);
            propertyIds.add(oppo.Space__r.Property__c);
            pbIds.add(oppo.Space__r.Property__r.PriceBook__c);
        }
        
        // get space products if available for selected space
        Map<String, SpaceProduct__c> productidSpaceproductMap = new Map<String,SpaceProduct__c>();
        List<SpaceProduct__c> spaceProducts = [SELECT Id, Space__c, Product__c, Product__r.DealType__c, 
                                               Product__r.OutgoingsCategory__c, CalculationMethod__c, Percentage__c, 
                                               SalesPrice__c,Product__r.SpaceType__c,Product__r.SpaceBillingCategory__c,
                                               EffectiveFromDate__c, EffectiveToDate__c
                                               FROM SpaceProduct__c 
                                               WHERE Space__c =: spaceIds 
                                               AND Active__c=true 
                                               AND Product__r.DealType__c != null 
                                               AND Product__r.SpaceType__c != null
                                               AND Product__r.SpaceBillingCategory__c != null
                                               ORDER BY LastModifiedDate ASC];
        if (spaceProducts.size() > 0) {
            for(SpaceProduct__c spaceProduct : spaceProducts) {
                if(spaceProduct.Product__c != null){
                    productidSpaceproductMap.put((spaceProduct.Space__c + '' + spaceProduct.Product__c), spaceProduct);
                    System.debug('Product ID SpaceProduct Map === ' + productidSpaceproductMap);
                }
            }
        }
        
        List<PricebookEntry> pricebookentryList = [SELECT Id, Name, UnitPrice, product2Id,product2.Name,Product2.DealType__c, 
                                                   Pricebook2Id,Product2.OutgoingsCategory__c, Product2.SpaceBillingCategory__c,
                                                   Product2.SpaceType__c,CurrencyIsoCode, EffectiveFromDate__c, EffectiveToDate__c, PBE_CalculationMethod__c
                                                   FROM PricebookEntry 
                                                   WHERE Pricebook2Id in :pbIds AND Product2.OutgoingsCategory__c!=null 
                                                   AND IsActive = true 
                                                   AND Product2.isactive = true 
                                                   AND DisclosureStatementOnly__c = false
                                                   AND Product2.ProductCode =: Constants.OTG
                                                   AND Product2.DealType__c != null
                                                   AND Product2.SpaceBillingCategory__c != null
                                                   AND Product2.SpaceType__c != null
                                                   //AND (EffectiveToDate__c==null OR EffectiveToDate__c>System.today())
                                                   ORDER BY EffectiveFromDate__c ASC, Name];
        
        Map<Id,List<PricebookEntry>> pricebookPriceBookEntryMap = new Map<Id,List<PricebookEntry>>();
        for(PricebookEntry pricebookEntryRecord : pricebookentryList){
            if (pricebookPriceBookEntryMap.containsKey(pricebookEntryRecord.Pricebook2Id)) {
                pricebookPriceBookEntryMap.get(pricebookEntryRecord.Pricebook2Id).add(pricebookEntryRecord);                    
            } else {
                pricebookPriceBookEntryMap.put(pricebookEntryRecord.Pricebook2Id,new List<PricebookEntry>{pricebookEntryRecord});
            }
        }
        
        system.debug('pricebookPriceBookEntryMap : ' + pricebookPriceBookEntryMap);
        
        for(Opportunity opptyRecord: oppotunityList){
            if(!opptyRecord.TechByPassOnClone__c){
                oppDateTemp = opptyRecord.ProposedRentCommencementDate__c;
            } else {
                oppDateTemp = opptyRecord.LeaseVariationEffectiveDate__c;
            }
            
            if(String.isBlank(opptyRecord.Space__r.BillingCategory__c)){
                opptyRecord.Space__r.BillingCategory__c='NA';
            }
            
            System.debug(' INSIDE* '+opptyRecord.DealType__c);
            
            pbEntryNameOppLineItemMap = new Map<String, OpportunityLineItem>();
            if(String.isNotBlank(opptyRecord.DealType__c) 
               && pricebookPriceBookEntryMap.containsKey(opptyRecord.Space__r.Property__r.PriceBook__c) 
               && String.IsNotBlank(opptyRecord.Space__r.ApplicableOutgoings__c)){
                   
                   System.debug('Product ID === ' + productidSpaceproductMap);
                   
                   for(PricebookEntry pricebookEntryRecord : pricebookPriceBookEntryMap.get(opptyRecord.Space__r.Property__r.PriceBook__c)){
                       if(String.isNotBlank(pricebookEntryRecord.product2.DealType__c)){
                           // check if the product is avaliable for selected deal type
                           List<String> productdealTypevalueList = pricebookEntryRecord.product2.DealType__c.split(';');
                           List<String> productBillingcategoryList = pricebookEntryRecord.product2.SpaceBillingCategory__c.split(';');
                           List<String> productSpacetypeList = pricebookEntryRecord.product2.SpaceType__c.split(';');
                           List<String> spaceoutgoingList = opptyRecord.Space__r.ApplicableOutgoings__c.split(';');
                           List<String> projectoutgoingList = new List<String>();
                           
                           if(opptyRecord.Property__r.ApplicableOutgoings__c!=null){
                               projectoutgoingList = opptyRecord.Property__r.ApplicableOutgoings__c.split(';');
                           }
                           
                           System.debug(productdealTypevalueList+ ' INSIDE* '+opptyRecord.DealType__c);
                           System.debug(productBillingcategoryList+ ' * '+  + ' * '+ opptyRecord.Space__r.BillingCategory__c);
                           System.debug(productSpacetypeList+ ' * '+  + ' * '+ opptyRecord.Space__r.Type__c);
                           
                           // pick line items which are part of selected space.
                           if(projectoutgoingList.contains(pricebookEntryRecord.Product2.OutgoingsCategory__c)
                              && spaceoutgoingList.contains(pricebookEntryRecord.Product2.OutgoingsCategory__c)
                              && productdealTypevalueList.contains(opptyRecord.DealType__c)
                              && productBillingcategoryList.contains(opptyRecord.Space__r.BillingCategory__c)
                              && productSpacetypeList.contains(opptyRecord.Space__r.Type__c)
                              && pricebookEntryRecord.CurrencyIsoCode == opptyRecord.CurrencyIsoCode){  
                                  
                                  system.debug('pricebookEntryRecord.Name : ' + pricebookEntryRecord.Name);
                                  system.debug('pricebookEntryRecord.EffectiveToDate__c : ' + pricebookEntryRecord.EffectiveToDate__c);
                                  system.debug('pricebookEntryRecord.EffectiveFromDate__c : ' + pricebookEntryRecord.EffectiveFromDate__c);
                                  
                                  if(opptyRecord.Space__r.SpaceProductsApplies__c
                                     && productidSpaceproductMap.containsKey(opptyRecord.Space__c + '' + pricebookEntryRecord.product2Id)){
                                         
                                         spaceProductTemp
                                             = productidSpaceproductMap.get(opptyRecord.Space__c + '' + pricebookEntryRecord.Product2Id);
                                         
                                         if(spaceProductTemp.EffectiveToDate__c != null && spaceProductTemp.EffectiveFromDate__c != null
                                            && oppDateTemp >= spaceProductTemp.EffectiveFromDate__c 
                                            && oppDateTemp <= spaceProductTemp.EffectiveToDate__c){
                                                
                                                oppoLineItemTemp = createOTGOppLineItem(opptyRecord, pricebookEntryRecord, spaceProductTemp);
                                                
                                                pbEntryNameOppLineItemMap.put(pricebookEntryRecord.Name, oppoLineItemTemp);
                                            } else if(spaceProductTemp.EffectiveToDate__c == null 
                                                      && (!pbEntryNameOppLineItemMap.containsKey(pricebookEntryRecord.Name)
                                                          || (pbEntryNameOppLineItemMap.get(pricebookEntryRecord.Name).EffectiveToDate__c == null
                                                              && oppDateTemp >= pricebookEntryRecord.EffectiveFromDate__c ))){
                                                                  oppoLineItemTemp = createOTGOppLineItem(opptyRecord, pricebookEntryRecord, spaceProductTemp);
                                                                  
                                                                  pbEntryNameOppLineItemMap.put(pricebookEntryRecord.Name, oppoLineItemTemp);
                                                              }
                                     } else {
                                         if(pricebookEntryRecord.EffectiveToDate__c != null 
                                            && pricebookEntryRecord.EffectiveFromDate__c != null
                                            && oppDateTemp >= pricebookEntryRecord.EffectiveFromDate__c 
                                            && oppDateTemp <= pricebookEntryRecord.EffectiveToDate__c){
                                                
                                                oppoLineItemTemp = createOTGOppLineItem(opptyRecord, pricebookEntryRecord, null);
                                                
                                                pbEntryNameOppLineItemMap.put(pricebookEntryRecord.Name, oppoLineItemTemp);
                                            } else if(pricebookEntryRecord.EffectiveToDate__c == null 
                                                      && (!pbEntryNameOppLineItemMap.containsKey(pricebookEntryRecord.Name)
                                                          || (pbEntryNameOppLineItemMap.get(pricebookEntryRecord.Name).EffectiveToDate__c == null
                                                              && oppDateTemp >= pricebookEntryRecord.EffectiveFromDate__c ))){
                                                                  oppoLineItemTemp = createOTGOppLineItem(opptyRecord, pricebookEntryRecord, null);
                                                                  
                                                                  pbEntryNameOppLineItemMap.put(pricebookEntryRecord.Name, oppoLineItemTemp);
                                                              }
                                     }
                              }
                       }
                   }
                   
                   oppLineItemsNew.addAll(pbEntryNameOppLineItemMap.values());
               }
        }
        system.debug('oppLineItemsNew--------'+JSON.serialize(oppLineItemsNew));
        return oppLineItemsNew;
    }
    
    public static OpportunityLineITem createOTGOppLineItem(Opportunity opportunity, PriceBookEntry pbEntry,
                                                           SpaceProduct__c spaceProductTemp){
                                                               OpportunityLineItem oppoLineItem = new OpportunityLineItem();
                                                               
                                                               oppoLineItem.IsActive__c = true;
                                                               oppoLineItem.PriceBookEntryId = pbEntry.Id;
                                                               oppoLineItem.OpportunityId = opportunity.id;
                                                               
                                                               if(opportunity.ProposedRentCommencementDate__c != null){
                                                                   //oppoLineItem.EffectiveFromDate__c = opportunity.ProposedRentCommencementDate__c;  
                                                               }
                                                               
                                                               oppoLineItem.Product2Id = pbEntry.Product2Id;  
                                                               
                                                               //If the space have space products, price should be picked from SpaceProduct__c record
                                                               System.debug('Opp SpaceProduct ===== ' + opportunity.Space__r.SpaceProductsApplies__c);
                                                               System.debug('Keyy === ' + opportunity.Space__c+''+pbEntry.product2Id);
                                                               Decimal recoverableArea = opportunity.TECH_RecoverableArea__c > 0
                                                                                            ? opportunity.TECH_RecoverableArea__c
                                                                   						    : opportunity.Space__r.RentableArea__c; //RPP-10905
                                                               if(opportunity.Space__r.SpaceProductsApplies__c && spaceProductTemp != null){
                                                                   oppoLineItem.UnitPrice = spaceProductTemp.SalesPrice__c;
                                                                   oppoLineItem.CalculationMethod__c = spaceProductTemp.CalculationMethod__c;
                                                                   
                                                                   if(spaceProductTemp.CalculationMethod__c == Constants.SP_FIXED){
                                                                       oppoLineItem.Quantity = 1;
                                                                       oppoLineItem.ApplicableArea__c = 1;
                                                                   } else if(spaceProductTemp.CalculationMethod__c == Constants.SP_PSM){
                                                                       oppoLineItem.Quantity = recoverableArea; //RPP-10905
                                                                       oppoLineItem.ApplicableArea__c = recoverableArea; //RPP-10905
                                                                   } else if(spaceProductTemp.CalculationMethod__c == Constants.SP_PERCENTAGE){
                                                                       if(opportunity.AnnualMinimumRent__c != null){
                                                                           oppoLineItem.UnitPrice 
                                                                               = (opportunity.AnnualMinimumRent__c * spaceProductTemp.Percentage__c)/100;
                                                                       } else {
                                                                           oppoLineItem.UnitPrice = 0;
                                                                       }
                                                                       
                                                                       oppoLineItem.Quantity = 1;
                                                                       oppoLineItem.ApplicableArea__c = 1;
                                                                       oppoLineItem.Percentage__c = spaceProductTemp.Percentage__c;
                                                                   }
                                                               } else {
                                                                   	String pbcCalculationMethod = pbEntry.PBE_CalculationMethod__c;
                                                                   	system.debug('pbcCalculationMethod----'+pbcCalculationMethod);
                                                                   	system.debug('pbEntry.UnitPrice------'+pbEntry.UnitPrice);
                                                                	if(pbcCalculationMethod == Constants.SP_PSM){
                                                                   		if(recoverableArea > 0){ //RPP-10905
                                                                       		oppoLineItem.Quantity = recoverableArea; //RPP-10905
                                                                       	}else{
                                                                           	oppoLineItem.Quantity = 0.00;
                                                                       	}
                                                                       	oppoLineItem.ApplicableArea__c = recoverableArea; //RPP-10905
                                                                       	//RPP-10813 - start
                                                                       	oppoLineItem.UnitPrice = pbEntry.UnitPrice;
                                                                       	//oppoLineItem.totalPrice = oppoLineItem.ApplicableArea__c * pbEntry.UnitPrice;
                                                                       	//RPP-10813 - end
                                                                   	}else if(pbcCalculationMethod == Constants.SP_PERCENTAGE){
                                                                       	if(opportunity.AnnualMinimumRent__c != NULL && opportunity.AnnualMinimumRent__c > 0){
                                                                       		oppoLineItem.UnitPrice = opportunity.AnnualMinimumRent__c * (pbEntry.UnitPrice * 0.01);
                                                                       	}
                                                                       	else{
                                                                           	oppoLineItem.UnitPrice = 0.00;
                                                                       	}
                                                                       
                                                                       	oppoLineItem.Quantity = 1;
                                                                       	oppoLineItem.ApplicableArea__c = 1;
                                                                       	oppoLineItem.Percentage__c = pbEntry.UnitPrice;
                                                                   	}else if(pbcCalculationMethod == Constants.SP_FIXED){
                                                                       	oppoLineItem.Quantity = 1;
                                                                       	oppoLineItem.ApplicableArea__c = 1;
                                                                        //RPP-10813 - start
                                                                       	oppoLineItem.UnitPrice = pbEntry.UnitPrice;
                                                                        //RPP-10813 - end
                                                                   	   	//oppoLineItem.Quantity = opportunity.Space__r.RentableArea__c;
                                                                   	}
                                                               	}
                                                               
                                                               	return oppoLineItem;
                                                           }
    
    /*
* @Author: Chen Chen
* @Parameter: 
* @Description:
*/
    public static List<OpportunityLineItem> outgoingUpdate(List<Id> oppoIds) {
        List<OpportunityLineItem> OppLineItmsToDelete = [Select Id from OpportunityLineItem WHERE Opportunityid IN:oppoIds];
        database.delete(OppLineItmsToDelete);
        List<OpportunityLineItem> oppoNewLineItems = AddOutgoings(oppoIds);
        return oppoNewLineItems;
    }
     
    /*
* @Author: Chen Chen
* @Parameter: 
* @Description:
*/
    @AuraEnabled
    public static Response oppoItemList(Id oppoId) {
        Set<String> existingProductSet = new Set<String>();
        List<Opportunity> oppoArea = [SELECT Id, Space__r.RentableArea__c,TECH_RecoverableArea__c,Stagename,DealAchieved__c,JDESentStatus__c 
                                      FROM Opportunity 
                                      WHERE Id =: oppoId];
        Response res = new Response();
        res.oppos.addAll(oppoArea);
        res.userUITheme=Userinfo.getUiThemeDisplayed();
        res.Userinfo = [SELECT id, Profile.Name, ProfileId, Name FROM User WHERE Id =: Userinfo.getUserId()];
        List<opportunityLineItemWrapper> oltList = new List<opportunityLineItemWrapper>();
        List<Id> oppoIds = new List<Id>();
        oppoIds.add(oppoId);
        List<OpportunityLineItem> allItems = AddOutgoings(oppoIds);
        Set<Id> productIds = new Set<Id>();
        Map<Id,OpportunityLineItem> productIdItemMap=new Map<Id,OpportunityLineItem>();
        for (OpportunityLineItem oppoLineItem : allItems) {
            productIds.add(oppoLineItem.Product2Id);
            productIdItemMap.put(oppoLineItem.product2Id,oppoLineItem);
        }
        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Id IN: productIds];
        Map<Id, String> productIdToName = new Map<Id, String>();
        
        for (Product2 product : products) {
            productIdToName.put(product.Id, product.Name);
        }
        
        List<OpportunityLineItem> existingItems = [SELECT Id, ListPrice, TotalPrice, Product2.Id, Product2.Name,UnitPrice, Quantity,
                                                   Product2.Family,Product2.ProductCode,Opportunity.TECH_RecoverableArea__c, 
                                                   PricebookEntryId, PriceBookEntry.Name
                                                   FROM OpportunityLineItem 
                                                   WHERE OpportunityId =: oppoId 
                                                   AND Product2.ProductCode =: Constants.OTG Order by Product2.Name];
        
        OpportunityLineItemWrapper lineItemWrapper = new OpportunityLineItemWrapper();      
        Map<Id,OpportunityLineItem> productIdItemMapExisting=new Map<Id,OpportunityLineItem>();
        
        for(OpportunityLineItem opptylineitemRecord : existingItems){
            productIdItemMapExisting.put(opptylineitemRecord.product2Id,opptylineitemRecord);
            existingProductSet.add(opptylineitemRecord.Product2.Name);
            
            lineItemWrapper = new OpportunityLineItemWrapper();
            lineItemWrapper.isActive = true;
            lineItemWrapper.pricebookEntryId = opptylineitemRecord.PricebookEntryId;
            lineItemWrapper.recordId = opptylineitemRecord.Id;
            lineItemWrapper.listPrice = opptylineitemRecord.UnitPrice;
            lineItemWrapper.totalPrice = opptylineitemRecord.TotalPrice;
            lineItemWrapper.itemName = opptylineitemRecord.Product2.Name;
            //res.rentableArea=productIdItemMapExisting.get(allitemrecord.product2Id).Quantity; 
            res.rentableArea = opptylineitemRecord.Opportunity.TECH_RecoverableArea__c;
            
            oltList.add(lineItemWrapper);
        }
        
        for(OpportunityLineItem allitemrecord : allItems){
            if(!productIdItemMapExisting.containsKey(allitemrecord.product2Id) 
               && !existingProductSet.contains(productIdToName.get(allitemrecord.Product2Id))){
                   lineItemWrapper = new OpportunityLineItemWrapper();
                   lineItemWrapper.recordId = null;
                   lineItemWrapper.pricebookEntryId = allitemrecord.PricebookEntryId;
                   lineItemWrapper.isActive = false;
                   lineItemWrapper.listPrice = allitemrecord.UnitPrice;
                   lineItemWrapper.totalPrice = 0.00;
                   lineItemWrapper.itemName = productIdToName.get(allitemrecord.Product2Id);
                   oltList.add(lineItemWrapper);
               }
        }
        
        System.debug('ONLOAD ITEMS'+oltList);
        
        if (oltList.size() > 0) {
            res.lineItemList = oltList;
            try {
                res.lineItemList2 = JSON.serialize(oltList);
            } catch (Exception e) {
                res.lineItemList2 = NULL;
            }
            
            if(res.rentableArea==0||res.rentableArea==null){
                res.rentableArea = oppoArea.get(0).Space__r.RentableArea__c;
            }
        }
        return res;
    }
    
    @AuraEnabled
    public static Response getMoreValue(Id opportunityId) {
        Response res = new Response();
        Boolean updateError = false;
        res.userUITheme=Userinfo.getUiThemeDisplayed();
        Opportunity opp = [Select DealAchieved__c, PromoLevyIncluded__c, NZProperty__c,Id, tolabel(Space__r.Type__c),RecordType.Developername, Account.parentId From Opportunity Where id = :opportunityId];
        if (opp != null) {
            res.spaceType = opp.Space__r.Type__c;
            res.nzProperty = opp.NZProperty__c;
            res.isPromoLevy = (Constants.YES.equalsIgnoreCase(opp.PromoLevyIncluded__c) ? true : false);
            res.dealAchieved = opp.DealAchieved__c;
            List<PrecedentClause__c> precedentClause = [Select Id, PercentageRentPercent__c, Type__c, Status__c From PrecedentClause__c Where Status__c =: Constants.ACTIVE and Type__c = 'Percentage Rent' and Account__c =:opp.Account.parentId Limit 1];
            if (precedentClause.size() > 0) {
                res.percentageRent = precedentClause.get(0).PercentageRentPercent__c;
            } else {
                res.percentageRent = 0;
            }
        } else {
            res.status = CONSTANTS.FAILED;
            res.message = CONSTANTS.OPP_LINEITEM_RES_MESSAGE;
        }
        
        res.hasEditAccess = userHasEditAccess(opportunityId);
        
        return res;
    }
    
    @AuraEnabled
    public static void getOppLineItemsList(){
        
    }
    
    /* commented by pkumarlg not used in any method, keep it for now to see the impact
* @InvocableMethod
public static void populateOpportunityLineItemWhenCreateOpp(List<Id> opportunityIds) {
List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
// NOTE : did not bulkify the code because it is POC
Id opportunityId = opportunityIds.get(0);
Map<String, Decimal> resultList = new Map<String, Decimal>();
Opportunity opp = [select id, Space__r.RentableArea__c from opportunity where id = :opportunityId];
Decimal spaceSize = opp.Space__r.RentableArea__c; // will be unit
//Id currentPriceBook = opp.Property__r.CurrentPricebook__c;

List<PricebookEntry> entries = [select id, IsActive, Product2Id, Product2.Name, Product2.DefaultPrice__c from PricebookEntry where  Product2.Family='Recoveries - Semi-Gross'];
List<OpportunityLineItem> existingLineItems = [select id, OpportunityId, name from OpportunityLineItem where OpportunityId= :opportunityId];
if (existingLineItems.size() == 0 && spaceSize > 0) {
// space from null to new space, tell by opportunity line item
for (PricebookEntry entry : entries) {
if (entry.IsActive) {
OpportunityLineItem lineItem = new OpportunityLineItem();
lineItem.Product2Id = entry.Product2Id;
lineItem.Quantity = spaceSize;
lineItem.OpportunityId = opportunityId;
lineItem.PricebookEntryId = entry.Id;
lineItems.add(lineItem);   
}
}   
} else {
// space is changed and update the price
for (OpportunityLineItem lineItem : existingLineItems) {
lineItem.Quantity = spaceSize;
lineItems.add(lineItem);
}
}
upsert lineItems;
}*/
    
    @AuraEnabled  
    public static Map<String, Decimal> getPriceList(Id opportunityId) {
        Map<String, Decimal> resultList = new Map<String, Decimal>();
        Opportunity opp = [select id, Space__r.RentableArea__c, DealType__c, pricebook2id  from opportunity where id = :opportunityId];
        Decimal spaceSize = opp.Space__r.RentableArea__c;
        String dealType = opp.DealType__c;
        String productFamily = CONSTANTS.EMPTY;
        
        if(dealType.equals('Net')){
            productFamily = CONSTANTS.RECOVERIES_NET;
        }
        else if(dealType.equals('Gross')){
            productFamily = CONSTANTS.RECOVERIES_GROSS;
        }
        else{
            productFamily = CONSTANTS.RECOVERIES_SEMI_GROSS;
        }
        
        List<PricebookEntry> entries = [select id, IsActive, Product2.Name, Product2.DefaultPrice__c from PricebookEntry where Product2.Family=:productFamily and pricebook2id=:opp.pricebook2id Order By Product2.Name ];
        for (PricebookEntry entry : entries) {
            if (entry.IsActive) {
                Decimal defaultPrice = entry.Product2.DefaultPrice__c != null ? entry.Product2.DefaultPrice__c : 0;
                resultList.put(entry.Product2.Name, defaultPrice);  
            }
        }
        
        return resultList;
    }
    
    /**
* Describe: According to promotion fund meta data to calculate promotion fund
*/
    /*private static Double calculatePromotionFundBasedOnFund(String leaseType, Decimal currentRent) {
Decimal promotion= 0;
List<PromotionFund__mdt> promotionFunds = [select id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c, MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c, RentRangeMax__c, RentRangeMin__c, Type__c from PromotionFund__mdt where RentRangeMin__c <= :currentRent and RentRangeMax__c >= :currentRent and Type__c = :leaseType];   
if (promotionFunds.size() == 1) {

PromotionFund__mdt promotionFund = promotionFunds.get(0);
promoMinValue = promotionFund.MinimumPromotionFund__c;
promoMaxValue = promotionFund.MaxPromotionFund__c;
//promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
if (promotionFund.MinRequired__c != null && promotionFund.MinRequired__c) {
//promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
promotion = currentRent * promotionFund.CategoryPecentage__c / 100;

//if(promotion < promotionFund.MinimumPromotionFund__c)
//    promotion = promotionFund.MinimumPromotionFund__c;
//else if(promotion > promotionFund.MaxPromotionFund__c)
//    promotion = promotionFund.MaxPromotionFund__c;

} else if (promotionFund.MaxRequired__c!= null && promotionFund.MaxRequired__c) {
//promotion =  promotionFund.CategoryAmount__c + (currentRent - promotionFund.RentRangeMin__c + 1) * promotionFund.CategoryPecentage__c / 100 > promotionFund.MaxPromotionFund__c ? promotionFund.MaxPromotionFund__c : promotionFund.CategoryAmount__c + (currentRent - promotionFund.RentRangeMin__c + 1) * promotionFund.CategoryPecentage__c / 100;
promotion = currentRent * promotionFund.CategoryPecentage__c / 100;

//if (promotion < promotionFund.MinimumPromotionFund__c) {
//    promotion = promotionFund.MinimumPromotionFund__c;
//} else if (promotion > promotionFund.MaxPromotionFund__c) {
//    promotion = promotionFund.MaxPromotionFund__c;
//}              
} else {
//promotion = promotionFund.CategoryAmount__c + (currentRent - promotionFund.RentRangeMin__c + 1) * promotionFund.CategoryPecentage__c / 100;
//promotion = currentRent * promotionFund.CategoryPecentage__c / 100;

// minmus should be always checked
promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
}
}
System.debug('promotion ' + promotion);
return promotion;
}*/
    
    //Abhishek M
    //@desc: Refactored the code for Promotion Fund calculation for AU (RPP - 10579)
    @testVisible
    private static Double calculatePromotionFundBasedOnFund(Opportunity opp, String leaseType, Decimal currentRent) {
        Decimal promotion= 0;
        
        List<PromotionFund__mdt> promotionFunds = [SELECT id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c, MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c, RentRangeMax__c, RentRangeMin__c, Type__c 
                                                   FROM PromotionFund__mdt 
                                                   WHERE RentRangeMin__c <= :currentRent 
                                                   AND RentRangeMax__c >= :currentRent 
                                                   AND Type__c = :leaseType];   
        
        if (promotionFunds.size() == 1) {
            PromotionFund__mdt promotionFund = promotionFunds.get(0);
            System.debug('10705Analysis debug  promotionFund>>>  '+promotionFund);
            
            Decimal promoMinValue = promotionFund.MinimumPromotionFund__c;
            Decimal promoMaxValue = promotionFund.MaxPromotionFund__c;
            Decimal oppNatAgreementMinThreshold = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
            Decimal oppNatAgreementMaxThreshold = opp.NationalAgreement__r.CurrentMaximumThreshold__c;
            
            System.debug('10705Analysis debug  promoMinValue>>>  '+promoMinValue);
            System.debug('10705Analysis debug  promoMaxValue>>>  '+promoMaxValue);
            System.debug('10705Analysis debug  oppNatAgreementMinThreshold>>>  '+oppNatAgreementMinThreshold);
            System.debug('10705Analysis debug  oppNatAgreementMaxThreshold>>>  '+oppNatAgreementMaxThreshold);
            
            
            if((promotionFund.MinRequired__c != NULL && promotionFund.MinRequired__c) || (promotionFund.MaxRequired__c!= NULL && promotionFund.MaxRequired__c)){
                promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
            }else {
                promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
            }
            System.debug('10705Analysis debug/ promotion before'+promotion);
            promotion = comparePromoFund(promotion, oppNatAgreementMaxThreshold, oppNatAgreementMinThreshold, promoMaxValue, promoMinValue);
            System.debug('10705Analysis debug/ promotion after'+promotion);
        }
        
        System.debug('promotion: ' + promotion);
        System.debug(' Inside calculatePromotionFundBasedOnFund>>>>>>>>');
        return promotion;
    }
    
    /*public static Double calculatePromotionFundBasedOnNatAgree(List<Opportunity> oppLst, Decimal currentRent) {
Decimal promotion= 0;
Decimal min = 0;
Decimal max = 999999999999.99;
if(oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c != null){
min = oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c;
}
if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c != null){
max = oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c;
}
if (oppLst.size()>0) {
promotion = currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 >= min ? currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 : min;
promotion = promotion <= max ? promotion : max;
}
System.debug('promotion ' + promotion);
return promotion;
}*/
    
    //Abhishek M
    //@desc: Refactored the code for Promotion Fund calculation for NatAgreement PromoPercentage (RPP - 10579)
    public static Double calculatePromotionFundBasedOnNatAgree(List<Opportunity> oppLst, Decimal currentRent, String leaseType) {
        Decimal promotion= 0;
        Decimal min = 0;
        Decimal max = 999999999999.99;
        
        /*  if(oppLst[0].NationalAgreement__r.PromoPercentage__c != NULL && oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c == Null && oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c == Null){
promotion = currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 >= min ? currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 : min;
System.debug('promotion 1a >>>>>'+promotion);
promotion = promotion <= max ? promotion : max;
System.debug('promotion 1b >>>>>'+promotion);
return promotion;
}*/
        
        
        
        List<PromotionFund__mdt> promotionFunds = [SELECT id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c, MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c, RentRangeMax__c, RentRangeMin__c, Type__c 
                                                   FROM PromotionFund__mdt 
                                                   WHERE RentRangeMin__c <= :currentRent 
                                                   AND RentRangeMax__c >= :currentRent 
                                                   AND Type__c = :leaseType];
        System.debug('promotionFunds CategoryPercentage'+promotionFunds[0].CategoryPecentage__c);
        //10705 start
        /*  
if(oppLst.size() > 0){
if(oppLst[0].NationalAgreement__r.PromoPercentage__c == Null || oppLst[0].NationalAgreement__r.PromoPercentage__c == 0){
if(promotionFunds[0].CategoryPecentage__c != Null){
promotion = currentRent * promotionFunds[0].CategoryPecentage__c / 100 ;
//MaxPromotionFund__c  MinimumPromotionFund__c
if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c == Null && oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c == Null){

}
}

}else{
promotion = currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 ;
if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c == Null && oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c == Null){
return promotion;
}else{
if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c != Null && promotion >= oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c){
promotion = oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c;
}
if(oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c != Null && promotion <= oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c){
promotion = oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c;
}
return promotion;
}
}
} */
        
        //10705 start2
        if(oppLst[0].NationalAgreement__r.PromoPercentage__c != Null && oppLst[0].NationalAgreement__r.PromoPercentage__c != 0){
            
            promotion = currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 ;
            if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c == Null && oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c == Null){
                return promotion;
            }else{
                if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c != Null && promotion >= oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c){
                    promotion = oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c;
                }
                if(oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c != Null && promotion <= oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c){
                    promotion = oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c;
                }
                return promotion;
            }
            
        }
        
        //10705 end
        
        
        if(oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c != null){
            min = oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c;
        }
        System.debug('min sonal >>>>>'+min);
        if(oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c != null){
            max = oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c;
        }
        System.debug('max sonal >>>>>'+max);
        if (oppLst.size()>0){
            Decimal promoMinValue = promotionFunds[0].MinimumPromotionFund__c;
            Decimal promoMaxValue = promotionFunds[0].MaxPromotionFund__c;
            Decimal oppNatAgreementMinThreshold = oppLst[0].NationalAgreement__r.CurrentMinimumThreshold__c;
            Decimal oppNatAgreementMaxThreshold = oppLst[0].NationalAgreement__r.CurrentMaximumThreshold__c;
            System.debug('promotionFunds CategoryPercentage'+promotionFunds[0].CategoryPecentage__c);
            
            promotion = currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 >= min ? currentRent * oppLst[0].NationalAgreement__r.PromoPercentage__c / 100 : min;
            System.debug('promotion sonal >>>>>'+promotion);
            promotion = comparePromoFund(promotion, oppNatAgreementMaxThreshold, oppNatAgreementMinThreshold, promoMaxValue, promoMinValue);
            System.debug('promotion sonal >>>>>'+promotion);
        }
        
        System.debug('promotion: ' + promotion);
        System.debug('inside calculatePromotionFundBasedOnNatAgree>>>>>');
        return promotion;
    }
    
    /*private static Double calculatePromotionFundBasedOnFundNZ(String NZproperty, Decimal currentRent, Boolean isThresholdApplicable) {
List<PromotionFund__mdt> promotionFunds = [select id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c, MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c, RentRangeMax__c, RentRangeMin__c, Type__c from PromotionFund__mdt where RentRangeMin__c <= :currentRent and RentRangeMax__c >= :currentRent];   
Decimal promotion= 0;
if (promotionFunds.size() > 0){
//PromotionFund__mdt promotionFund = promotionFunds.get(0);
//promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
for(PromotionFund__mdt promotionFund : promotionFunds){
if(NZproperty.contains(promotionFund.Type__c)){
//if(isThresholdApplicable){
//    promotion = currentRent * promotionFund.CategoryPecentage__c / 100 >= promotionFund.MinimumPromotionFund__c ? currentRent * promotionFund.CategoryPecentage__c / 100 : promotionFund.MinimumPromotionFund__c;
//    promotion = promotion <= promotionFund.MaxPromotionFund__c ? promotion : promotionFund.MaxPromotionFund__c;
//}else{
//    promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
//}

promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
promoMinValue = promotionFund.MinimumPromotionFund__c;
promoMaxValue = promotionFund.MaxPromotionFund__c;
}
}
}

return promotion;
}*/
    
    //Abhishek M
    //@desc: Refactored the code for Promotion Fund calculation for NZ (RPP - 10579)
    @testVisible
    private static Double calculatePromotionFundBasedOnFundNZ(Opportunity opp, String NZproperty, Decimal currentRent, Boolean isThresholdApplicable) {
        Decimal promotion= 0;
        List<PromotionFund__mdt> promotionFunds = [SELECT Id, CategoryAmount__c, CategoryPecentage__c, MaxPromotionFund__c, MaxRequired__c, MinimumPromotionFund__c, MinRequired__c, RentCategory__c, RentRangeMax__c, RentRangeMin__c, Type__c 
                                                   FROM PromotionFund__mdt 
                                                   WHERE RentRangeMin__c <= :currentRent 
                                                   AND RentRangeMax__c >= :currentRent];
        
        
        if (promotionFunds.size() > 0){
            for(PromotionFund__mdt promotionFund : promotionFunds){
                if(NZproperty.contains(promotionFund.Type__c)){
                    Decimal promoMinValue = promotionFund.MinimumPromotionFund__c;
                    Decimal promoMaxValue = promotionFund.MaxPromotionFund__c;
                    Decimal oppNatAgreementMinThreshold = opp.NationalAgreement__r.CurrentMinimumThreshold__c;
                    Decimal oppNatAgreementMaxThreshold = opp.NationalAgreement__r.CurrentMaximumThreshold__c;
                    
                    promotion = currentRent * promotionFund.CategoryPecentage__c / 100;
                    
                    promotion = comparePromoFund(promotion, oppNatAgreementMaxThreshold, oppNatAgreementMinThreshold, promoMaxValue, promoMinValue);
                }
            }
        }
        
        System.debug('promotion: ' + promotion);
        System.debug('Sonal inside calculatePromotionFundBasedOnFundNZ>>>>>>>>');
        return promotion;
    }
    
    public static Decimal comparePromoFund(Decimal promotion, Decimal aMaxValue, Decimal aMinValue, Decimal mMaxValue, Decimal mMinValue){
        System.debug('inside comparePromoFund aMaxValue >>>'+aMaxValue);
        System.debug('inside comparePromoFund aMinValue >>>'+aMinValue);
        System.debug('inside comparePromoFund mMaxValue >>>'+mMaxValue);
        System.debug('inside comparePromoFund mMinValue >>>'+mMinValue);
        
        Boolean alreadyCorrected = FALSE;
        System.debug('promotion inside comparePromoFund 1 >>>'+promotion);
        if(aMaxValue != NULL){
            if(promotion > aMaxValue){
                promotion = aMaxValue;
                alreadyCorrected = TRUE;
                System.debug('promotion inside comparePromoFund 1st if '+promotion);
            }
        }else if(mMaxValue != NULL && promotion > mMaxValue){
            System.debug('promotion inside comparePromoFund 1st else'+promotion);
            promotion = mMaxValue;
            alreadyCorrected = TRUE;
        }
        
        if(aMinValue != NULL && alreadyCorrected == FALSE){
            if(promotion < aMinValue)
                promotion = aMinValue;
            System.debug('promotion inside comparePromoFund 2nd if'+promotion);
        }else if(mMinValue != NULL && promotion < mMinValue && alreadyCorrected == FALSE){
            promotion = mMinValue;
            System.debug('promotion inside comparePromoFund 2nd else'+promotion);
        }
        System.debug('promotion inside comparePromoFund 2'+promotion);
        return promotion;
    }
    
    @AuraEnabled
    public static Map<String, Double> getRentInfo(Id opportunityId, Decimal currentRent, Decimal grossRent, 
                                                  Decimal pecentageOfRent, Boolean isPromotionIncluded, 
                                                  String leaseType, Boolean isNZProperty, String nzProperty, 
                                                  Boolean promoThresholdApplies) {
        Map<String, Decimal> resultList = new Map<String, Decimal>();
        Decimal promotion = 0.00;
        
        List<Opportunity> oppList = [SELECT Id, NationalAgreement__r.PromoPercentage__c, NationalAgreement__r.CurrentMinimumThreshold__c, NationalAgreement__r.CurrentMaximumThreshold__c, DealType__c, AnnualMinimumRent__c, Is_Promotion_Fund_Changed__c, TotalPromotionLevy__c
                                     FROM Opportunity 
                                     WHERE Id =: opportunityId];
        // Calculate promotion fund		//RPP - 10985 Line No: 1126 to 1128
        if((isPromotionIncluded && oppList[0].TotalPromotionLevy__c != 0) || oppList[0].Is_Promotion_Fund_Changed__c == True){     
            promotion = oppList[0].TotalPromotionLevy__c;
        }else if(isPromotionIncluded && oppList[0].NationalAgreement__r.PromoPercentage__c != NULL && leaseType != null){
            promotion = calculatePromotionFundBasedOnNatAgree(oppList, currentRent, leaseType);
        }else if (isNZProperty != null && !isNZProperty && currentRent != null && currentRent > 0 && isPromotionIncluded !=null && isPromotionIncluded && leaseType != null) {
            promotion = calculatePromotionFundBasedOnFund(oppList[0], leaseType, currentRent);
        }else if(isNZProperty && currentRent > 0 && isPromotionIncluded && nzProperty != null){
            promotion = calculatePromotionFundBasedOnFundNZ(oppList[0], nzProperty, currentRent, promoThresholdApplies);
        }
                                                      
         if(promotion != null)
            resultList.put('PromotionFund', promotion);
        
        return resultList;
    }
    
    public static budgetDataWrapper populateBudgetData(String id, String label, Date effectiveDate, Decimal amount, Decimal rent){
        budgetDataWrapper bdWrap = new budgetDataWrapper();
        bdWrap.id = id;
        bdWrap.BudgetType = label;
        bdWrap.EffectiveDate = effectiveDate;
        bdWrap.Budget = amount;
        bdWrap.Variance = rent - amount;
        return bdWrap;
    }
    
    
    @AuraEnabled
    public static List<budgetDataWrapper> getBudgetData(Id opportunityId, String type, Decimal rent) {
        
        List<budgetDataWrapper> bdWrapLst = new List<budgetDataWrapper>();
        Opportunity opp = [Select Id,EffectiveDate__c, Stretch_Rent_Variance__c, Stretch_Rent__c, Space__r.LatestJVBudget__r.EffectiveDate__c, Space__r.LatestBudget__r.EffectiveDate__c, 
                           Space__r.LatestForecast__r.EffectiveDate__c, Space__r.UsableArea__c, Space__r.Type__c, Space__r.RentableArea__c, 
                           Space__r.LatestForecastedRent__c,Space__r.LatestForecastedNetRent__c,Space__r.LatestBudgetedNetRent__c,Space__r.LatestJVBudgetedNetRent__c, Space__r.LatestJVBudgetedRent__c, Space__r.LatestBudgetedRent__c,Space__r.LatestBudgetedSemiGrossRent__c,
                           Space__r.LatestJVBudgetedSemiGrossRent__c,Space__r.LatestForecastedSemiGrossRent__c,Space__r.LatestBudgetedGrossRent__c,Space__r.LatestJVBudgetedGrossRent__c,
                           Space__r.LatestForecastedGrossRent__c
                           from Opportunity where id =: opportunityId];
        if(type == constants.OPP_LINEITEM_SEMI_GROSS){
            
            bdWrapLst.add(populateBudgetData('sg1',constants.LAT_BUDGSGRENT,
                                             opp.Space__r.LatestBudget__r.EffectiveDate__c,
                                             opp.Space__r.LatestBudgetedSemiGrossRent__c,
                                             rent));
            
            bdWrapLst.add(populateBudgetData('sg2',constants.LAT_JVBUDSGRENT,
                                             opp.Space__r.LatestJVBudget__r.EffectiveDate__c,
                                             opp.Space__r.LatestJVBudgetedSemiGrossRent__c,
                                             rent));
            
            bdWrapLst.add(populateBudgetData('sg3',constants.LAT_LFORCSGRENT,
                                             opp.Space__r.LatestForecast__r.EffectiveDate__c,
                                             opp.Space__r.LatestForecastedSemiGrossRent__c,
                                             rent)); 
            
            // Below code is added to implement RPP-10975
            bdWrapLst.add(populateBudgetData('sg4',constants.LAT_STRERENT,
                                             opp.EffectiveDate__c,
                                             opp.Stretch_Rent__c,
                                             rent));  
            
            
        }else if(type == constants.OPP_LINEITEM_NET){
            
            bdWrapLst.add(populateBudgetData('n1',constants.LAT_BUDGRENT,
                                             opp.Space__r.LatestBudget__r.EffectiveDate__c,
                                             opp.Space__r.LatestBudgetedNetRent__c,
                                             rent));
            
            bdWrapLst.add(populateBudgetData('n2',constants.LAT_JVBUDRENT,
                                             opp.Space__r.LatestJVBudget__r.EffectiveDate__c,
                                             opp.Space__r.LatestJVBudgetedNetRent__c,
                                             rent));
            
            bdWrapLst.add(populateBudgetData('n3',constants.LAT_LFORCRENT,
                                             opp.Space__r.LatestForecast__r.EffectiveDate__c,
                                             opp.Space__r.LatestForecastedNetRent__c,
                                             rent));
            
            // Below code is added to implement RPP-10975
            bdWrapLst.add(populateBudgetData('n4',constants.LAT_STRECRENT,
                                             opp.EffectiveDate__c,
                                             opp.Stretch_Rent__c,
                                             rent));
            
            
        }else if(type == constants.GROSS){
            
            bdWrapLst.add(populateBudgetData('g1',constants.LAT_BUDSGRENT,
                                             opp.Space__r.LatestBudget__r.EffectiveDate__c,
                                             opp.Space__r.LatestBudgetedGrossRent__c,
                                             rent));
            
            bdWrapLst.add(populateBudgetData('g2',constants.LAT_JVBUDGRENT,
                                             opp.Space__r.LatestJVBudget__r.EffectiveDate__c,
                                             opp.Space__r.LatestJVBudgetedGrossRent__c,
                                             rent));
            
            bdWrapLst.add(populateBudgetData('g3',constants.LAT_LFORCGRENT,
                                             opp.Space__r.LatestForecast__r.EffectiveDate__c,
                                             opp.Space__r.LatestForecastedGrossRent__c,
                                             rent));
            
            // Below code is added to implement RPP-10975
            bdWrapLst.add(populateBudgetData('g4',constants.LAT_STRETCHRENT,
                                             opp.EffectiveDate__c,
                                             opp.Stretch_Rent__c,
                                             rent));
        }
        return bdWrapLst;
    }   
    
    @AuraEnabled
    public static Response savePercentageRentResult(Id opportunityId, String breakType, Decimal percentageRent, Decimal breakAmount, Decimal forecastedturnoveryear, Decimal forecastedpercentagerentyear, String breakReason) {
        Response res = new Response();
        res.userUITheme=Userinfo.getUiThemeDisplayed();
        Opportunity oppo = [Select ForecastedPercentageRentYear1__c,ForecastedTurnoverYear1__c,Id, ReasonForArtificialBreak__c, BreakAmount__c, BreakType__c, PercentageRentPercent__c From Opportunity where Id =:opportunityId Limit 1];
        if (oppo != null) {
            oppo.BreakType__c = breakType;
            System.debug(percentageRent);
            oppo.PercentageRentPercent__c = percentageRent;
            oppo.BreakAmount__c = breakAmount;
            oppo.ForecastedTurnoverYear1__c = forecastedturnoveryear;
            oppo.ReasonForArtificialBreak__c = breakReason;
            try{
                database.update(oppo);
            } catch(Exception e){
                res.status = CONSTANTS.FAILED;
                res.message = e.getMessage();
            }
        } else {
            res.status = CONSTANTS.FAILED;
            res.message = CONSTANTS.OPP_LINEITEM_RES_MESSAGE;
        }
        return res;
    }
    @AuraEnabled
    public static Response getOppSecDeposit(Id opportunityId) {
        Response res = new Response();
        res.userUITheme=Userinfo.getUiThemeDisplayed();
        List<OpportunityLineItem> opportunityLineItemList = [select id,opportunityid from Opportunitylineitem where opportunityid =: opportunityId];
        for(Opportunity opp : OpportunityLineItemBL.getOpportunitySecurityDeposit(opportunityLineItemList)){
            res.securitydeposit = opp.SecurityDeposit__c;
            break;
        }
        return res;
    }
    
    @AuraEnabled
    public static Boolean userHasEditAccess(Id opportunityId) {
        Boolean hasEditAccess = false;
        Boolean isOppLocked = false;
        Boolean isDealAchieved = false;
        Boolean userAccess = false;
        opportunity oppRecord = new Opportunity();
        if(opportunityId != null) {
            try {
                oppRecord = [SELECT id, DealAchieved__c,StageName,UpdateDealTermsCompleted__c FROM Opportunity WHERE id =: opportunityId];
            } catch(Exception e) {
                oppRecord = null;
            }
            if(Approval.isLocked(opportunityId)||(oppRecord.StageName==Constants.PROPOSE_ACCEPT&&!oppRecord.UpdateDealTermsCompleted__c)) {
                isOppLocked = true;
            }
        }
        if(oppRecord != null) {
            isDealAchieved = oppRecord.DealAchieved__c;
        }
        for(UserRecordAccess usrRecAcc : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userInfo.getUserId() AND RecordId =:opportunityId]){
            hasEditAccess = usrRecAcc.HasEditAccess;
        }      
        if(!isOppLocked && !isDealAchieved && hasEditAccess) {
            userAccess = true;
        }
        return userAccess;
    }
    
    @AuraEnabled
    public static LightningResponse refreshOutgoings(Opportunity opp){
        LightningResponse res = new LightningResponse();
        Map<Id, List<OpportunityLineItem>> successRefreshedOliMap = new Map<Id, List<OpportunityLineItem>>();
        
        try{
            successRefreshedOliMap = OutgoingsRefreshController.refreshOpportunityLineItem(new List<Opportunity>{opp});
        } catch(Exception e){
            res.status = Constants.FAILED;
            res.message = e.getMessage() + '>>>' + e.getStackTraceString();
        }
        
        return res;
    }
    
    //created on 27/Apr/2020 for handling rejection behaviour through PB-Opp_OnOpportunityInsertUpdate
    //RPP - 10985
    @InvocableMethod
    public static void CreateOppLineItem(List<Id> OpportunityIds){
        
        List<OpportunityLineItem> opportunityProductsList = new List<OpportunityLineItem>();
        Set<Id> priceBookIdSet = new Set<Id>();
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        PriceBookEntry promoRevPbe = new PriceBookEntry();
        Set<Id> propertyIdSet = new Set<Id>();
        Set<Id> opportunityAccountIdSet = new Set<Id>();
        Map<Id, Id> topParentAccountMap  = new Map<Id,Id>();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
        Map<String, PriceBookEntry> productNameandPricebookEntryMap = new Map<String, PriceBookEntry>();
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        
        Opportunity oppo = [SELECT Id,TotalPromotionLevy__c,TechByPassOnClone__c,RecordTypeId,Property__c,AccountId,AnnualMinimumRent__c,ProposedStartDate__c,
                            TermYr__c, TermMonths__c, TermDays__c, SecurityDeposit__c,PromoLevyIncluded__c,Reason_for_No_Promo_Levy__c, pricebook2Id,Property__r.PriceBook__c,TECH_OldPromotionFund__c,
                            Space__c,Space__r.BillingCategory__c,Space__r.Type__c,DealType__c,CurrencyIsoCode 
                            FROM opportunity 
                            WHERE Id In :OpportunityIds limit 1];
        
        String spacebillingcategory='NA';
        
        if(String.isNotBlank(oppo.Space__r.BillingCategory__c)){
            spacebillingcategory=oppo.Space__r.BillingCategory__c;
        }
        
        List<PricebookEntry> promotionpriceBookEntry = [SELECT Id, Product2Id from PricebookEntry where Pricebook2Id =:oppo.Property__r.PriceBook__c AND Product2.Family =:Constants.PROMO_MARKETING AND isActive = true AND Product2.SpaceBillingCategory__c INCLUDES (:spacebillingcategory) AND Product2.DealType__c INCLUDES (:oppo.DealType__c) AND CurrencyIsoCode=:oppo.CurrencyIsoCode AND Product2.SpaceType__c INCLUDES (:oppo.Space__r.Type__c) Limit 1];
        
        try{
            if(promotionpriceBookEntry != null && promotionpriceBookEntry.size()>0 && oppo.TECH_OldPromotionFund__c > 0){
                OpportunityLineItem lineItemPromotion = new OpportunityLineItem();
                lineItemPromotion.Product2Id = promotionpriceBookEntry[0].Product2Id;
                lineItemPromotion.UnitPrice = oppo.TECH_OldPromotionFund__c;
                lineItemPromotion.Quantity = 1;
                lineItemPromotion.OpportunityId = oppo.Id;
                lineItemPromotion.PricebookEntryId = promotionpriceBookEntry[0].id;
                opportunityProductsList.Add(lineItemPromotion);
                
                if(!oppo.TechByPassOnClone__c){
                    
                    priceBookIdSet.add(oppo.Pricebook2Id);
                    pbEntryList = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet);
                    List<OpportunityLineItem> existingOLI = [SELECT Id, OpportunityId, Product2Id, ProductFamily__c, CPIType__c
                                                             FROM OpportunityLineItem 
                                                             WHERE OpportunityId =: oppo.Id
                                                             AND Product2.Family =: Constants.PRODUCT_PROMO_REVIEW
                                                             AND Flexi_Rent__c = false
                                                             ORDER BY EffectiveFromDate__c];                
                    
                    Map<Id, PriceBookEntry> promoRevByPriceBookMap = new Map<Id, PriceBookEntry>();
                    promoRevByPriceBookMap = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet, Constants.PRODUCT_PROMO_REVIEW);
                    promoRevPbe = promoRevByPriceBookMap.get(oppo.Pricebook2Id);
                    
                    opportunityAccountIdSet.add(oppo.AccountId);
                    if(oppo.Property__c != null){
                        propertyIdSet.add(oppo.Property__c);
                    }
                    Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet));
                    topParentAccountMap = OpportunityBL.buildTopParentAccountMap(opportunityAccountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
                    nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
                    
                    Map<Id, Double> opptyWithRent = new Map<Id, Double>();
                    
                    oppLineItemWrapper.PromoMarketingPrice = oppo.TECH_OldPromotionFund__c;
                    oppLineItemWrapper.opportunityRecord = oppo;
                    oppLineItemWrapper.opportunityRecordtypeName = RecordTypeUtil.getAllRecordTypesById(Constants.OPPORTUNITY).get(oppo.RecordTypeId).getName();
                    oppLineItemWrapper.propertyMap = propertyMap;
                    oppLineItemWrapper.nationalAgreementClauseMap = nationalAgreementClauseMap;
                    oppLineItemWrapper.topParentAccountMap = topParentAccountMap;
                    oppLineItemWrapper.productNameandPricebookEntryMap = productNameandPricebookEntryMap;
                    opportunityProductsList.addAll(OpportunityBL.createUpdateReviewsforOpportunity(null, oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, promoRevPbe,existingOLI)); // LF RPP-10151 9.5.2019 //RPP-10674 - Changed the method
                    
                }
            }
            Database.upsert(opportunityProductsList);
        }catch(Exception e){
            system.debug(e.getMessage());
        }
    }
}