/**
 * @author:				Kyle Tan
 * @desc:				Test Class for UserManagerCheck
 **/
@isTest
private class UserManagerCheckTest {
    
    @testSetup
    private static void testSetup() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        //Create Users
        Profile tempProfileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        List<User> userList = new List<User>();
        userList.add(TestDataFactory.createUniqueTestUser('John', 'A', tempProfileRec.Id));
        userList.add(TestDataFactory.createUniqueTestUser('John', 'B', tempProfileRec.Id));
        userList[0].EmployeeNumber = '12345';
        userList[1].ManagerEmployeeID__c = '12345';
        system.runAs(testUser) {
            database.insert(userList);
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    private static void userManagerFulfillTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id FROM User WHERE EmployeeNumber = '12345' OR ManagerEmployeeID__c = '12345']);
        List<Id> userIdList = new List<Id>();
        userIdList.addAll(userMap.keySet());
        system.runAs(testUser) {
            test.startTest();
            UserManagerCheck.userManagerFulfill(userIdList);
            test.stopTest();
        }
    }
}