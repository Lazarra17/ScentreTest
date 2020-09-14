/*
*       author: Clark Marie Garde
*       created date: October 15, 2018
*       description: Test class for OpportunityChatterNotificationInvocable
* 
*/
@isTest
public class OpportunityChatterNotifInvocableTest {
    @TestSetup private static void testSetup() {
        List<Opportunity> oppList = new List<Opportunity>();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //CREATE OPPORTUNITY
        oppList = TestDataFactory.createOpportunity(10, account);
        Database.insert(oppList);
        oppList = [SELECT Id, AccountId, Property__c, Space__c FROM Opportunity limit 1];
    }
    
    @isTest
    private static void testGetchatternotificationdata() {
        List<Opportunity> opportunityList = [SELECT ID,Name,Property__c,OwnerId,ApprovalStatus__c FROM Opportunity LIMIT 1];
        List<ChatterPostUtil.chatterNotificationWrapper> chatterwrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        
        Test.startTest();  
        	OpportunityChatterNotificationInvocable.getchatternotificationdata(opportunityList);
        	chatterwrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
        Test.stopTest();
        
        system.assertEquals(true, chatterwrapperList <> null);
    }
     @isTest
    private static void testGetchatternotificationdataforTrigger() {
        List<Opportunity> opportunityList = [SELECT ID,Name,Property__c,OwnerId,ApprovalStatus__c FROM Opportunity LIMIT 1];
        List<ChatterPostUtil.chatterNotificationWrapper> chatterwrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        
        Test.startTest();  
        	OpportunityChatterNotificationInvocable.getchatternotificationdataforTrigger(opportunityList);
        	chatterwrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
        Test.stopTest();
        
        system.assertEquals(true, chatterwrapperList <> null);
    }
}