/*
* @author:              Sidney Garcia
* @description:         Test class for LightningResponse
*/
@isTest
public class LightningResponseTest {
	@TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(1);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1, pricebookList[0]);
        database.insert(propertyList);
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //CREATE OPPORTUNITY
        account = [SELECT Id, Property__c FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(1, account);
        database.insert(opportunityList);
    }
    //Testing the lightning response using OpportunityUnlockUpdateController
    public static testMethod void unlockOpportunityRecord() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper oppWrapper = new OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper();
        oppList = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        String oppId = oppList[0].Id;
        String stageName = CONSTANTS.PROPOSE_ACCEPT;
        
        System.runAs(testUser) {
            
            Test.startTest();
            wrapper = OpportunityUnlockUpdateController.unlockOpportunityRec(oppId, stageName);
            
            Test.stopTest();
        }
        //Assertion
        System.assertEquals(true, wrapper.status == Constants.SUCCESS);
    }
}