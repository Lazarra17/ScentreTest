/*
* @author:              Sidney Garcia
* @description:         Test class for OpportunityUnlockUpdateController
*/
@isTest
public class OpportunityUnlockUpdateControllerTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<contact> contactList = new list<contact>();
        List<case> caseList = new list<case>();
        List<User> userList = new List<User>();
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = new List<Space__c>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        //System.debug('Pricebook rec ' + priceBookRec);
        
        propertyList = TestDataFactory.createProperty(1);
        for(Property__c property : propertyList){
            property.PriceBook__c = priceBookRec.Id;
        }
        Database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 5];
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        database.insert(accountList);
        //System.debug('Account List ' + accountList);
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        
        //CREATE SPACE
        spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        spaceLst[0].BillingCategory__c = 'NA';
        database.insert(spaceLst);
        
        //CREATE CONTRACT
        spaceLst = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
        
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceLst);
        //System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        
    }
    
    //Check if unlocking opportunity is successful
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
        Approval.lock(oppId);
        System.runAs(testUser) {
            
            Test.startTest();
            wrapper = OpportunityUnlockUpdateController.unlockOpportunityRec(oppId, stageName);
            
            Test.stopTest();
        }
        oppWrapper = (OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper) JSON.deserialize(
			wrapper.returnValue, 
			OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper.class
		);
        //Assertion
        //assertEquals(true, oppWrapper.isUnlocked);
    }
    
    public static testMethod void unlockOpportunityRecordCatch() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper oppWrapper = new OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper();
        oppList = [SELECT Id, StageName FROM Opportunity LIMIT 10];
        String oppId = oppList[0].Id;
        String stageName = CONSTANTS.PROPOSE_ACCEPT;
        //delete oppList;
        
        System.runAs(testUser) {
            
            Test.startTest();
            wrapper = OpportunityUnlockUpdateController.unlockOpportunityRec(oppId, stageName);
            
            Test.stopTest();
        }
        oppWrapper = (OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper) JSON.deserialize(
			wrapper.returnValue, 
			OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper.class
		);
    }
    //check if unlocking opportunity is not successful
    public static testMethod void unlockOpportunityRecordElse() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        LightningResponse wrapper = new LightningResponse();
        OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper oppWrapper = new OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper();
        oppList = [SELECT Id FROM Opportunity LIMIT 1];
        
        String oppId = oppList[0].Id;
        String stageName = CONSTANTS.UNDERSTAND_NEGOTIATE;
        System.runAs(testUser) {
            
            Test.startTest();
         	
            wrapper = OpportunityUnlockUpdateController.unlockOpportunityRec(oppId, stageName);
            Test.stopTest();
        }
        oppWrapper = (OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper) JSON.deserialize(
			wrapper.returnValue, 
			OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper.class
		);
        //System.assertEquals(false, oppWrapper.isUnlocked);
    }
    
    
    
    //check if locking opportunity record is successful
 /*  locking no required anymore, that's why below function commented out
  
   public static testMethod void lockOpportunityRecord(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        
        LightningResponse wrapper = new LightningResponse();
        OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper oppWrapper = new OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper();
        
        oppList = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        
        String oppId = oppList[0].Id;
        System.runAs(testUser) {
            
            Test.startTest();
            
			wrapper = OpportunityUnlockUpdateController.lockOpportunity(oppId);
            
            Test.stopTest();
        }
        
		oppWrapper = (OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper) JSON.deserialize(
			wrapper.returnValue, 
			OpportunityUnlockUpdateController.OpportunityStageAndLockStatusWrapper.class
		);
        
        System.assertEquals(true, oppWrapper.lockedOpp);
    } */
    
    public static testMethod void getPicklistValues(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Opportunity> oppList = new List<Opportunity>();
        OpportunityUnlockUpdateController.OpportunityPicklistsValuesWrapper oppWrapper = new OpportunityUnlockUpdateController.OpportunityPicklistsValuesWrapper();
        LightningResponse wrapper = new LightningResponse();
        
        System.runAs(testUser) {
            
            Test.startTest();
            
			wrapper = OpportunityUnlockUpdateController.getPicklistValues();
            
            Test.stopTest();
        }
        
        oppWrapper = (OpportunityUnlockUpdateController.OpportunityPicklistsValuesWrapper) JSON.deserialize(
			wrapper.returnValue, 
			OpportunityUnlockUpdateController.OpportunityPicklistsValuesWrapper.class
		);
        System.assertEquals(8, oppWrapper.opportunityStages.size());
        System.assertEquals(5, oppWrapper.reasonPicklist.size());
    }
    
}