/*
* @author: 				Kyle Tan
* @description:			Test class for PropertyOwnershipBL
*/
@isTest
private class PropertyOwnershipBLTest {
    
    @testSetup private static void testSetup(){
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(2, priceBookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c];
        
        //CREATE ACCOUNT
        accountList = TestDataFactory.createAccountBulk(2, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
    }
    
    public static testMethod void buildPropertyToUpdateMapTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c LIMIT 2]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account LIMIT 2]);
        List<PropertyOwnership__c> propertyOwnershipList = new List<PropertyOwnership__c>();
        Map<Id, Property__c> propertyToUpdateMap = new Map<Id, Property__c>();
        Set<Id> propertyIdSet = new Set<Id>();
        
        for(Property__c propertyRec : propertyList) {
            propertyIdSet.add(propertyRec.Id);
        }
        
        //CREATE PROPERTY OWNERSHIP
        propertyOwnershipList.addAll(TestDataFactory.createPropertyOwnership(10, propertyList[0].Id, accountList[0].Id));
        
        system.runAs(testUser) {
            Test.startTest();
            
            database.insert(propertyOwnershipList, false);
            propertyToUpdateMap = PropertyOwnershipBL.buildPropertyToUpdateMap(propertyIdSet);
            
            Test.stopTest();
        }
        
        system.assert(propertyToUpdateMap.size() == 2);
    }

}