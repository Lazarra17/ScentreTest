/**
 * @author:			Kyle Tan
 * @desc:			Test class for PropertyMapsTriggerHandler
 **/
@isTest
private class PropertyMapsTriggerHandlerTest {

    @testSetup
    private static void testSetup() {
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].MainFloor__c = '1';
        database.insert(spaceList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void insertPropertyMaps() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<PropertyMaps__c> propertyMapsList = new List<PropertyMaps__c>();
        propertyMapsList.addAll(TestDataFactory.createPropertyMaps(1, propertyList[0].Id));
        system.runAs(testUser) {
            test.startTest();
            database.insert(propertyMapsList);
            test.stopTest();
        }
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void updatePropertyMaps() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<PropertyMaps__c> propertyMapsList = new List<PropertyMaps__c>();
        propertyMapsList.addAll(TestDataFactory.createPropertyMaps(1, propertyList[0].Id));
        database.insert(propertyMapsList);
        propertyMapsList = [SELECT Id, URL__c FROM PropertyMaps__c];
        propertyMapsList[0].URL__c = 'test@email.com.svg';
        propertyMapsList[0].Floor__c = '1';
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(propertyMapsList);
            TriggerHandler.clearAllBypasses();
            database.delete(propertyMapsList[0]);
            test.stopTest();
        }
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void deletePropertyMaps() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<PropertyMaps__c> propertyMapsList = new List<PropertyMaps__c>();
        propertyMapsList.addAll(TestDataFactory.createPropertyMaps(1, propertyList[0].Id));
        database.insert(propertyMapsList);
        propertyMapsList = [SELECT Id FROM PropertyMaps__c];
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.delete(propertyMapsList[0]);
            test.stopTest();
        }
    }
}