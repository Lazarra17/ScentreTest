@isTest
public class OpportunityPairTest {
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
        opportunityList = TestDataFactory.createOpportunity(200, accountList[0]);
        insert opportunityList;
        
        
    }
    public static testMethod void testProduceKeyPairs(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 10];
        List<OpportunityPair.OppoPair> oppPairList = new List<OpportunityPair.OppoPair>();
        Set<String> oppIdSet = new Set<String>();
        
        for(Opportunity opp : oppList){
            oppIdSet.add(opp.Id);
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            oppPairList = OpportunityPair.produceKeyPairs(oppIdSet);
            Test.stopTest();
        }
        System.assertEquals(90, oppPairList.size());
    }
    
    public static testMethod void testCheckKeyPairExist() {
		Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityPair.OppoPair> oppPairList = new List<OpportunityPair.OppoPair>();
        OpportunityPair.OppoPair opp2 = new OpportunityPair.OppoPair();
        
        opp2.primaryOppoId = 'Opp1SecondaryString';
        opp2.secondOppoId = 'Opp1PrimaryString';
        oppPairList.add(opp2);
        
        
        System.runAs(testUser) {
            Test.startTest();
            OpportunityPair.checkKeyPairExist(oppPairList, 'Opp1PrimaryString', 'Opp1SecondaryString');
            oppPairList.clear();
            OpportunityPair.checkKeyPairExist(oppPairList, 'Opp1PrimaryString', 'Opp1SecondaryString');
            Test.stopTest();
        }
        
        System.assertEquals(false, !oppPairList.isEmpty());
    }
}