/**
  *		Test Class for ContractTriggerHandler
  *		Created by Prince; 3/20/2019
  */
@isTest
public class ContractTriggerHandlerTest {
    @testSetup private static void testSetup() {
        // Create Test User
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id);
        Database.insert(testUser);
        
        // Create Account
        Account accountRecord = new Account();
        accountRecord = TestDataFactory.createAccount(0);
        Database.insert(accountRecord);
        
        // Create Contract
        List<Contract__c> contractList = new List<Contract__c>();
        // contractList = TestDataFactory.createContract(1, accountRecord, propertyRecord, opportunityList[0]);
        contractList = TestDataFactory.createContract(1, accountRecord);
        contractList[0].LeaseStatus__c = 'F';
        
        Database.insert(contractList);
    }

    /**
	  *		Check 'Before Update' logic
	  */
    @isTest public static void updateTechStatus() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id);
        
        Contract__c contractRecord = [SELECT Id, LeaseStatus__c, TechStatusChanged__c FROM Contract__c LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
          	
            contractRecord.LeaseStatus__c = 'D';
            database.update(contractRecord);
                
            Test.stopTest();
        }
        
    }
}