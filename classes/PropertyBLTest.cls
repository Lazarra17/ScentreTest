/*
* Author:               Clark Garde
* Created Date:         5/2/2018
* Last Modified By:     Clark Garde
* Description:          Test class for PropertyBL
*/
@isTest
public class PropertyBLTest {
    
    @TestSetup static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        Integer propertySize = 25;
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //CREATE PROPERTY
        propertyList.addAll(TestDataFactory.createProperty(propertySize, priceBookList[0]));
        
        Database.insert(propertyList);
        Integer accountCounter = 0;
        
        for(Property__c propertyVar : propertyList) {
            accountList.add(TestDataFactory.createAccount(accountCounter, propertyVar.Id, accountRecordTypeMapByName.get(CONSTANTS.THIRD_PARTY).getRecordTypeId()));
            accountCounter++;
            accountList.add(TestDataFactory.createAccount(accountCounter, propertyVar.Id, accountRecordTypeMapByName.get(CONSTANTS.THIRD_PARTY).getRecordTypeId()));
            accountCounter++;
        }
        
        Database.insert(accountList);
    }
    
    static testMethod void renameAccountTest() {
        //INSTANTIATION
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accountRecord = new Account();
        List<Account> assertAccountList = new List<Account>();
        List<Account> accountList = new List<Account>([SELECT Id, TradingName__c, Property__c FROM Account WHERE Property__r.PropertyShortName__c != null]);
        Set<Id> propertyId = new Set<Id>();
        for(Account accounVar : accountList) {
            propertyId.add(accounVar.Property__c);
        }
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, PropertyShortName__c FROM Property__c Where Id in: propertyId]);
        List<Property__c> propertiesToUpdate = new List<Property__c>();
        
        //RUN TEST
        
        Test.startTest();
        
        for(Property__c prop : propertyList) {
            prop.PropertyShortName__c = prop.PropertyShortName__c + '(new)';
            propertiesToUpdate.add(prop);
        }
        
        Database.update(propertiesToUpdate);
        Test.stopTest();
        
        //ASSERTION
        for(Account acc : assertAccountList) {
            System.assertEquals('Test Account - ABC' + '(new)', acc.Name);
        }
    }
}