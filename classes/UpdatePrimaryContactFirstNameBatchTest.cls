@isTest
public class UpdatePrimaryContactFirstNameBatchTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        try {
            database.insert(oppList);
        } catch (Exception e) {
            system.debug('Exc: '+e.getLineNumber());
            system.debug('Exc: '+e.getMessage());
        }
        
        //Create Account
        Account acc1 = new Account();
        acc1 = TestDataFactory.createAccount(1);
        database.insert(acc1);
        
        //Create Contact
        Contact Con1 = new Contact();
        Con1 = TestDataFactory.createContact('testN',acc1);
        Insert Con1;
        
        //update Opty with primary contact
        oppList[0].PrimaryContact__c = Con1.Id;
        database.update(oppList);
        
    }
    
    private static testMethod void callUpdatePrimaryContactFirstName(){
        
        List<Opportunity> oppList1 = [SELECT Id, StageName, Account.Type, Name, PrimaryContact__c, PrimaryContact__r.FirstName, Tech_PrimaryContactFirstName__c FROM Opportunity];
        
        Test.startTest();
        UpdatePrimaryContactFirstNameBatch UpdatePriCon = new UpdatePrimaryContactFirstNameBatch();
        Database.executeBatch(UpdatePriCon, 5);
        Test.stopTest();
    }
    
}