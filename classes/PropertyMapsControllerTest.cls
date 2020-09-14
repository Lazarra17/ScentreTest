/*
* @author:              Miguel Paguio
* @description:         Test class for PropertyMapsController
*/
@isTest
public class PropertyMapsControllerTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<PropertyMaps__c> propertyMapsList = new List<PropertyMaps__c>();
        List<Space__c> spaceList = new List<Space__c>();
        List<User> userList = new List<User>();
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //CREATE PROPERTYMAPS
        propertyMapsList = TestDataFactory.createPropertyMaps(1, propertyList.get(0).Id);
        Database.insert(propertyMapsList);
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        database.insert(accountList);
        
        //CREATE SPACE
        /**for(Integer counter = 0; counter < 10; counter++){
spaceList = TestDataFactory.createSpace(5, propertyList.get(counter));   
}**/
        spaceList = TestDataFactory.createSpace(1, propertyList.get(0));
        Database.insert(spaceList);
        
        for(Integer i = 0; i < 10; i++){
            User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME + ' ' + i, CONSTANTS.TEST_LNAME + ' ' + i, profileRec.Id);
            userList.add(testUser);
        }
        Database.insert(userList); 
    }
    
    public static testMethod void getPropertyMapsByPropertyTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        List<Property__c> propRec = [SELECT Id FROM Property__c];
        List<PropertyMaps__c> propMaps = [SELECT Id FROM PropertyMaps__c LIMIT 1];
        System.runAs(testUser){
            
            Test.startTest();          
            propMaps = PropertyMapsController.getPropertyMapsByProperty(propRec.get(0).Id);            
            Test.stopTest();   
        }
        
        System.assertEquals(true, propMaps <> null);
    }
    
    public static testMethod void getImageSpaceIdAndLevelTest() {
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        List<Property__c> propRec = [SELECT Id FROM Property__c];
        List<PropertyMaps__c> propMaps = [SELECT Id FROM PropertyMaps__c LIMIT 1];
        List<Space__c> spaceRec = [SELECT Id FROM Space__c];
        String testProp = '';
        
        System.runAs(testUser){
            Test.startTest();          
            testProp = PropertyMapsController.getImageSpaceIdAndLevel('0', spaceRec.get(0).Id);            
            Test.stopTest(); 
        }
        
        
        System.assertEquals(true, testProp <> '');
    }
    
    public static testMethod void getPropertyMapBySpaceTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        List<Property__c> propRec = [SELECT Id FROM Property__c];
        List<PropertyMaps__c> propMaps = [SELECT Id FROM PropertyMaps__c LIMIT 1];
        List<Space__c> spaceRec = [SELECT Id FROM Space__c];
        String testProp = '';
        System.runAs(testUser){
            Test.startTest();          
            testProp = PropertyMapsController.getPropertyMapBySpace(spaceRec.get(0).Id);            
            Test.stopTest();   
        }
        
        System.assertEquals(true, testProp <> null);
        
    }
    
    
    public static testMethod void getImageByPropertyAndLevelTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        List<Property__c> propRec = [SELECT Id FROM Property__c];
        List<PropertyMaps__c> propMaps = [SELECT Id FROM PropertyMaps__c LIMIT 1];
        String testProp = '';
        
        System.runAs(testUser){
            Test.startTest();          
            testProp = PropertyMapsController.getImageByPropertyAndLevel('0', propRec.get(0).Id);            
            Test.stopTest();   
        }
        
        System.assertEquals(true, testProp <> '');
    }
    
    public static testMethod void getSpacesAndImageByPropertyTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        List<Property__c> propRec = [SELECT Id FROM Property__c];
        List<PropertyMaps__c> propMaps = [SELECT Id FROM PropertyMaps__c LIMIT 1];
        String testProp = '';
        System.runAs(testUser){
            
            Test.startTest();          
            testProp = PropertyMapsController.getSpacesAndImageByProperty('0', propRec.get(0).Id);            
            Test.stopTest();   
        }
        System.debug('check');
        System.assertEquals(true, testProp <> '');
    }
    
   
}