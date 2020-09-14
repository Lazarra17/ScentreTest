/**
* @author:          Kyle Tan
* @description:     Test class for Rent Review Controller
**/
@isTest
private class RentReviewControllerTest {
    
    @testSetup
    private static void testSetup(){
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        PriceBook2 pb = new PriceBook2 ();
        Product2 promoProductRecord = new Product2();
        PricebookEntry pricebookEntryPromoRecord = new PricebookEntry();
        PricebookEntry pricebookEntryRent = new PricebookEntry();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityRecord = new Opportunity();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem OpportunityLineItemRecord = new OpportunityLineItem ();
        OpportunityLineItem opportunityLineItemRecordRent = new OpportunityLineItem();
        Integer loopInt = 0;
        Product2 productRecord;
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
        List<Product2> productList = new List<Product2>();
        promoProductRecord = TestDataFactory.createProduct(Constants.PRODUCT_PROMO_REVIEW, Constants.PRODUCT_FAMILY_PROMO_MARKETING);
        productList.add(promoProductRecord);
        promoProductRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.PRODUCT_FAMILY_PROMO_MARKETING);
        productList.add(promoProductRecord);
        database.insert(productList);
        
        //CREATE PricebookEntry
        pricebookEntryPromoRecord = TestDataFactory.createStandardPriceBookEntry(1, productList[0])[0];
        database.insert(pricebookEntryPromoRecord);
        pricebookEntryPromoRecord = [SELECT Id, Name, Pricebook2Id FROM PricebookEntry LIMIT 1];
        
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        productRecord = [SELECT Id, Family FROM Product2 WHERE Family = 'Rent'];        
        //CREATE PricebookEntry
        pricebookEntryRent = TestDataFactory.createStandardPriceBookEntry(1, productRecord)[0];
        database.insert(pricebookEntryRent);
        pricebookEntryRent = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(10, accountList[0]);
        insert opportunityList;
        
        //CREATE OpportunityLineItem
        for(Integer counter = 0; counter < 3; counter++) {
            if (counter < 3 ) {
                opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(counter, opportunityList[counter], promoProductRecord, pricebookEntryPromoRecord);
            }
            opportunityLineItemList.add(opportunityLineItemRecord);
            
        }
        
        for(Integer counter = 0; counter < 3; counter++) {
            if (counter < 3 ) {
               opportunityLineItemRecordRent = TestDataFactory.createOpportunityLineItem(counter, opportunityList[counter], productRecord, pricebookEntryRent);
            }
            opportunityLineItemList.add(opportunityLineItemRecordRent);
            
        }
        
        insert opportunityLineItemList;
        
    }
    /*
    * @author:              Kyle Tan
    * @description:         this method tests if the opportunity has rent review line items
    */
    private static testMethod void getOpportunityLineItemTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = [SELECT Id FROM OpportunityLineItem];
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Product2> productList = new List<Product2>([SELECT Id FROM Product2]);
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>([SELECT Id FROM PricebookEntry]);
        
        
        system.runAs(testUser) {
            Test.startTest();
                RentReviewController.getOpportunityLineItem(opportunityList[0].Id);
            Test.stopTest();
        }
        
        //system.assertEquals(20, opportunityLineItemList.size());
    }
    
    /*
    * @author:              Kyle Tan
    * @description:         this method tests if a rent review item is deleted
    */
    private static testMethod void deleteLineItemTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = [SELECT Id FROM OpportunityLineItem LIMIT 5];
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Product2> productList = new List<Product2>([SELECT Id FROM Product2]);
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>([SELECT Id FROM PricebookEntry]);
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        
        
        
        system.runAs(testUser) {
            Test.startTest();
            for(Opportunity oppRec : opportunityList) {
                RentReviewController.deleteLineItem(opportunityLineItemList[0].Id);
            }
            Test.stopTest();
        }
        
        system.assertEquals(5, [SELECT Id FROM OpportunityLineItem].size());
    }
    
    private static testMethod void testUserHasEditAccess() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = [SELECT Id FROM OpportunityLineItem LIMIT 5];
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Product2> productList = new List<Product2>([SELECT Id FROM Product2]);
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>([SELECT Id FROM PricebookEntry]);
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        
        
        
        system.runAs(testUser) {
            Test.startTest();
            for(Opportunity oppRec : opportunityList) {
                RentReviewController.userHasEditAccess(oppRec.Id);
            }
            Test.stopTest();
        }
        
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests if the rent review or promo review opportunity line items are updated
    						correctly
    */
    private static testMethod void getOppLineItemForUpdateTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = [SELECT Id FROM OpportunityLineItem];
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Id> opportunityLineItemIdList = New List<Id>();
        for(OpportunityLineItem oppLineItemRec : opportunityLineItemList){
            opportunityLineItemIdList.add(oppLineItemRec.Id);
        }
        String cpiType = Constants.NATIONAL;
        String stdReviewType = 'CPI';
        
        
        system.runAs(testUser) {
            Test.startTest();
                List<OpportunityLineItem> oppLineItemListForUpdate = RentReviewController.getOppLineItemForUpdate(opportunityList[0].Id, opportunityLineItemIdList, cpiType, stdReviewType);
            Test.stopTest();
        }
        
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests if the CPI Type Picklist values are fetched properly.
    */
    private static testMethod void getCPITypeValuesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        
        system.runAs(testUser) {
            Test.startTest();
                List<String> cpiTypeValueList = RentReviewController.getCPITypeValues();
            Test.stopTest();
            
        system.assert(cpiTypeValueList.size() > 0);
        }
    }
    
    /*
    * @author:              Shrikant Hase
    * @description:         this method tests if the Standard Review Type Picklist values are fetched properly.
    */
    private static testMethod void getStdReviewTypeValuesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        
        system.runAs(testUser) {
            Test.startTest();
                List<String> stdReviewTypeValueList = RentReviewController.getStdReviewTypeValues();
            Test.stopTest();
        
        system.assert(stdReviewTypeValueList.size() > 0);
        }
    }
     
}