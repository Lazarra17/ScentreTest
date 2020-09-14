/*
* @author:          Kyle Tan
* @description:     Test Class for OpportunityLineItemBL
*/
@isTest
private class OpportunityLineItemBLTest{
    
    @TestSetup private static void testSetup() {
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        PriceBook2 pb = new PriceBook2 ();
        Product2 productBaseRentGross = new Product2();
        Product2 productFitoutContribution = new product2();
        Product2 productSundayTradeSemiGross = new Product2();
        Product2 productPromotionLevy = new Product2();
        Product2 productCouncilRatesNet = new Product2();
        PricebookEntry pricebookEntryBaseRentGross = new PricebookEntry();
        PricebookEntry pricebookEntryFitoutContribution = new PricebookEntry();
        PricebookEntry pricebookEntrySundayTradeSemiGross = new PricebookEntry();
        PricebookEntry pricebookEntryPromotionLevy = new PricebookEntry();
        PricebookEntry pricebookEntryCouncilRatesNet = new PricebookEntry();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityRecord = new Opportunity();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        Integer loopInt = 0;
        Product2 productRecord;
        
        //CREATE PRODUCT
        
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //CREATE PROPERTY
        testProperty = TestDataFactory.createPropertyRecord();
        testProperty.PriceBook__c = pricebookId;
        database.insert(testProperty);
        
        //CREATE ACCOUNT
        for(Integer counter = 0; counter < 5; counter++) {
            accountRecord = TestDataFactory.createAccount(counter, testProperty.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
            accountList.add(accountRecord);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Property__c FROM Account LIMIT 5];
        Contact contactRecord = TestDataFactory.createContact(CONSTANTS.TEST_FNAME, accountList[0]);
        insert contactRecord;
        //CREATE Products
        productBaseRentGross = TestDataFactory.createProduct(CONSTANTS.PRODUCT_BASE_RENT_GROSS, CONSTANTS.PRODUCT_FAMILY_RENT);
        database.insert(productBaseRentGross);
        productBaseRentGross = [SELECT Id FROM Product2 LIMIT 1];
        
        //CREATE PricebookEntry
        pricebookEntryBaseRentGross = TestDataFactory.createStandardPriceBookEntry(1, productBaseRentGross)[0];
        database.insert(pricebookEntryBaseRentGross);
        pricebookEntryBaseRentGross = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(10, accountList[0]);
        insert opportunityList;
        
        //CREATE OpportunityLineItem
        for(Integer counter = 0; counter < 5; counter++) {
            if (counter < 5 ) {
                opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(counter, opportunityList[counter], productBaseRentGross, pricebookEntryBaseRentGross );
            }
            opportunityLineItemList.add(opportunityLineItemRecord);
            
        }
        insert opportunityLineItemList;

    }
    
    public static testMethod void getOpportunitySecurityDepositTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>([SELECT Id, OpportunityId FROM OpportunityLineItem]);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, SecurityDeposit__c FROM Opportunity]);
        
        System.runAs(testUser) {
            
            Test.startTest();
            	opportunityList = OpportunityLineItemBL.getOpportunitySecurityDeposit(opportunityLineItemList);
            Test.stopTest();
        }
            system.assertEquals(true, opportunityList[0].SecurityDeposit__c <> 0);
    }
    
    public static testMethod void testUpdateOppLineItems(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>([SELECT Id, OpportunityId FROM OpportunityLineItem]);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, SecurityDeposit__c,ProposedRentCommencementDate__c FROM Opportunity]);
        List<OpportunityLineItem> updatedOppLineItemList = new List<OpportunityLineItem>();
        
        System.runAs(testUser) {
            
            Test.startTest();
            	updatedOppLineItemList = OpportunityLineItemBL.updateOppLineItems(opportunityList[0], opportunityLineItemList);
            Test.stopTest();
        }
            system.assertEquals(true, opportunityList[0].SecurityDeposit__c <> 0);
        
    }
}