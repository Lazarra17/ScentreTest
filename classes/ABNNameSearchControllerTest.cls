/*
* @author:              Sidney Garcia
* @description:         Test class for ABNNameSearchController
*/

@isTest
public class ABNNameSearchControllerTest {
    public static testMethod void getNZBNNameList() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseNZBNTest());
            Test.startTest();
            wrapper = ABNNameSearchController.getNZBNNameList(CONSTANTS.TEST, CONSTANTS.TEST);
            
            Test.stopTest();
        }
        
        
        System.assertEquals(CONSTANTS.SUCCESS, wrapper.status);
        System.assertEquals(true, wrapper.returnValue <> null);
       
    }
    
    public static testMethod void getNZBNNameListNull() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        LightningResponse wrapper = new LightningResponse();
		String tradingName = NULL;
        String lesseeName = NULL;
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseNZBNTest());
            Test.startTest();
            wrapper = ABNNameSearchController.getNZBNNameList(tradingName, lesseeName);
            
            Test.stopTest();
        }
        
        
        System.assertEquals(CONSTANTS.FAILED, wrapper.status);
       
    }    
    
    public static testMethod void getABNNameList() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseABNTest());
            Test.startTest();
            wrapper = ABNNameSearchController.getABNNameList(CONSTANTS.TEST, CONSTANTS.TEST);
            
            Test.stopTest();
        }
        
        System.assertEquals(CONSTANTS.SUCCESS, wrapper.status);
        System.assertEquals(true, wrapper.returnValue <> null);
       
    }
    
    public static testMethod void isaccountvalidtoupdatedetails() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Account accRec = TestDataFactory.createAccount(1);
        List<Account> accList = new List<Account>();
        accList.add(accRec);
        Database.insert(accList);
        String recordId = accRec.Id;
    	
        System.runAs(testUser) {
            Test.startTest();            
            ABNNameSearchController.isaccountvalidtoupdatedetails(recordId);
			Test.stopTest();            
        }
    }
}