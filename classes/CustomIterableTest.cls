/*
*       author: Sidney Garcia
*       description: Test class for CustomIterable
*/

@isTest
public class CustomIterableTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        Contact conRec = new Contact();
        
       	//CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(5, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        for(Account acc : accountList){
            acc.TechDispatchedVersion__c = 1;
            acc.TechDispatchedTimeStamp__c = System.now();
        }
        database.insert(accountList);
        
        //CREATE CONTACT
        for(Integer i = 0; i < accountList.size(); i++){
            conRec = TestDataFactory.createContact('Test Contact', accountList[0]);
            contactList.add(conRec);
        }
        for(Contact con : contactList){
            con.TechDispatchedVersion__c = 1;
            con.TechDispatchedTimeStamp__c = System.now();
        }
        database.insert(contactList);
        //CREATE SPACE
        List<Space__c> spaceList = TestDataFactory.createSpace(5, propertyList[0]);
        for(Space__c space : spaceList){
            space.TechDispatchedVersion__c = 1;
            space.TechDispatchedTimeStamp__c = System.now();
        }
        database.insert(spaceList);
    }
    
    public static testMethod void testCustomIterable() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Boolean hasNext;
		SObject sObjs;
        System.runAs(testUser) {
            
            Test.startTest();
            CustomIterable testIterable = new CustomIterable();
            testIterable.iterator();
            hasNext = testIterable.hasNext();
            sObjs = testIterable.next();
            Test.stopTest();
        }
        //Assertion
        System.assertEquals(true, hasNext);
        System.assertEquals(true, sObjs <> null);
    }
    
    public static testMethod void testCustomIterableNoRecords(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Account> accList = [SELECT Id from Account WHERE TechEventVersionSame__c = FALSE];
        List<Space__c> spaceList = [SELECT Id from Space__c WHERE TechEventVersionSame__c = FALSE];
        Boolean hasNext;
		SObject sObjs;
        System.runAs(testUser) {
            delete accList;
            delete spaceList;
            
            Test.startTest();
            CustomIterable testIterable = new CustomIterable();
            testIterable.iterator();
            hasNext = testIterable.hasNext();
            sObjs = testIterable.next();
            Test.stopTest();
        }
        
        System.assertEquals(false, hasNext);
        System.assertEquals(false, sObjs <> null);
    }
}