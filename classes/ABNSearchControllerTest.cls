/*
* @author:              Sidney Garcia
* @description:         Test class for ABNSearchController
*/

@isTest
public class ABNSearchControllerTest {
    @TestSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<User> testUserList = new List<User>();
        List<Account> parentAccList = new List<Account>();
        
        Account account = new Account();
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        
        Database.insert(testUserList);    
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, null, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        for(Integer i = 0; i < 10; i++){
            account = TestDataFactory.createAccountwithParent(i, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        	accountList.add(account);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Name FROM Account LIMIT 100];
        
    }
    
	public static testMethod void getNZBNDetails() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseNZBNTest());
            Test.startTest();
            wrapper = ABNSearchController.getNZBNDetails('Test');
            
            Test.stopTest();
        }
        
        
        System.assertEquals(CONSTANTS.SUCCESS, wrapper.status);
        System.assertEquals(true, wrapper.returnValue <> null);
       
    }
    
    public static testMethod void getABNDetails() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseABNTest());
            Test.startTest();
            wrapper = ABNSearchController.getABNDetails(CONSTANTS.TEST, CONSTANTS.TEST);
            
            Test.stopTest();
        }
        
        System.assertEquals(CONSTANTS.SUCCESS, wrapper.status);
        System.assertEquals(true, wrapper.returnValue <> null);
       
    }
    
    public static testMethod void isaccountvalidtoupdatedetails() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        Account accountRecord = [SELECT Id FROM Account WHERE RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() LIMIT 1];
        
        String accountRecordId = accountRecord.Id;
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseABNTest());
            Test.startTest();
            wrapper = ABNSearchController.isaccountvalidtoupdatedetails(accountRecordId);
            
            Test.stopTest();
        }
        
        System.assertEquals(CONSTANTS.SUCCESS, wrapper.status);
        System.assertEquals(true, wrapper.returnValue <> null);
       
    }

}