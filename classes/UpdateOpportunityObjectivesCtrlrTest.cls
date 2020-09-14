/**
  *		Date: 4/10/2019
  *		Description: Test class for UpdateOpportunityObjectivesController
  */
@isTest
public class UpdateOpportunityObjectivesCtrlrTest {
    @testSetup private static void testSetup() {
        // Create Account
        Account account = TestDataFactory.createAccount(1);
        Database.insert(account);
        
        // Create Opportunity
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(1, account);
        Database.insert(opportunityList);
    }
    
    @isTest private static void TestLockOpportunity() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Test', 'User', profileRec.Id);
        
        List<Opportunity> oppList = [SELECT Id, Name, BackgroundIssue__c, Financials__c, OptionsRecommendations__c FROM Opportunity LIMIT 1];
        LightningResponse lexResponseLock = new LightningResponse();
        
        System.runAs(testUser) {
            Test.startTest();
			lexResponseLock = UpdateOpportunityObjectivesController.lockOpportunity(oppList[0].Id);
            System.debug('[TC]: LightningResponse Lock: ' + lexResponseLock);
            Test.stopTest();
        }
        
        // Assertions
		Map<String, Object> rv = (Map<String, Object>) JSON.deserializeUntyped(lexResponseLock.returnValue);
        // System.debug('RETURN VALUE: ' + rv.get('lockedOpp'));
        System.assertEquals(true, rv.get('lockedOpp'));
    }
    
    @isTest private static void TestUnlockOpportunity() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Test', 'User', profileRec.Id);
        
        List<Opportunity> oppList = [SELECT Id, Name, BackgroundIssue__c, Financials__c, OptionsRecommendations__c FROM Opportunity LIMIT 1];
        LightningResponse lexResponseLock = new LightningResponse();
        LightningResponse lexResponseUnlock = new LightningResponse();
        
        System.runAs(testUser) {
            Test.startTest();
            lexResponseLock = UpdateOpportunityObjectivesController.lockOpportunity(oppList[0].Id);
            lexResponseUnlock = UpdateOpportunityObjectivesController.unLockOpportunity(oppList[0].Id);
            Test.stopTest();
        }
        
        // Assertions
        Map<String, Object> rvLock = (Map<String, Object>) JSON.deserializeUntyped(lexResponseLock.returnValue);
        Map<String, Object> rvUnlock = (Map<String, Object>) JSON.deserializeUntyped(lexResponseUnlock.returnValue);
        System.assertEquals(true, rvLock.get('lockedOpp'));
        System.assertEquals(true, rvUnlock.get('lockedOpp'));
    }
}