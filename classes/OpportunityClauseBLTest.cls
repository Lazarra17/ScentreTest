@isTest
public class OpportunityClauseBLTest {
    @testSetup
    private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account account = new Account();
        Opportunity opp = new Opportunity();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE Account
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
        
        //CREATE Opportunity
        opportunityList = TestDataFactory.createOpportunity(20, account);
        database.insert(opportunityList);
        opp = [SELECT ID FROM Opportunity LIMIT 1];
        
  
    }
        @isTest
        public static void createOpportunityClause(){
            Test.startTest();
            Opportunity opp = [SELECT ID FROM Opportunity LIMIT 1];
            System.debug('Sample Opp created'  + opp);
			
            OpportunityClause__c oppClauseRecord = new OpportunityClause__c();
            oppClauseRecord.Name = 'Opportunity Clause';
            oppClauseRecord.ClauseDetails__c = 'Sample detail';
            oppClauseRecord.RiskApplies__c = true;
            oppClauseRecord.Opportunity__c = opp.Id;
            
            insert oppClauseRecord;
            
            opp = [SELECT Id, ClauseSummary__c FROM Opportunity LIMIT 1];
            
            system.assert(opp.ClauseSummary__c.contains(oppClauseRecord.Name));
            
            System.debug('Sample Clause' +  oppClauseRecord);
            Test.stopTest();      
        }
}