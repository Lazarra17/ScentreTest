/**
 * @author:			Kyle Tan
 * @desc:			test class for ManageAcceptanceController class
 **/
@isTest
private class ManageAcceptanceControllerTest {

    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> oppClauseTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
        Map<String, Schema.RecordTypeInfo> clauseLibTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.CLAUSE_LIBRARY_API);
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        List<Property__c> propertyList = new List<Property__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Account> accList = new List<Account>();
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        accList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accList);
        
        //Create Clause Library
        clauseLibList = TestDataFactory.createClauseLibrary(2);
        clauseLibList[1].Type__c = Constants.CLAUSE_TYPE_ACCEPTANCE;
        clauseLibList[1].SubType__c = null;
        clauseLibList[1].RiskApplies__c = false;
        clauseLibList[1].RecordTypeId = clauseLibTypeMapByName.get(Constants.CL_STANDARD_RESPONSES_NAME).getRecordTypeId();
        database.insert(clauseLibList);
        
        //Create Opportunity
        oppList = TestDataFactory.createOpportunity(1, accList[0]);
        database.insert(oppList);
        
        //Create Opportunity Clause
        oppClauseList = TestDataFactory.createOpportunityClause(1, oppList[0], clauseLibList[0]);
        oppClauseList[0].RecordTypeId = oppClauseTypeMapByName.get(Constants.OC_STANDARD_RESPONSE_CLAUSE_NAME).getRecordTypeId();
        oppClauseList[0].Type__c = 'Acceptance';
        database.insert(oppClauseList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void buildOpportunityClauseWrapperTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = ManageAcceptanceController.buildOpportunityClauseWrapper(oppList[0].Id);
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void verifyOpportunityTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Boolean verify = false;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            verify = ManageAcceptanceController.verifyOpportunity(oppList[0].Id);
            test.stopTest();
        }
        system.assertEquals(false, verify);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void getClauseTypePicklistValuesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = ManageAcceptanceController.getClauseTypePicklistValues();
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void getDocLocPicklistValuesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = ManageAcceptanceController.getDocLocPicklistValues();
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void getApplicationStatePicklistValuesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        system.runAs(testUser) {
            test.startTest();
            response = ManageAcceptanceController.getApplicationStatePicklistValues();
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void createOpportunityClauseTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>([SELECT Id FROM ClauseLibrary__c]);
        
        system.runAs(testUser) {
            test.startTest();
            response = ManageAcceptanceController.createOpportunityClause(JSON.serialize(clauseLibList), oppList[0].Id);
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void deleteOpportunityClauseTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningResponse response = new LightningResponse();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>([SELECT Id FROM OpportunityClause__c]);
        system.runAs(testUser) {
            test.startTest();
            response = ManageAcceptanceController.deleteOpportunityClause(oppClauseList[0].Id);
            test.stopTest();
        }
        system.assertEquals('SUCCESS', response.status);
    }
}