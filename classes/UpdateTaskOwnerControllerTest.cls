/*
*       author: Clark Marie Garde
*       created date: Aug 20, 2018
*       description: Test class for UpdateTaskOwnerController
* 
*/
@isTest
public class UpdateTaskOwnerControllerTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        User testUser = new User();
        Task task = new Task();
        List<Opportunity> oppList = new List<Opportunity>();
        Contact contact = new Contact();
        Account account = new Account();
        List<Space__c> spaceList = new List<Space__c>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Space__c> spaceLst = new List<Space__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contrList = new List<Contract__c>();
        Product2 productRecord;
        
        //CREATE USER
        testUser = TestDataFactory.sysAdministrator();
        database.insert(testUser);
        testUser = [SELECT Id, Profile.Name from User LIMIT 1];
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        //System.debug('Pricebook rec ' + priceBookRec);
        
        propertyList = TestDataFactory.createProperty(1);
        for(Property__c property : propertyList){
            property.PriceBook__c = priceBookRec.Id;
        }
        Database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 5];
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        database.insert(accountList);
        //System.debug('Account List ' + accountList);
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        
        //CREATE SPACE
        spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        spaceLst[0].BillingCategory__c = 'NA';
        database.insert(spaceLst);
        
        //CREATE CONTRACT
        spaceLst = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
        
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceLst);
        //System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        
        
        //CREATE TASK
        task = TestDataFactory.createTaskRelatedToOpp(opportunityList[0].id, contact);
        database.insert(task);
        task = [SELECT Id,OwnerId from Task];
    }
    
    public static testMethod void testUpdateTaskOwner() {
        User userinfo=[select id,Profile.Name from User LIMIT 1];
        List<Task> taskList = [SELECT Id, OwnerId from Task LIMIT 1];
        String updateTaskOwner;
        
        Test.startTest();
        updateTaskOwner = UpdateTaskOwnerController.UpdateTaskOwner(taskList[0].OwnerId, taskList[0].Id);
        Test.stopTest();
        
    }
    
    public static testMethod void testValidate() {
        User userinfo=[select id,Profile.Name from User LIMIT 1];
        List<Task> taskList = [SELECT Id, OwnerId from Task LIMIT 1];
        String updateTaskOwner;
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
            Test.startTest();
                UpdateTaskOwnerController temp = new UpdateTaskOwnerController();
                temp.validate();
            Test.stopTest();  
        
    }
    
    public static testMethod void testUpdateTaskOwnerSC() {
        User userinfo=[select id,Profile.Name from User LIMIT 1];
        List<Task> taskList = [SELECT Id, OwnerId from Task LIMIT 1];
        String updateTaskOwner;
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
            Test.startTest();
        	ApexPages.StandardSetController apSSC = new ApexPages.StandardSetController(taskList);
            UpdateTaskOwnerController ut = new UpdateTaskOwnerController(apSSC);
            Test.stopTest();  
        
    }
    
}