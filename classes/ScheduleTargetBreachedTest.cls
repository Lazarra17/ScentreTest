@isTest
public class ScheduleTargetBreachedTest {
    
    static testmethod void testScheduleTargetBreached (){
    
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Account> accountsWithParentList = new List<Account>([SELECT Id, Property__c FROM Account WHERE ParentId != null LIMIT 100]);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        Map<Id, PrecedentClause__c> precedentClauseMap = new Map<Id, PrecedentClause__c>();
        
        for(PrecedentClause__c precedentClauseRecord :[SELECT Id, Name, Type__c, Description__c, Comments__c, EffectiveToDate__c FROM PrecedentClause__c WHERE Account__c != null]) {
            precedentClauseMap.put(precedentClauseRecord.Id, precedentClauseRecord);
        }
        
        opportunityList.addAll(TestDataFactory.createOpportunity(accountsWithParentList));
        
        System.runAs(testUser) {
            
            database.insert(opportunityList, false);
            
        }    
        Test.startTest();
        ScheduleTargetBreached sh1 = new ScheduleTargetBreached();
        String sch = '0 0 2 * * ?'; 
        system.schedule('ScheduleTargetBreached', sch, sh1); 
        Test.stopTest();
    }
    
}