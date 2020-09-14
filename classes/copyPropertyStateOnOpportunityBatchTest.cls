@isTest
public class copyPropertyStateOnOpportunityBatchTest {
    
    @TestSetup private static void testSetup(){
               
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        propertyList[0].PropertyState__c = 'NSW';
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
        database.insert(oppList);
        
    }
    
    public static testmethod void batchTest(){
        
        Test.startTest();
        copyPropertyStateOnOpportunityBatch propState = new copyPropertyStateOnOpportunityBatch();
        Database.executeBatch(propState); 
        Test.stopTest();
        
        Opportunity opp1 = [SELECT Id, Tech_PropertyState__c FROM Opportunity WHERE Tech_PropertyState__c = 'NSW' LIMIT 1];
        System.assertEquals('NSW', opp1.Tech_PropertyState__c);
    }

}