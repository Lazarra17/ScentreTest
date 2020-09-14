@isTest
public class UnlockAllLockedOpporutnityTest {
    @TestSetup private static void testSetup(){
               
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
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
        oppList[0].DevelopmentType__c = '';
        database.insert(oppList);
        Approval.Lock(oppList[0].Id);
        
    }
    public static testMethod void callBatchUnlockAllLockedOpporutnity(){
       
        Test.startTest();
        UnlockAllLockedOpporutnity batchOppUnlock = new UnlockAllLockedOpporutnity();
        Database.executeBatch(batchOppUnlock, 200);
        Test.stopTest();
    }
}