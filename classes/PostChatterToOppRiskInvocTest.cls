/**
* @author:          Sidney Garcia
* @description:     Test class for PostChatterToOppRiskInvoc
**/
@isTest
public class PostChatterToOppRiskInvocTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        ClauseLibrary__c clauseLibRecord = new ClauseLibrary__c();
        
        //CREATE TEST USERS
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        
        Database.insert(testUserList); 
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        database.insert(productRecord);
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
        
       //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(10, account);
        database.insert(opportunityList);
        
        //CREATE CLAUSE LIBRARY
        clauseLibList = TestDataFactory.createClauseLibrary(1);
        clauseLibList[0].RiskClauseNotifyUsers__c = 'Accounts Receivable Admin';
        Database.insert(clauseLibList);
        
        //CREATE OPPORTUNITY CLAUSE
        for(Opportunity opp : opportunityList){
            oppClauseList.add(
                TestDataFactory.createOpportunityClause(1, opp, clauseLibList[0])[0]
            );
        }
        Database.insert(oppClauseList);      
        
        //oppClauseList = [SELECT Id,Name, ClauseDetails__c, ReferencedClause__c,RecordType.Name,RiskApplies__c FROM OpportunityClause__c];
        //System.debug('Opp Clause List' + oppClauseList);
        
        //CREATE PROPERTY TEAM
        Id internalTeamRecTypeId;
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, 'Accounts Receivable Admin',  testUserList[0].Id, internalTeamRecTypeId);
        database.insert(propteam);
    }
    
    public static testMethod void postChatterToOppRiskTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        ChatterPostUtil.chatterNotificationWrapper chatterItem = new ChatterPostUtil.chatterNotificationWrapper();
        List<Id> oppIDLst = new List<Id>();
        
        for(Opportunity opp : oppList){
            oppIDLst.add(opp.Id);
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            PostChatterToOppRiskInvoc.postChatterToOppRisk(oppIDLst);
            Test.stopTest();
        }
        List<OpportunityFeed> oppFeed = [SELECT ID, ParentId, Body from OpportunityFeed where Id in :oppIDlst];
        System.assertEquals(true, oppFeed <> null);
        
    }
}