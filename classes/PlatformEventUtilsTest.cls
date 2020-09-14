/**
 * @author:			Kyle Tan
 * @description:	Test Class for PlatformEventUtils
 **/
@isTest
private class PlatformEventUtilsTest {

    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Opportunity
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        accountList = TestDataFactory.createAccountBulk(20, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.GROUP_LEVEL).getRecordTypeId());
        database.insert(accountList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void getDescribeResult() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<String> apiName = new List<String>();
        String stringToAssert;
        
        system.runAs(testUser) {
            test.startTest();
            stringToAssert = PlatformEventUtils.getRecordJsonPayload(accountList[0].Id, apiName);
            test.stopTest();
        }
    }
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void testGetRecordsJsonPayload() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Set<String>> stringMap = PlatformEventUtils.getfieldlistforintegration(Constants.ACCOUNT);        
        List<String> stringList = new List<String>();
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Id> IdList = new List<Id>();
        List<String> apiName = new List<String>(stringMap.get(Constants.ACCOUNT));
        for(Account accRec : accountList) {
            IdList.add(accRec.Id);
        }
        
        system.runAs(testUser) {
            test.startTest();
            stringList = PlatformEventUtils.getRecordsJsonPayload(IdList,apiName);
            test.stopTest();
        }
    }
    
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void testGetRecordsJsonPayloadMap() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, String> stringMap = new Map<Id, String>();
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Id> IdList = new List<Id>();
        List<String> apiName = new List<String>();
        
        for(Account accRec : accountList) {
            IdList.add(accRec.Id);
        }
        
        apiName.add('Name');
        apiName.add('Phone');
        
        system.runAs(testUser) {
            test.startTest();
            stringMap = PlatformEventUtils.getRecordsJsonPayloadMap(IdList, apiName);
            test.stopTest();
        }
    }
    
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void testGetfieldlistforintegration() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Set<String>> stringMap = new Map<String, Set<String>>();
        
        system.runAs(testUser) {
            test.startTest();
            stringMap = PlatformEventUtils.getfieldlistforintegration(Constants.ACCOUNT);
            test.stopTest();
        }
        
    }
    
    /**
     * @author:			Kyle Tan
     **/
    private static testMethod void testConstructApiNames() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
		List<String> stringList = new List<String>();        
        Datetime tempDate = date.today();
        system.runAs(testUser) {
            test.startTest();
            stringList = PlatformEventUtils.constructApiNames('Test,Name,Data');
            tempDate = PlatformEventUtils.getUTCDateTime(tempDate);
            test.stopTest();
        }
    }
}