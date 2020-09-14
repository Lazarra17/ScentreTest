/*
*       author: Clark Marie Garde
*       created date: June 12, 2018
*       description: Test class for ClauseSelectionController
*
*/
@isTest
public class ClauseSelectionControllerTest {
    
    @TestSetup private static void testSetup() {
        
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        ClauseLibrary__c clauseLibRecord = new ClauseLibrary__c();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Space__c> spaceList= new List<Space__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        Space__c spaceRec = new Space__c();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];

        //CREATE SPACE
		spaceList = TestDataFactory.createSpace(10, propertyList[0]);
        database.insert(spaceList);
        spaceRec = [SELECT Id FROM Space__c LIMIT 1];
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(10, account, propertyList[0], spaceRec);
        database.insert(opportunityList);
        
        //CREATE CLAUSE LIBRARY
        clauseLibList = TestDataFactory.createClauseLibrary(10);
        Database.insert(clauseLibList);
        
        //CREATE OPPORTUNITY CLAUSE
        oppClauseList = TestDataFactory.createOpportunityClause(10,  opportunityList[0], clauseLibList[0]);
        Database.insert(oppClauseList);      
        oppClauseList = [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c,RecordType.Name,RiskApplies__c FROM OpportunityClause__c];
        
    }
    
    public static testMethod void getOppClause() {
        ClauseSelectionController.clauseAndOptionWrapper response = new ClauseSelectionController.clauseAndOptionWrapper(null, null,null,null);
        
        Test.startTest();
       		response = ClauseSelectionController.getClauses([select id from opportunity Limit 1].Id);
       	Test.stopTest();
        
        System.assertEquals(true, response <> null);
        
    }
    
    public static testMethod void createOppClause() {
        ClauseLibrary__c clauseLib = [SELECT Id, Name, ClauseDetails__c,ActivatedDate__c,Type__c,RiskApplies__c, ReasonRecommendation__c from ClauseLibrary__c LIMIT 1];
        String oppClause = 'SELECT Id, Name, ClauseDetails__c, EffectiveFromDate__c, Opportunity__c, Type__c,ReferencedClause__c, RiskApplies__c, ReasonRecommendation__c FROM OpportunityClause__c';
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
       // List<OpportunityClause__c> oppClauseToCreate = new List<OpportunityClause__c>();
        LightningResponse response = new LightningResponse();
        
        Test.startTest();
       		response = ClauseSelectionController.saveClause(oppClause, [select id from opportunity Limit 1].Id);
       	Test.stopTest();
        
        System.assertEquals(true, String.isEmpty(response.returnValue));
        
    }
    
    public static testMethod void getUpdatedClause() {
        OpportunityClause__c oppClasue = [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c,RecordType.Name,RiskApplies__c FROM OpportunityClause__c LIMIT 1];
        OpportunityClause__c updatedOppClasue = new OpportunityClause__c();
        
        Test.startTest();
       		updatedOppClasue = ClauseSelectionController.getUpdatedClause(oppClasue.Id);
       	Test.stopTest();
        
        System.assertEquals(true, updatedOppClasue <> null);
        
    }
    
    public static testMethod void getDeletedClause() {
        List<OpportunityClause__c> oppClasue = [SELECT Id,Opportunity__c FROM OpportunityClause__c LIMIT 1];
        ClauseSelectionController.clauseAndOptionWrapper deleteOppClasue = new ClauseSelectionController.clauseAndOptionWrapper(null, null,null,null);
        List<OpportunityClause__c> selectedClauses = [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c,RecordType.Name,RiskApplies__c FROM OpportunityClause__c];

        Test.startTest();
       		deleteOppClasue = ClauseSelectionController.deleteClause(oppClasue[0].Id, selectedClauses[0].Id);
       	Test.stopTest();
        
        System.assertEquals(true, deleteOppClasue <> null);
        
    }
    
     public static testMethod void getEnableEditStatus() {
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        Boolean editStatus;

        Test.startTest();
       		editStatus = ClauseSelectionController.enableClauseEditUpdate(oppList[0].Id);
       	Test.stopTest();
        
        System.assertEquals(true, editStatus = true);
    }
}