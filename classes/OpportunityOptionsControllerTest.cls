@isTest
public class OpportunityOptionsControllerTest {
	@testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OPPORTUNITY);
        Opportunity opportunityRecord;          

        //CREATE ACCOUNT
        Account account;
        List<Account> accountList = new List<Account>();
        account = TestDataFactory.createAccount(1);
        accountList.add(account);
        Database.insert(accountList);
        
        //CREATE CONTACT
        Contact contact;
        List<Contact> contactList = new List<Contact>();
		contact = TestDataFactory.createContact('Contact', account);
        contactList.add(contact);
        Database.insert(contactList);
        
        //CREATE PROPERTY
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1);
        Database.insert(propertyList);
        
		//CREATE SPACE
		List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        Database.insert(spaceList);
        
        //CREATE PRICEBOOK
        Pricebook2 pricebook;
        List<Pricebook2> pbList = new List<Pricebook2>();
        pricebook = TestDataFactory.createPricebook();
        pbList.add(pricebook);
        Database.insert(pbList);
        
        //CREATE OPPORTUNITY
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(accountList);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
        Database.insert(oppList);
        
        //CREATE PRODUCT
        Product2 productRecord;
        List<Product2> productList = new List<Product2>();
        productRecord = TestDataFactory.createProduct('Options', 'Options');
        productList.add(productRecord);
        Database.insert(productList);
        
        //CREATE PRICEBOOK ENTRY
        PricebookEntry pbEntry;
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        pbEntry = TestDataFactory.createPriceBookEntryRecord('Options', productList[0], pbList[0]);
        pbEntryList.add(pbEntry);
        Database.insert(pbEntryList);
        
        System.debug('James oppList' + oppList);
        System.debug('James productList' + productList);
        System.debug('James pbEntryList' + pbEntryList);
        
		//CREATE OPPORTUNITY LINE ITEM
		OpportunityLineItem oppLineItem;
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
		oppLineItem = TestDataFactory.createOpportunityLineItem(1, oppList[0], productList[0], pbEntryList[0]);
        oppLineItemList.add(oppLineItem);
        Database.insert(oppLineItemList);
        
    }
    
    public static testMethod void testGetOpportunityLineItem() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse responseObject = new LightningResponse();
        Opportunity oppRecord = [SELECT Id, Name, RecordTypeId FROM Opportunity];
        
        System.runAs(testUser) {
            Test.startTest();
            responseObject = OpportunityOptionsController.getOpportunityLineItem(oppRecord.Id);
            Test.stopTest();   
        }
        System.assertEquals('SUCCESS', responseObject.status);
    }
    
    public static testMethod void testUserHasEditAccess() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Opportunity oppRecord = [SELECT Id, Name, RecordTypeId FROM Opportunity];
        
        
        System.runAs(testUser) {
        Test.startTest();
        OpportunityOptionsController.UserHasEditAccess(oppRecord.Id);
        Test.stopTest();
        }
    }
    
    public static testMethod void testInsertOptions() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        Opportunity oppRecord = [SELECT Id, Name, RecordTypeId FROM Opportunity];
        Pricebook2 pricebook = [SELECT Id, Name FROM Pricebook2];
        PricebookEntry pbEntry = [SELECT Id, Name FROM PriceBookEntry WHERE NAME='Options'];
        Product2 productRecord = [SELECT Id, Name FROM Product2 WHERE Name='Options'];
        String description = 'Line Description';
        Integer optionTerms = 4;
        
        System.runAs(testUser) {
            Test.startTest();
            OpportunityOptionsController.insertOptions(description, pbEntry.Id, productRecord.Id, optionTerms, oppRecord.Id);
            Test.stopTest();
        }
    }
    
    public static testMethod void testRemoveOpportunity() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Opportunity oppRecord = [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Name='Test Name0' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            OpportunityOptionsController.removeOpportunity(oppRecord.Id);
            Test.stopTest();        
        }
    }
}