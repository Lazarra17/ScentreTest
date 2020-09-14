/**
* @author:			Kyle Tan
* @description:		Test class for AddReviewModalController
**/
@isTest
private class AddReviewModalControllerTest {
    
    @testSetup
    private static void testSetup(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);        
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<Product2> productList = new List<Product2>();
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        List<Space__c> spaceList = new List<Space__c>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PRODUCT
        productList.add(TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT));
        database.insert(productList);
        productList = [SELECT Id FROM Product2];
        
        //CREATE PRICEBOOK ENTRY
        pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[0]));
        database.insert(pricebookEntryList);
        pricebookEntryList = [SELECT Id FROM PricebookEntry];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);

        //CREATE SPACE
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].type__c = '1';
        spaceList[0].BillingCategory__c = 'NA';
        database.insert(spaceList);
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(1, parentAccList[0], propertyList, spaceList);
        system.runAs(testUser) {
            database.insert(opportunityList);
        }
        opportunityList = [SELECT Id, TermYr__c, ProposedStartDate__c FROM Opportunity];
        
    }
    /*
    * @author:              Kyle Tan
    * @description:         this method tests if a line item is correctly inserted via insertRent method in AddReviewModalController
    */
    private static testMethod void insertRentReviewTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Product2> productList = new List<Product2>([SELECT Id FROM Product2]);
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>([SELECT Id FROM PricebookEntry]);
       
        system.runAs(testUser) {
            Test.startTest();
            for(Integer i = 0; i < 10; i++) {
                AddReviewModalController.insertRentReview('Non-Standard', 
                                                          'National', 
                                                          String.valueOf(date.today()), 
                                                          String.valueOf(date.today()), 
                                                          null, 
                                                          opportunityList[0].Id, 
                                                          pricebookEntryList[0].Id, 
                                                          productList[0].Id,
                                                          'Market',
                                                          '100',
                                                          10);
            }
            Test.stopTest();
        }
        
        //system.assertEquals(10, [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityList[0].Id].size());
    }
}