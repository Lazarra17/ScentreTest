@isTest
public class HighRiskOpportunityClauseUtilityTest {
    @TestSetup private static void testSetup() {
        Property__c testProperty = new Property__c();
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        PriceBook2 pb = new PriceBook2 ();
        Product2 productBaseRentGross = new Product2();
        PricebookEntry pricebookEntryBaseRentGross = new PricebookEntry();
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
        
        List<OpportunityClause__c> oppoClause = TestDataFactory.createOpportunityClause(10, opportunityList[0]);
        insert oppoClause;
        
        contactRecord = [SELECT Id FROM Contact LIMIT 1];
        OpportunityContactRole oppContactRole = TestDataFactory.createOpportunityContactRole(opportunityList[0], contactRecord, CONSTANTS.TEAM_ROLE_CENTREMANAGER);
        insert oppContactRole;
    }
    public static testMethod void testGetOppClausePerProperty(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityClause__c> oppClauseList = [SELECT Id, Opportunity__c, Opportunity__r.Property__c FROM OpportunityClause__c LIMIT 10];
        
        Map<Id, Map<Id, List<OpportunityClause__c>>> getOppClausePerProperty = new Map<Id, Map<Id, List<OpportunityClause__c>>>();
        System.runAs(testUser) {
            
            Test.startTest();
            getOppClausePerProperty = HighRiskOpportunityClauseUtility.getOppClausePerProperty(oppClauseList);
            Test.stopTest();
        }
    }
    public static testMethod void testCountRCA(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Opportunity oppRecord = [SELECT Id, Category__c, Tech_SpaceType__c FROM Opportunity LIMIT 1];
        List<OpportunityClause__c> oppClauseList = [SELECT Id, Opportunity__c, Opportunity__r.Property__c,
                                                    Opportunity__r.Account.Category__c
                                                    FROM OpportunityClause__c 
                                                    WHERE Opportunity__c !=: oppRecord.Id];
        
        Map<Id, List<OpportunityClause__c>> oppIdOppClauseListMap = new Map<Id, List<OpportunityClause__c>>();
        oppIdOppClauseListMap.put(oppRecord.Id, oppClauseList);
        System.runAs(testUser) {
            
            Test.startTest();
            Opportunity countRCA = HighRiskOpportunityClauseUtility.countRCA(oppRecord, oppIdOppClauseListMap);
            Test.stopTest();
        }
    }   
}