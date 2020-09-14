/**
 * @author:				Kyle Tan
 * @desc:				test class for TriggerHandler class
 **/
@isTest
private class TriggerHandlerTest {
    
    /**
     * @author:				Kyle Tan
     **/
    @istest
    private static void TriggerHandlerCall() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler tempTriggerHandler = new TriggerHandler();
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.clearAllBypasses();
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
            TriggerHandler.isBypassed('OpportunityTriggerHandler');
            test.stopTest();
        }
    }
}