@isTest
private class RentUtilityTest
{
    @TestSetup 
    private static void testSetup() {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);   
        Map<String, Schema.RecordTypeInfo> precclasueRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PRECEDENT_CLAUSE_API);
        Pricebook2 pricebookRecord = new Pricebook2();
        List<Product2> productList = new List<Product2>();
        List<Property__c> propertyList = new List<Property__c>();
        PrecedentClause__c precRecord = new PrecedentClause__c();
        List<Account> accountList = new List<Account>();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        List<PricebookEntry> pricebookEntryList2 = new List<PricebookEntry>(); 
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        //CREATE PRICEBOOK
        pricebookRecord = TestDataFactory.createPricebook();
        try {
            database.insert(pricebookRecord);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        try {
            pricebookRecord = [SELECT Id FROM Pricebook2 LIMIT 1];
        } catch (Exception e) {
            pricebookRecord = NULL;
        }
        
        
        //CREATE PRODUCT
        productList.add(TestDataFactory.createProduct(CONSTANTS.OPP_LINEITEM_BASERENT_NET, Constants.RENT));
        productList.add(TestDataFactory.createProduct('Promotion Fund', CONSTANTS.PROMO_MARKETING));
        productList.add(TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, CONSTANTS.RECOVERIES_GROSS));
        productList[0].dealtype__c = 'Gross';
        productList[0].ProductCode = CONSTANTS.OTG;
        productList[0].SpaceBillingCategory__c = 'NA';
        productList[0].OutgoingsCategory__c = 'Air Con';
        
        productList[1].dealtype__c = 'Gross';
        productList[1].SpaceBillingCategory__c = 'NA';
        productList[1].ProductCode = CONSTANTS.OTG;
        productList[1].OutgoingsCategory__c = 'Council Rates';  
        
        productList[2].dealtype__c = 'Gross';
        productList[2].SpaceBillingCategory__c = 'NA';
        productList[2].OutgoingsCategory__c = 'Council Rates';  
        productList[2].ProductCode = CONSTANTS.OTG;
        
        try {
            database.insert(productList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        try {
            productList = [SELECT Id FROM Product2];
        } catch (Exception e) {
            productList = NULL;
        }
        
        //System.debug('Product List ' + productList);
        
        //CREATE PRICEBOOK ENTRY
        pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[1]));
        pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[0]));
        try {
            database.insert(pricebookEntryList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        pricebookEntryList2.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[1]));
        pricebookEntryList2.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[0]));
        pricebookEntryList2[1].pricebook2id = pricebookRecord.id;
        pricebookEntryList2[0].pricebook2id = pricebookRecord.id; 
        try {
            database.insert(pricebookEntryList2);
        } catch (Exception e) {
            errorHandler.createError(e);
        }        
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        propertyList[0].PriceBook__c = pricebookRecord.id;
        propertyList[0].ApplicableOutgoings__c = 'Air Con;Council Rates;Land Tax;Water Rates;Sunday Trade - Air Con;Sunday Trade;Operating Expenses;Emergency Levy';
        try {
            database.insert(propertyList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        try {
            propertyList = [SELECT Id FROM Property__c];
        } catch (Exception e) {
            propertyList = NULL;
        }
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        try {
            database.insert(accountList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }        
        
        Profile profileRec;
        try {
            profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        } catch (Exception e) {
            profileRec = NULL;
        }
        
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        for(Space__c spaceRec : spaceLst){
            spaceRec.type__c = '2';
            spaceRec.RentableArea__c = 12;
        }
        
        try {
            database.insert(spaceLst);
        } catch (Exception e) {
            errorHandler.createError(e);
        }           
        
        List<SpaceProduct__c> spaceProductList = TestDataFactory.createSpaceProduct(1,spaceLst[0], CONSTANTS.RENT, productList[0]);
        //System.debug('Space Product Before' + spaceProductList);
        
        try {
            database.insert(spaceProductList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }              
        
        try {
            spaceLst = [SELECT Id, ApplicableOutgoings__c, NumberOfProducts__c, SpaceProductsApplies__c FROM Space__c];
        } catch (Exception e) {
            spaceLst = NULL;
        }           
        
        contrList = TestDataFactory.createContract(1, accountList[0]);
        for(Contract__c contractRec : contrList){
            contractRec.Space__c = spaceLst[0].id;
        }
        database.insert(contrList);
        //CREATE PRECEDENT CLAUSE
        precRecord = TestDataFactory.createPrecedentClause(1, accountList[0].Id, precclasueRecordTypeMapByName.get(CONSTANTS.NATIONAL_AGREEMENTS).getRecordTypeId());
        precRecord.PromoPercentage__c = 0;
        try {
            database.insert(precRecord);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        try {
            precRecord = [SELECT Id, PromoPercentage__c, CurrentMinimumThreshold__c, CurrentMaximumThreshold__c FROM PrecedentClause__c];
        } catch (Exception e) {
            precRecord = NULL;
        }          
        
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0].Id, precRecord);
        for(Opportunity opp : opportunityList){
            opp.pricebook2id = pricebookRecord.id;
            opp.property__c = propertyList[0].id;
            opp.space__c = spaceLst[0].id;
            opp.DealType__c = 'Gross';
            opp.CurrencyIsoCode = 'AUD';
            opp.AnnualMinimumRent__c = 2000;
            opp.PercentageRentIncluded__c = true;
            opp.ProposedStartDate__c = system.today();
            opp.ProposedRentCommencementDate__c = system.today();
            opp.RentInAdvance__c = 1000;
            opp.SecurityDeposit__c = 1000;
            opp.PromoLevyIncluded__c = 'Yes';
            opp.NationalAgreement__c = precRecord.Id;
            //opp.UsageClause__c
            opp.StageName = Constants.UNDERSTAND_NEGOTIATE;
        }
        
        try {
            database.insert(opportunityList);
        } catch (Exception e) {
            system.debug('Exception: '+e.getMessage());
            system.debug('Exception: '+e.getLineNumber());
            errorHandler.createError(e);
        }        
        
        //Create Usage clause
        opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c, NationalAgreement__r.PromoPercentage__c, NationalAgreement__r.CurrentMinimumThreshold__c, NationalAgreement__r.CurrentMaximumThreshold__c FROM Opportunity];
        List<OpportunityClause__c> oppClauseRecordsList = new List<OpportunityClause__c>();
        oppClauseRecordsList = TestDataFactory.createOpportunityClause(1,opportunityList[0]);
        try {
            database.insert(oppClauseRecordsList);
        } catch (Exception e) {
            system.debug('Exception: '+e.getMessage());
            system.debug('Exception: '+e.getLineNumber());
            errorHandler.createError(e);
        }  
        
        //Update Opportunity with stage Issue Lease.
        Opportunity opp1 = opportunityList[0];
        opp1.StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
        
        try {
            database.update(opportunityList);
        } catch (Exception e) {
            system.debug('Exception: '+e.getMessage());
            system.debug('Exception: '+e.getLineNumber());
            errorHandler.createError(e);
        }  
        
        //Update Precedent Clause for promo percentage = 0
        precRecord.PromoPercentage__c = 80;
        try {
            database.update(precRecord);
        } catch (Exception e) {
            system.debug('Exception: '+e.getMessage());
            system.debug('Exception: '+e.getLineNumber());
            errorHandler.createError(e);
        }  
        
        
        Opportunity opp2 = opportunityList[0];
        opp2.Description = 'test';
        try {
            database.update(opportunityList);
        } catch (Exception e) {
            system.debug('Exception: '+e.getMessage());
            system.debug('Exception: '+e.getLineNumber());
            errorHandler.createError(e);
        }  
        
        opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(1, opportunityList[0], productList[0], pricebookEntryList2[0] );
        opportunityLineItemRecord.Flexi_Rent__c = false;
        opportunityLineItemRecord.CalculationMethod__c = CONSTANTS.SP_PERCENTAGE;
        opportunityLineItemRecord.AmortizedRent__c = 10000;
        opportunityLineItemRecord.Percentage__c = 2;
        opportunityLineItemRecord.EffectiveFromDate__c = date.today();
        opportunityLineItemList.add(opportunityLineItemRecord);
        try {
            database.insert(opportunityLineItemList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        Property__c propertyRecord = new Property__c();
        propertyRecord.Name = 'Test Property';
        propertyRecord.PropertyShortName__c = 'ABC';
        propertyRecord.Country__c = 'New Zealand';
        propertyRecord.PropertyCity__c = 'Newmarket';
        propertyRecord.CurrencyIsoCode = 'NZD';
        insert propertyRecord;
        
        List<Account> accountList1 = new List<Account>(); 
        accountList1.addAll(TestDataFactory.createAccountBulk(1, propertyRecord.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        try {
            database.insert(accountList1);
        } catch (Exception e) {
            //errorHandler.createError(e);
        }
        
        List<Opportunity> opportunityList1 = new List<Opportunity>();
        opportunityList1 = TestDataFactory.createOpportunity(accountList1);
        for(Opportunity opp : opportunityList1){
            //opp.pricebook2id = pricebookRecord.id;
            opp.property__c = propertyRecord.id;
            //opp.space__c = spaceLst[0].id;
            opp.DealType__c = 'Gross';
            opp.CurrencyIsoCode = 'AUD';
            opp.AnnualMinimumRent__c = 2000;
        }
        
        try {
            database.insert(opportunityList1);
        } catch (Exception e) {
            //errorHandler.createError(e);
        }        
        
    }
    
    private static testMethod void testGetRentInfoNZProperty(){
        List<Opportunity> oppList = [Select Id, AnnualMinimumRent__c, NZProperty__c, PromoLevyIncluded__c, DealType__c, NationalAgreement__r.PromoPercentage__c,NationalAgreement__r.CurrentMinimumThreshold__c,NationalAgreement__r.CurrentMaximumThreshold__c, NationalAgreement__r.Status__c 
                                     from Opportunity LIMIT 10];
        
        for(Opportunity opp : oppList){
            opp.NationalAgreement__c = null;
            opp.PromoLevyIncluded__c = 'Yes';
            opp.DealType__c = 'Semi Gross';
        }
        	
        Test.startTest();
        TriggerHandler.clearAllBypasses();
        Database.update(oppList);
        RentUtility.getRentInfo(oppList);
        Test.stopTest();
    }
    
    private static testMethod void testGetRentInfoNZProperty1(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        
        List<Opportunity> oppList = [Select Id, AnnualMinimumRent__c, NZProperty__c, PromoLevyIncluded__c, DealType__c, NationalAgreement__r.PromoPercentage__c,NationalAgreement__r.CurrentMinimumThreshold__c,NationalAgreement__r.CurrentMaximumThreshold__c, NationalAgreement__r.Status__c 
                                     from Opportunity WHERE Property__r.Country__c = 'New Zealand' LIMIT 10];
        
        for(Opportunity opp : oppList){
            opp.NationalAgreement__c = null;
            opp.PromoLevyIncluded__c = 'Yes';
            opp.DealType__c = 'Semi Gross';
        }
        
        Test.startTest();
        TriggerHandler.clearAllBypasses();
        Database.update(oppList);
        RentUtility.getRentInfo(oppList);
        Test.stopTest();
    }
}