/*
 *	@description: Test class for ChatterForRiskApprovalGrantedOpp
 *	@startdate: 4/5/2019
 *
 */
@isTest
public class ChatterForRiskApprovalGrantedOppTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Space__c> spaceList = new List<Space__c>();
        List<Contract__c> contrList = new List<Contract__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        // CREATE PRICEBOOK
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        // CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        for(Property__c property : propertyList){
            property.PriceBook__c = priceBookRec.Id;
        }
        Database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 5];
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        
        // CREATE SPACE
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].type__c = '1';
        spaceList[0].BillingCategory__c = 'NA';
        database.insert(spaceList);
        
        //CREATE CONTRACT
        spaceList = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceList[0].id;
        database.insert(contrList);
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceList);
        database.insert(opportunityList);
    }
    
    @isTest private static void testChatterPostToRetailAdmin() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Id> opptyIds = new List<Id>();
        List<Opportunity> opportunityList = [SELECT Id, Name FROM Opportunity LIMIT 1];
        for (Opportunity opp : opportunityList) {
            opptyIds.add(opp.Id);
        }
        
        System.runAs(testUser) {
            Test.startTest();
            ChatterForRiskApprovalGrantedOpp.chatterPostToRetailAdmin(opptyIds);
            Test.stopTest();
        }
        
        // Assertions        
        List<FeedItem> chatterFeedList = [SELECT Id, ParentId, CreatedById FROM FeedItem LIMIT 10];
        for (FeedItem ci : chatterFeedList) {
            System.assertNotEquals(null, ci.Body);
            System.assertEquals(testUser.Id, ci.CreatedById);
        }
    }
}