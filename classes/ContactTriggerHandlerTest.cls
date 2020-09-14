/*
* @author:          Kyle Tan
* @description:     Test Class for ContactTriggerHandler
*/
@isTest
public class ContactTriggerHandlerTest {
    @TestSetup private static void testSetup(){
        
        //Create Pricebook
        Pricebook2 pricebookRec = new Pricebook2();
        pricebookRec = TestDataFactory.createPricebook();
        pricebookRec.CurrencyIsoCode = 'AUD';
        database.insert(pricebookRec);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(10, pricebookRec);
        database.insert(propertyList);
        
        //Create Parent Account
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> parentAccList = new List<Account>();
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        
        //Create Account
        Account account = new Account();
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        account.TenantNo__c = '1234';
        database.insert(account);
        
        //Create Contact
        Contact conRec = new Contact();
        conRec = TestDataFactory.createContact('Test Contact', account);
        database.insert(conRec);
    }
    
    private static testMethod void testContactUpdate() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Contact> contactList = [SELECT Id, FirstName, LastName, Comments__c, Phone FROM Contact];
        for(Contact con : contactList){
            con.Phone = '123456778';
            con.FirstName = 'Kobe';
            con.LastName = 'Bryant';
            con.Comments__c = 'Lakers Champ';
        }
        system.runAs(testUser) {
            Test.startTest();
            database.update(contactList);
            TriggerHandler.clearAllBypasses();
            database.delete(contactList);
            Test.stopTest();
        }
    }
}