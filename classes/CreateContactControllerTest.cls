@isTest
public class CreateContactControllerTest {
    public static testMethod void testSearchContact(){
        //Property__c prop = TestDataFactory.createProperty(1, Test.getStandardPricebookId());
        Account acc = TestDataFactory.createAccount(1);
        insert acc;
        Contact con = TestDataFactory.createContact('Test Contact', acc);
        insert con;
        
        Test.startTest();
        Contact con1 = CreateContactController.searchContact(con.Id);
        Test.stopTest();
        
        System.assertEquals(con1.Id, con.Id, 'Ids are same as expected');
    }
    
    testMethod public static void testSearchContactNegative(){
        
        Test.startTest();
        Contact con = CreateContactController.searchContact(null);
        Test.stopTest();
        
        System.assertEquals(con, null, 'Contact returned is null');
    }
    
}