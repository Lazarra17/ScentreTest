/*
* @author:          Sidney Garcia
* @description:     Test Class for ClauseSummaryController
*/

@isTest
public class ClauseSummaryControllerTest {
    @testSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> clauseLibTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.CLAUSE_LIBRARY_API);
        Map<String, Schema.RecordTypeInfo> oppClauseTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        propertyList[0].Pricebook__c = Test.getStandardPricebookId();
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
        oppList = TestDataFactory.createOpportunity(3, accountList[0], propertyList[0], spaceList[0]);
        oppList[0].TechByPassOnClone__c = true;
        database.insert(oppList);
        
        //Create Clause Library
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        clauseLibList = TestDataFactory.createClauseLibrary(2);
        clauseLibList[1].Type__c = 'RCA';
        clauseLibList[1].SubType__c = 'Rent Review';
        clauseLibList[1].RiskApplies__c = true;
        database.insert(clauseLibList);
        
        //Create Opportunity Clause
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        oppClauseList = TestDataFactory.createOpportunityClause(2, oppList[0], clauseLibList[0]);
        oppClauseList[0].Type__c = 'RCA';
        oppClauseList[0].SubType__c = 'Rent Review';
        database.insert(oppClauseList);
    }
    public static testMethod void getSelectedClausesTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        LightningResponse res = new LightningResponse();
        Opportunity opportunityRecord = [select id from Opportunity LIMIT 1];
        ClauseSummaryController.clauseDetailsWrapper clauseWrapper = new ClauseSummaryController.clauseDetailsWrapper();
        System.runAs(testUser) {
            Test.startTest();
            res = ClauseSummaryController.getSelectedClauses(opportunityRecord.Id);
            Test.stopTest();
        }
        clauseWrapper = (ClauseSummaryController.clauseDetailsWrapper) JSON.deserialize(
			res.returnValue, 
			ClauseSummaryController.clauseDetailsWrapper.class
		);
        System.assertEquals(2, clauseWrapper.opportunityClauseList.size());
    }    
}