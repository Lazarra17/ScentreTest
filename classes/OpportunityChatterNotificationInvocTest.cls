/**
 * @author:				Kyle Tan
 * @desc:				Test Class for OpportunityChatterNotificationInvocable
 **/
@isTest
private class OpportunityChatterNotificationInvocTest {

    @testSetup static void testSetup() {
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
        database.insert(oppList);
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void getchatternotificationdataTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                           ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                           GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                           CorporateLegal__c, COO__c 
                                                           FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            OpportunityChatterNotificationInvocable.getchatternotificationdata(oppList);
            test.stopTest();
        }
    }
}