/**
 * @author:				Kyle Tan
 * @desc:				test class for AccountTriggerHandler
 **/
@isTest
private class AccountTriggerHandlerTest{
    
    @testSetup
    static void testSetup(){
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    static void copyParentAddressTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        accountList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.GROUP_LEVEL).getRecordTypeId());
        tempAccountList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        accountList[0].TechConvertedLeadId__c = '1234';
        system.runAs(testUser) {
            test.startTest();
            database.insert(accountList);
            TriggerHandler.clearAllBypasses();
            tempAccountList[0].ParentId = accountList[0].Id;
            tempAccountList[0].Category__c = null;
            tempAccountList[0].BillingState = null;
            tempAccountList[0].BillingCountry = null;
            tempAccountList[0].ShippingState = null;
            tempAccountList[0].ShippingCountry = null;
            database.insert(tempAccountList);
            test.stopTest();
        }
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    static void updateAccountTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        accountList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.GROUP_LEVEL).getRecordTypeId());
        system.runAs(testUser) {
            test.startTest();
            database.insert(accountList);
            TriggerHandler.clearAllBypasses();
            accountList[0].RecordTypeId = accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId();
            accountList[0].TradingName__c = 'Test New Trading Name';
            database.update(accountList[0]);
            TriggerHandler.clearAllBypasses();
            database.delete(accountList[0]);
            test.stopTest();
        }
    }
        /**
     * @author : 		Janus Gargoles
	**/
    @isTest
    static void accountEventPublishUpdateTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name=:CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('James','Doe',profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Property__c> propertyList = [SELECT Id FROM Property__c LIMIT 1];
        accountList = TestDataFactory.createAccountBulk(2, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.GROUP_LEVEL).getRecordTypeId());
        system.assertEquals(accountList.size(),2);
        system.runAs(testUser){
            test.startTest();
            accountList[0].TenantNo__c = '123456';
            database.insert(accountList);
            TriggerHandler.clearAllBypasses();
            accountList[1].ParentId = accountList[0].Id;
            database.update(accountList);
            TriggerHandler.clearAllBypasses();
            test.stopTest();
        }
    }
    
    /**
     * @author: 		Janus Gargoles
	**/
    @isTest
    static void retailCentreMgtAccountUpdateTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name=:Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John','Lavender',profileRec.Id);
        User testUser2 = [SELECT Id FROM User WHERE Profile.Name=:Constants.SCGRETAILCENTREMGT AND IsActive = true LIMIT 1];
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Property__c> propertyList = [SELECT Id FROM Property__c LIMIT 1];
        accountList = TestDataFactory.createAccountBulk(1,propertyList[0].Id,accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        system.runAs(testUser){
            test.startTest();
            accountList[0].OwnerId = testUser2.Id;
            database.insert(accountList);
            TriggerHandler.clearAllBypasses();
            system.runAs(testUser2){
                accountList[0].BillingCountry = 'Australia';
                accountList[0].BillingCity = 'Sydney';
                accountList[0].BillingPostalCode = '2000';
                database.update(accountList);
                TriggerHandler.clearAllBypasses();
            }
            test.stopTest();
        }
    }
}