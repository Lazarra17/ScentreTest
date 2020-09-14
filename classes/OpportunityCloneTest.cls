@isTest
public class OpportunityCloneTest {
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
        accountList = [SELECT Id, Name, Property__c FROM Account LIMIT 5];
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
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, testProperty);
        spaceLst[0].type__c = '1';
        spaceLst[0].BillingCategory__c = 'NA';
        database.insert(spaceLst);
        spaceLst = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceLst[0].id;
        contrList[0].LeaseStartDate__c = date.today();
        contrList[0].LeaseEndDate__c = date.today().addDays(10);
        contrList[0].CurrentRent__c = 1000;
        database.insert(contrList);
        
        //CREATE OpportunityLineItem
        for(Integer counter = 0; counter < 5; counter++) {
            if (counter < 5 ) {
                opportunityLineItemRecord = TestDataFactory.createOpportunityLineItem(counter, opportunityList[counter], productBaseRentGross, pricebookEntryBaseRentGross );
            }
            opportunityLineItemList.add(opportunityLineItemRecord);
            
        }
        insert opportunityLineItemList;
        
        OpportunityClause__c oppoClause = TestDataFactory.createOpportunityClause(1, opportunityList[0])[0];
        insert oppoClause;
        
        contactRecord = [SELECT Id FROM Contact LIMIT 1];
        OpportunityContactRole oppContactRole = TestDataFactory.createOpportunityContactRole(opportunityList[0], contactRecord, CONSTANTS.TEAM_ROLE_CENTREMANAGER);
        insert oppContactRole;
    }
    
    public static testMethod void testOppoClone(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        List<Contract__c> contractList = [SELECT Id FROM Contract__c LIMIT 1];
        Set<String> oppIdSet = new Set<String>();
        for(Opportunity opp : oppList){
            oppIdSet.add(opp.Id); 
        }
        List<List<String>> inputString = new List<List<String>>();
        String variationType = 'Variation to Lease';
        List<String> inputStringList = new List<String>();
        inputStringList.addAll(oppIdSet);
        for(Integer i = 0; i<oppIdSet.size(); i++){
            inputStringList.add(variationType);
            inputStringList.add(contractList[0].Id);
        }
        inputString.add(inputStringList);
        List<String> newOppoId = new List<String>(); 
        System.debug('Input String ' + inputString);
        System.runAs(testUser) {
            
            Test.startTest();
            newOppoId = OpportunityClone.oppoClone(inputString);
            Test.stopTest();
        }
        System.assertEquals(true, newOppoId <> null);
    }
}