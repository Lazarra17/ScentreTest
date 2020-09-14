@isTest
public class UnlockAllLockedOpporutnitySchedulTest {
     static testmethod void testUnlockAllLockedOpporutnitySchedul (){
        
        List<Account> accountsWithParentList = new List<Account>([SELECT Id, Property__c FROM Account WHERE ParentId != null LIMIT 100]);
        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList.addAll(TestDataFactory.createOpportunity(accountsWithParentList));  
        Test.startTest();
        UnlockAllLockedOpporutnitySchedul shOpp = new UnlockAllLockedOpporutnitySchedul();
        String schtime = '0 15 * * * ?'; 
        system.schedule('UnlockAllLockedOpp', schtime, shOpp); 
        Test.stopTest();
     }
    
}