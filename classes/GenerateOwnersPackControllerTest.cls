/**
 * @author		:Kyle Tan
 * @desc		:test class for GenerateOwnersPackController class
 **/
@isTest
private class GenerateOwnersPackControllerTest {

    @testSetup
    private static void testSetup() {
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
        database.insert(oppList);
    }
    
    /**
     * @author			:Kyle Tan
     **/
    @isTest
    private static void getOppTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        GenerateOwnersPackController.Response response = new GenerateOwnersPackController.Response();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = GenerateOwnersPackController.getOpp(oppList[0].Id, null);
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    @isTest
    private static void getOppTestNotNull() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        GenerateOwnersPackController.Response response = new GenerateOwnersPackController.Response();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = GenerateOwnersPackController.getOpp(oppList[0].Id, 'BUTTON');
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
}