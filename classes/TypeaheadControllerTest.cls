@isTest
public class TypeaheadControllerTest {

    public static testMethod void searchDBTest1(){
        
        Account acc = TestDataFactory.createAccount(1);
        insert acc;
        Contact con = TestDataFactory.createContact('Test Contact', acc);
        insert con;
        
        Test.startTest();
        String str = TypeaheadController.searchDB('Account', 'Name', 'Id', 10, 'Name', 'test', '', true);
        System.debug(str);
        Object wrapperList = JSON.deserializeUntyped(str);
        System.debug(wrapperList);
        Test.stopTest();
        
        System.assertNotEquals(wrapperList, null, 'Found the Account record');
    }
    
    public static testMethod void searchDBTest2(){
        
        Account acc = TestDataFactory.createAccount(1);
        insert acc;
        Contact con = TestDataFactory.createContact('Test Contact', acc);
        insert con;
        
        Test.startTest();
        String str = TypeaheadController.searchDB('Account', 'Name', 'Id', 10, 'Name', 'test', 'Name = \'Test Account 2\'', false);
        System.debug(str);
        Object wrapperList = JSON.deserializeUntyped(str);
        System.debug(wrapperList);
        Test.stopTest();
        
        System.assertNotEquals(wrapperList, null, 'Found the Account record');
    }
}