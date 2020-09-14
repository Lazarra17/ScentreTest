/*
* @author:              Sidney Garcia
* @description:         Test class for SchemaDescribeBL
*/
@isTest
public class SchemaDescribeBLTest {
	@TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(1);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1, pricebookList[0]);
        database.insert(propertyList);
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //CREATE OPPORTUNITY
        account = [SELECT Id, Property__c FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(1, account);
        database.insert(opportunityList);
    }
    public static testMethod void testdescribefieldnamefromFS(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String,Set<String>> describefieldnamefromFS = new Map<String,Set<String>>();
        System.runAs(testUser) {
            
            Test.startTest();
            describefieldnamefromFS = SchemaDescribeBL.describefieldnamefromFS(CONSTANTS.SPACE, CONSTANTS.SPACE_INTEGRATION_FIELDSET);
            Test.stopTest();
        }
        
    }
}