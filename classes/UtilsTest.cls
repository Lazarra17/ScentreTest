/**
 * @author:				Kyle Tan
 * @desc:				Test Class for Utils
 **/
@isTest
private class UtilsTest {

    /**
     * @author:				Kyle Tan
     **/
    @isTest
    private static void getCreatableFieldsSOQLTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Id> idList = new List<Id>();
        system.runAs(testUser) {
            test.startTest();
            Utils.getCreatableFieldsSOQL(Constants.OPPORTUNITY_CLAUSE_API, 'Id != null', idList, Constants.FIELD_SET_API_NAME_CLONE);
            test.stopTest();
        }
    }
}