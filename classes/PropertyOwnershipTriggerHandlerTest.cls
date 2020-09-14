/*
* @author:         Kyle Tan
* @description:      Test class for PropertyOwnershipTriggerHandler
*/
@isTest
private class PropertyOwnershipTriggerHandlerTest {
    
    @testSetup private static void testSetup(){
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, priceBookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c];
        
        //CREATE ACCOUNT
        accountList = TestDataFactory.createAccountBulk(10, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
    }
    
    public static testMethod void uponInsertTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<PropertyOwnership__c> propertyOwnershipList = new List<PropertyOwnership__c>();
        
        //CREATE PROPERTY OWNERSHIP
        for(Integer i = 0; i < 10; i++) {
            propertyOwnershipList.addAll(TestDataFactory.createPropertyOwnership(1, propertyList[i].Id, accountList[i].Id));
        }
        
        system.runAs(testUser) {
            Test.startTest();
            
            database.insert(propertyOwnershipList, false);
            
            Test.stopTest();
        }
        
        propertyOwnershipList = [SELECT Id FROM PropertyOwnership__c WHERE Property__r.Tech_ConcatenatedHoldingCompanyName__c != null AND Property__r.Tech_ConcatenatedAccountACN__c != null];
        system.assertEquals(10, propertyOwnershipList.size());
    }
    
    public static testMethod void uponDeletionTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c LIMIT 2]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account LIMIT 2]);
        List<PropertyOwnership__c> propertyOwnershipList = new List<PropertyOwnership__c>();
        
        //CREATE PROPERTY OWNERSHIP
        propertyOwnershipList.addAll(TestDataFactory.createPropertyOwnership(10, propertyList[0].Id, accountList[0].Id));
        database.insert(propertyOwnershipList, false);
        propertyOwnershipList = [SELECT Id FROM PropertyOwnership__c];
        TriggerHandler.clearBypass('PropertyOwnershipTriggerHandler');
        system.runAs(testUser) {
            test.startTest();
            database.delete(propertyOwnershipList);
            
            test.stopTest();
        }
        
        propertyOwnershipList = [SELECT Id FROM PropertyOwnership__c];
        system.assertEquals(0, propertyOwnershipList.size());
    }

}