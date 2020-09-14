@isTest
public class CreateAccountControllerTest {
    testMethod public static void testSearchContact(){
        Account acc = TestDataFactory.createAccount(1);
        insert acc;
        Contact con = TestDataFactory.createContact('Test Contact', acc);
        insert con;
        
        Test.startTest();
        Contact con1 = CreateAccountController.searchContact(acc.Id);
        Test.stopTest();
        
        System.assertEquals(con1.Id, con.Id, 'Ids are same as expected');
    }
    
    testMethod public static void testSearchContactNegative(){
        
        Test.startTest();
        Contact con = CreateAccountController.searchContact(null);
        Test.stopTest();
        
        System.assertEquals(con, null, 'Contact returned is null');
    }
}