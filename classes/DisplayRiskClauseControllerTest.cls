/*
*       author: Clark Marie Garde
*       created date: June 28, 2018
*       description: Test class for DisplayRiskClauseController
* 
*/

@isTest
public class DisplayRiskClauseControllerTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account account = new Account();
        List<Property__c> propertyList = new List<Property__c>();
        List<Space__c> spaceList= new List<Space__c>();
        List<Contract__c> contrList= new List<Contract__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<Account> parentAccList = new List<Account>();
        Property__c propertyRecord = new Property__c();
        Account accountRecord = new Account();
        Contract__c contrRecord = new Contract__c();
        Space__c spaceRecord = new Space__c();
        Opportunity oppRecord = new Opportunity();
        OpportunityClause__c oppClauseRecord = new OpportunityClause__c();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyRecord = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //CREATE Space
        spaceList = TestDataFactory.createSpace(10, account, propertyList[0]);
        Database.insert(spaceList);
        spaceRecord = [SELECT Id, BackupRetailer__c, Property__c FROM Space__c limit 1];
        
        //CREATE OPPORTUNITY
        oppList = TestDataFactory.createOpportunity(10, account, propertyList[0], spaceList[0]);
        Database.insert(oppList);
        oppRecord = [SELECT Id, AccountId, Property__c, Space__c FROM Opportunity limit 1];
        
        //CREATE Contract
        contrList = TestDataFactory.createContract(10, account, propertyList[0], oppList[0]);
        database.insert(contrList);
        system.debug('contracttt' + contrList);
        contrRecord = [SELECT Id, Name, Account__c FROM Contract__c limit 1]; 
        
        //CREATE CLAUSE LIBRARY
        List<ClauseLibrary__c> clauseLibraryList = TestDataFactory.createClauseLibrary(10);
        Database.insert(clauseLibraryList);
        
        //CREATE OPPORTUNITY CLAUSE
        Integer counter = 0;
        for(Opportunity opp : oppList){
            counter = 0;
            for(OpportunityClause__c oppClause : TestDataFactory.createOpportunityClause(10, opp)){
                oppClause.ReferencedClause__c = clauseLibraryList[counter].Id;
                counter++;
                
                oppClauseList.add(oppClause);
            }
        }
        
        Database.insert(oppClauseList);
    }
    
    @isTest
    private static void testGetPropertyRecord() {
        Property__c prop = [SELECT ID FROM Property__c LIMIT 1];
        DisplayRiskClauseController.Response response = new DisplayRiskClauseController.Response();
        
        Test.startTest();
            response = DisplayRiskClauseController.getDetails(prop.ID, 'Risktab');
        Test.stopTest();
        
        System.assertEquals('Success', response.status);
        
    }
    
    @isTest
    private static void testGetOpportunityRecord() {
        Opportunity opp = [SELECT ID FROM Opportunity LIMIT 1];
        DisplayRiskClauseController.Response response = new DisplayRiskClauseController.Response();
        
        Test.startTest();
            response = DisplayRiskClauseController.getDetails(opp.ID, '');
        Test.stopTest();
        
        System.assertEquals('Success', response.status);
        
    }
    
    @isTest
    private static void testGetOpportunityRecordRiskTab() {
        Opportunity opp = [SELECT ID FROM Opportunity LIMIT 1];
        DisplayRiskClauseController.Response response = new DisplayRiskClauseController.Response();
        
        Test.startTest();
            response = DisplayRiskClauseController.getDetails(opp.ID, 'Risktab');
        Test.stopTest();
        
        System.assertEquals('Success', response.status);
        
    }
    
    @isTest
    private static void testGetSpaceRecord() {
        Space__c spac = [SELECT ID FROM Space__c LIMIT 1];
        DisplayRiskClauseController.Response response = new DisplayRiskClauseController.Response();
        
        Test.startTest();
            response = DisplayRiskClauseController.getDetails(spac.ID, '');
        Test.stopTest();
        
        system.assertEquals('Success', response.status);
        
    }
    
    @isTest
    private static void testIsColumnEditable() {
        Opportunity opp = [SELECT Id, Stagename, OwnerId from Opportunity limit 1];
        Boolean canUpdate;
        
        Test.startTest();
            canUpdate = DisplayRiskClauseController.isColumnEditable(opp);
        Test.stopTest();
        
        System.assertEquals(true, canUpdate);
        
    }
    
    @isTest
    private static void testUserHasEditAccess() {
        Opportunity opp = [SELECT id, DealAchieved__c FROM Opportunity limit 1];
        Boolean userAccess;
        
        Test.startTest();
            userAccess = DisplayRiskClauseController.userHasEditAccess(opp.Id);
        Test.stopTest();
        
        System.assertEquals(true, userAccess);
        
    }
    
    @isTest
    private static void testUpdateOpportunityClause() {
        Opportunity opp = [SELECT ID FROM Opportunity LIMIT 1];
        DisplayRiskClauseController.Response response = new DisplayRiskClauseController.Response();
        
        response = DisplayRiskClauseController.getDetails(opp.ID, 'Risktab');
        
        Test.startTest();
            response = DisplayRiskClauseController.updateOpportunityClause(response.returnValue);
        Test.stopTest();
    }
    
}