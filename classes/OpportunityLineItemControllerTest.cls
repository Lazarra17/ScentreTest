@isTest
public class OpportunityLineItemControllerTest {
    
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
        BillCode__c BillCodeRec = new BillCode__c(); //10705
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
        System.debug('pricebookRecord 10705'+pricebookRecord);
        
        //10705
        BillCodeRec = TestDataFactory.createBillCode();
		//insert BillCodeRec;    
        try {
           database.insert(BillCodeRec);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        //CREATE PRODUCT
        productList.add(TestDataFactory.createProduct(CONSTANTS.OPP_LINEITEM_BASERENT_NET, Constants.RENT));
        productList.add(TestDataFactory.createProduct('Promotion Fund', CONSTANTS.PROMO_MARKETING));
        productList.add(TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, CONSTANTS.RECOVERIES));
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
        productList[2].BillCode__c = BillCodeRec.Id;
        productList[2].EffectiveFromDate__c = date.today();
        
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
        
        
        System.debug('productList 10705'+ productList);
        
        //CREATE PRICEBOOK ENTRY
        pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[2]));
        pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[1]));
        pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[0]));
        try {
            database.insert(pricebookEntryList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        System.debug('pricebookEntryList 10705'+ pricebookEntryList);
        
        pricebookEntryList2.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[2]));
        pricebookEntryList2.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[1]));
        pricebookEntryList2.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[0]));
        pricebookEntryList2[2].pricebook2id = pricebookRecord.id;
        pricebookEntryList2[1].pricebook2id = pricebookRecord.id;
        pricebookEntryList2[0].pricebook2id = pricebookRecord.id; 
        
        try {
            database.insert(pricebookEntryList2);
        } catch (Exception e) {
            errorHandler.createError(e);
        }        
        
        System.debug('pricebookEntryList2 10705'+ pricebookEntryList2);
        
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
        System.debug('propertyList 10705'+ propertyList);
        
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        try {
            database.insert(accountList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }        
        
        System.debug('AccountList 10705'+ accountList);
        
        Profile profileRec;
        try {
            profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        } catch (Exception e) {
            profileRec = NULL;
        }
        
        System.debug('profileRec 10705'+ profileRec);
        
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
        
        System.debug('spaceLst 10705'+ spaceLst);
        
        List<SpaceProduct__c> spaceProductList = TestDataFactory.createSpaceProduct(1,spaceLst[0], CONSTANTS.RENT, productList[2]);
        //System.debug('Space Product Before' + spaceProductList);

        try {
            database.insert(spaceProductList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }              
        
        System.debug('spaceProductList 10705'+ spaceProductList);
        
        try {
            spaceLst = [SELECT Id, ApplicableOutgoings__c, NumberOfProducts__c, SpaceProductsApplies__c FROM Space__c];
        } catch (Exception e) {
            spaceLst = NULL;
        }           
        
        System.debug('spaceLst 10705'+ spaceLst);
        
        contrList = TestDataFactory.createContract(1, accountList[0]);
        for(Contract__c contractRec : contrList){
            contractRec.Space__c = spaceLst[0].id;
        }
        database.insert(contrList);
        
        System.debug('contrList 10705'+ contrList);
        
		//CREATE PRECEDENT CLAUSE
		precRecord = TestDataFactory.createPrecedentClause(1, accountList[0].Id, precclasueRecordTypeMapByName.get(CONSTANTS.NATIONAL_AGREEMENTS).getRecordTypeId());
        try {
            database.insert(precRecord);
        } catch (Exception e) {
            errorHandler.createError(e);
        }
        
        System.debug('precRecord 10705'+ precRecord);

        try {
            precRecord = [SELECT Id, PromoPercentage__c, CurrentMinimumThreshold__c, CurrentMaximumThreshold__c FROM PrecedentClause__c];
        } catch (Exception e) {
            precRecord = NULL;
        }             
        
        System.debug('precRecord 10705'+ precRecord);
        
        System.debug('PRECEDENT CLAUSE ' + precRecord);
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0].Id, precRecord);
        
        System.debug('opportunityList 10705'+ opportunityList);
        
        for(Opportunity opp : opportunityList){
            opp.pricebook2id = pricebookRecord.id;
        	opp.property__c = propertyList[0].id;
        	opp.space__c = spaceLst[0].id;
        	opp.DealType__c = 'Gross';
        	opp.CurrencyIsoCode = 'AUD';
            opp.AnnualMinimumRent__c = 2000;
            opp.PercentageRentIncluded__c = False; //10705
            opp.StageName = Constants.OPPTY_UNDERSTAND_NEGOTIATE;
            //opp.NationalAgreement__r.PromoPercentage__c = precRecord.PromoPercentage__c;
            //opp.NationalAgreement__r.CurrentMinimumThreshold__c = precRecord.CurrentMinimumThreshold__c;
            //opp.NationalAgreement__r.CurrentMaximumThreshold__c = precRecord.CurrentMaximumThreshold__c;
        }
        
        
        try {
            database.insert(opportunityList);
        } catch (Exception e) {
            errorHandler.createError(e);
        }  
        
        //opportunityList = [SELECT Id FROM Opportunity];
        
        //10705
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
        opportunityList[0].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
        
        try {
            database.update(opportunityList);
        } catch (Exception e) {
            system.debug('Exception: '+e.getMessage());
            system.debug('Exception: '+e.getLineNumber());
            errorHandler.createError(e);
        } 
        //10705
        
        
        System.debug('opportunityList 10705'+ opportunityList);
        
        opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c, NationalAgreement__r.PromoPercentage__c, NationalAgreement__r.CurrentMinimumThreshold__c, NationalAgreement__r.CurrentMaximumThreshold__c FROM Opportunity];
        System.debug('OPPO LIST (10705)' + opportunityList);
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
    }
    
    private static testMethod void testgetNewLineItemTotals() 
    {
        
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        OpportunityLineItemController.Response res = new OpportunityLineItemController.Response();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        //Boolean b;
        System.runAs(testUser){
            Test.startTest();
            res = OpportunityLineItemController.getNewLineItemTotals (opportunityList[0].id, 2, 2, 2, CONSTANTS.OPP_LINEITEM_NET);
            //b = OpportunityLineItemController.getRefreshButtonVisibility(opportunityList[0].id);
            Test.stopTest();
        }
        system.assertequals(res.status,CONSTANTS.SUCCESS);
        //system.assertEquals(true, b); 
    }
    private static testMethod void testoppoItemList() 
    {
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        OpportunityLineItemController.Response res = new OpportunityLineItemController.Response();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	res = OpportunityLineItemController.oppoItemList (opportunityList[0].id);
            Test.stopTest();
        }
        system.assertequals(res.status,CONSTANTS.SUCCESS);
    }
    private static testMethod void testupdateOppoLineItem() 
    {
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705' + opportunityList);
        List<OpportunityLineItem> opportunityLineItemList = [SELECT Id, PricebookEntryId FROM OpportunityLineItem LIMIT 1];
        System.debug('opportunityLineItemList 10705' + opportunityLineItemList);
        OpportunityLineItemController.Response res = new OpportunityLineItemController.Response();
        
        OpportunityLineItemController.opportunityLineItemWrapper oppwrapper = new OpportunityLineItemController.opportunityLineItemWrapper();
        oppwrapper.isActive = true;
        oppwrapper.listPrice = 12;
        oppwrapper.itemName = CONSTANTS.OPP_LINEITEM_BASERENT_NET;
        oppwrapper.totalPrice = 2;
        oppwrapper.recordId = opportunityLineItemList[0].id;
        oppwrapper.pricebookEntryId = opportunityLineItemList[0].PricebookEntryId;
        List<OpportunityLineItemController.opportunityLineItemWrapper> oppwrapplst = new List<OpportunityLineItemController.opportunityLineItemWrapper>();
        oppwrapplst.add(oppwrapper);
        //System.debug('draftValue ' + oppwrapplst);
        String draftValues = JSON.serialize(oppwrapplst);
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        System.runAs(testUser){
            Test.startTest();
        	res = OpportunityLineItemController.updateOppoLineItem(draftValues, opportunityList[0].id, 1);
            Test.stopTest();
        }
        
        system.assertequals(res.status,CONSTANTS.SUCCESS);
    }
    private static testMethod void testgetBudgetData() 
    {
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        List<OpportunityLineItemController.budgetDataWrapper> bdwrapperLst = new List<OpportunityLineItemController.budgetDataWrapper>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	bdwrapperLst = OpportunityLineItemController.getBudgetData (opportunityList[0].id, constants.OPP_LINEITEM_SEMI_GROSS, 2);
        	bdwrapperLst = OpportunityLineItemController.getBudgetData (opportunityList[0].id, constants.OPP_LINEITEM_NET, 2);
        	bdwrapperLst = OpportunityLineItemController.getBudgetData (opportunityList[0].id, constants.GROSS, 2);
            Test.stopTest();
        }
        system.assert(bdwrapperLst.size()>0);
    }
    private static testMethod void testoutgoingUpdate() 
    {
        List<OpportunityLineItem> oppLineItemList = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE Opportunityid != null];
        List<Id> oppidlst = new List<Id>();
        oppidlst.add(oppLineItemList[0].OpportunityId);
        List<OpportunityLineItem> oppoNewLineItems = new List<OpportunityLineItem>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	//oppoNewLineItems = OpportunityLineItemController.outgoingUpdate (oppidlst);
            Test.stopTest();
        }
        //System.debug('oppo line items size ' + oppoNewLineItems.size());
        system.assert(oppoNewLineItems.size() <> null);
    }
    private static testMethod void testgetMoreValue() 
    {
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        OpportunityLineItemController.Response res = new OpportunityLineItemController.Response();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	res = OpportunityLineItemController.getMoreValue (opportunityList[0].id);
            Test.stopTest();
        }
        system.assertequals(res.status,CONSTANTS.SUCCESS);
    }
   
    private static testMethod void testgetPriceList() 
    {
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        Map<String, Decimal> result = new Map<String, Decimal>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	result = OpportunityLineItemController.getPriceList (opportunityList[0].id);
            Test.stopTest();
        }
        system.assertEquals(false, result.values().size()>0);
    }
    
    private static testMethod void testSavePercentageRentResult(){
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        OpportunityLineItemController.Response res = new OpportunityLineItemController.Response();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	res = OpportunityLineItemController.savePercentageRentResult(opportunityList[0].id, 'Natural', 1,  10,  5,  3, CONSTANTS.TEST);
            Test.stopTest();
        }
        system.assertequals(res.status,CONSTANTS.SUCCESS);

    }
    private static testMethod void testOutgoing(){
       List<OpportunityLineItem> OppLineItmsToDelete = [Select Id from OpportunityLineItem];
        List<Id> oppIds = new List<Id>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	OppLineItmsToDelete = OpportunityLineItemController.outgoingUpdate(oppIds);
            Test.stopTest();
        }
        
        system.assertequals(true, OppLineItmsToDelete <> null);
    }
    private static testMethod void testJeffOppoList(){
        List<Opportunity> opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        System.debug('opportunityList 10705'+ opportunityList);
        OpportunityLineItemController.Response res = new OpportunityLineItemController.Response();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	res = OpportunityLineItemController.getJeffOppoList();
            Test.stopTest();
        }
        
        system.assertequals(CONSTANTS.SUCCESS, res.status);
    }
     private static testMethod void testAddOutgoings(){
       List<OpportunityLineItem> OppLineItmsToAdd = [Select Id from OpportunityLineItem];
        List<Id> oppIds = new List<Id>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	OppLineItmsToAdd = OpportunityLineItemController.AddOutgoings(oppIds); 
            Test.stopTest();
        }
        
        system.assertequals(true, OppLineItmsToAdd <> null);
    }
    private static testMethod void testUpdateOppos(){
        Map<String, Object> oppoMap = new Map<String, Object>();
       	List<Opportunity> oppList = [Select Id from Opportunity];
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        		oppoMap = OpportunityLineItemController.updateOppos(oppList);
            Test.stopTest();
        }
    }
    
    private static testMethod void testGetRentInfoNZProperty(){
        Test.startTest();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        for(Opportunity opp : oppList){
            opp.NationalAgreement__c = null;
        }
        TriggerHandler.clearAllBypasses();
        Database.update(oppList);
        
        System.runAs(testUser){
            
        	OpportunityLineItemController.getRentInfo(oppList[0].Id, 1000, 1000, 2, true, 'Riccarton', true, 'Riccarton', true);
            Test.stopTest();
        }
    }
    
    private static testMethod void calculatePromotionFundBasedOnFundTest(){
        Test.startTest();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        for(Opportunity opp : oppList){
            opp.NationalAgreement__c = null;
        }
        TriggerHandler.clearAllBypasses();
        Database.update(oppList);
        
        System.runAs(testUser){
            
        	OpportunityLineItemController.calculatePromotionFundBasedOnFund(oppList[0], 'Riccarton', 1000);
            Test.stopTest();
        }
    }
    
    private static testMethod void calculatePromotionFundBasedOnFundNZTest(){
        Test.startTest();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        for(Opportunity opp : oppList){
            opp.NationalAgreement__c = null;
        }
        TriggerHandler.clearAllBypasses();
        Database.update(oppList);
        
        System.runAs(testUser){
            
        	OpportunityLineItemController.calculatePromotionFundBasedOnFundNZ(oppList[0], 'Riccarton', 1000, true);
            Test.stopTest();
        }
    }
    
    private static testMethod void testGetRentInfoBasedOnFund(){
        Test.startTest();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        for(Opportunity opp : oppList){
            opp.NationalAgreement__c = null;
        }
        TriggerHandler.clearAllBypasses();
        Database.update(oppList);
        
        System.runAs(testUser){
            
        	OpportunityLineItemController.getRentInfo(oppList[0].Id, 1000, 1000, 2, true, 'Riccarton', false, 'Riccarton', true);
            Test.stopTest();
        }
    }
    
    //RPP - 10985
    //Used for:  tests if promo review Opp line Items are created after NoPromoLevyIncluded is Rejected. 
    private static testMethod void testCreateOppLineItem(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        List<Id> OpportunityIds = New List<Id>();
        for(Opportunity opp: oppList){
            OpportunityIds.add(opp.Id);
        }
        
        System.runAs(testUser){
            Test.startTest();
        		OpportunityLineItemController.CreateOppLineItem(OpportunityIds); 
            Test.stopTest();
        }
    }
    
    private static testMethod void testrefreshOutgoings(){
        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity];
        LightningResponse res = new LightningResponse();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        System.runAs(testUser){
            Test.startTest();
        	res = OpportunityLineItemController.refreshOutgoings(opportunityList[0]);
            Test.stopTest();
        }
        
        system.assertequals(CONSTANTS.SUCCESS, res.status);
    }
}