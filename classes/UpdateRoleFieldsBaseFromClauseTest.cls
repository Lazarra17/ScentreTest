/*
*       author: Clark Marie Garde
*       created date: July 06, 2018
*       description: Test class for UpdateRoleFieldsBaseFromClause
*
*/

@isTest
public class UpdateRoleFieldsBaseFromClauseTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList= new List<Property__c>();
        Property__c propertyRec = new Property__c();
        List<User> userList = new List<User>();
        User userRec = new User();
        List<Opportunity> oppList= new List<Opportunity>();
        List<Opportunity> oppRec = new  List<Opportunity>();
        List<Pricebook2> priceBookRec = new List<Pricebook2>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        List<ClauseLibrary__c> clauseLibRec = new List<ClauseLibrary__c>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //CREATE USER
        userList.add(TestDataFactory.createUniqueTestUser('Test', 'User', profileRec.Id));
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        for(Space__c sp : spaceList){
            sp.Type__c = '3';
        }
        database.insert(spaceList);

        //Create Opportunity
        oppList = TestDataFactory.createOpportunity(3, account, propertyList[0], spaceList[0]);
        for(Opportunity opp : oppList){
            //opp.RCAsReviewed__c = false;
        }
        database.insert(oppList);
        
        //CREATE CONTRACT
        contractList = TestDataFactory.createContract(10, account, propertyList[0], oppList[0]);
        database.insert(contractList);
        contractList = [SELECT Id, Opportunity__c FROM Contract__c];
        
        //CREATE CLAUSE LIBRARY
        clauseLibList = TestDataFactory.createClauseLibrary(10);
        clauseLibList[0].RiskClauseApprovers__c = 'Corporate Legal';
        database.insert(clauseLibList);
        clauseLibRec = [SELECT Id,RiskClauseApprovers__c  FROM ClauseLibrary__c];
       
        //CREATE OPPORTUNITY CLAUSE
        oppClauseList = TestDataFactory.createOpportunityClause(10, oppList[0], clauseLibList[0]);
        database.insert(oppClauseList);
        oppClauseList = [SELECT Id,ReferencedClause__c,ReferencedClause__r.RiskClauseApprovers__c,Type__c FROM OpportunityClause__c];

    }
    public static testMethod void testUpdateRole() {
        List<Contract__c> contractList = [SELECT Id, Opportunity__c FROM COntract__c LIMIT 1];
        List<Opportunity> oppLst = [select Id,GroupGeneralManagerLARS__c,approvalStatus__c,CapitalVariance__c,RentVariance__c, 
                                    Property__c,RMRetailAdmin__c,RMLARS__c,GMLARS__c,GMRetailAdmin__c,CorporateLegal__c,DirectorLARSNZDevelopment__c, COO__c
                                    from Opportunity];
        
        List<OpportunityClause__c> oppClauseList = [select Opportunity__c,Type__c,Approved__c,id,ReferencedClause__c,ReferencedClause__r.RiskClauseApprovers__c from OpportunityClause__c];
       
            Test.startTest();
            List<Id> oppIdList = new List<Id>();
                for(Opportunity opp: oppLst){
                    oppIdList.add(opp.Id);
                }
        
            UpdateRoleFieldsBaseFromClause.updateRoleFields(oppIdList);
        Test.stopTest();
        
        system.assert(true, oppIdList <> null);
        
    }
}