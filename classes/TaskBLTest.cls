@isTest
public class TaskBLTest {
  @TestSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Product2> productList = new List<Product2>();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        Pricebook2 pricebookRecord;
        Product2 productRecord;
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        propertyList[0].Pricebook__c = priceBookRec.Id;
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
          
        //CREATE PRECEDENT CLAUSE
        
        for(Integer counter = 0; counter < 200; counter++) {
            precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, account.Id);
            if(counter < 190) {
                precedentClauseRecord.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId();
            } else {
                precedentClauseRecord.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId();
            }
            precedentClauseRecord.StandardReviewTypes__c = 'CPI+1.5';
            precedentClauseList.add(precedentClauseRecord);
        }
        database.insert(precedentClauseList);
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(1, account);
        database.insert(opportunityList);
        
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        Task newTask = TestDataFactory.createTask(taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), opportunityList[0].id, null, 'test', '03 - Certify Lease');
        database.insert(newTask);
    }
    public static testMethod void testpayload() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Task tsk = [select status from Task limit 1];
        system.runAs(testUser) {
            Test.startTest();
            tsk.status = 'Completed';
            database.update(tsk);
            Test.stopTest();
        }
    }
}