/* 
*@author:               Kyle Tan
*@description:          Test class for the PrecedentClauseTriggerHandler class
*/
@isTest
private class PrecedentClauseTriggerHandlerTest {
    
    //testSetup
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Property__c propertyRecord = new Property__c();
        Account accountRecord = new Account(); 
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c();   
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        List<Space__c> spaceLst = new List<Space__c>();
        Product2 productRecord;
        List<Account> parentAccList = new List<Account>();
        Account account = new Account();
        Contact conRec = new Contact();
        
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
        //CREATE ACCOUNT
        accountList = TestDataFactory.createAccountBulk(10, 
                                                        propertyRecord.Id, 
                                                        accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId());
        database.insert(accountList);
        tempAccountList = [SELECT Id 
                            FROM Account 
                            WHERE ParentId = null 
                            AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() 
                            LIMIT 10];
        accountList = new List<Account>();
        for(Integer counter = 0; counter < 10; counter++) {
            accountRecord = TestDataFactory.createAccountwithParent(counter, 
                                                                    null, 
                                                                    accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), 
                                                                    tempAccountList.get(counter).Id);
            accountList.add(accountRecord);
        }
        database.insert(accountList);
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Account.Property__c FROM Account WHERE ParentId != null LIMIT 100];
        
        opportunityList = TestDataFactory.createOpportunity(accountList);
        
        database.insert(opportunityList);
        
        //CREATE PRECEDENT CLAUSE
        accountList = [SELECT Id 
                        FROM Account 
                        WHERE ParentId = null 
                        AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() 
                        LIMIT 10];

        for(Integer counter = 0; counter < 10; counter++) {
            precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, accountList.get(counter).Id);
            precedentClauseList.add(precedentClauseRecord);
        }
        
        database.insert(precedentClauseList);
    }
    
    /* 
*@author:          Kyle Tan
*@description:     inserts precedent clause
*/
    public static testMethod void uponInsertTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        PrecedentClause__c precedentClauseRecord = new PrecedentClause__c();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Account> accountList = new List<Account>();
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        
        accountList = [SELECT Id 
                       FROM Account 
                       WHERE ParentId = null 
                       AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId() 
                       LIMIT 10];
        
        for(Integer counter = 0; counter < 10; counter++) {
            if(counter < 8) {
                precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, accountList.get(counter).Id);
            } else {
                precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, accountList.get(counter - 1).Id);
            }
            precedentClauseList.add(precedentClauseRecord);
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            database.insert(precedentClauseList);
            precedentClauseList = [SELECT Id FROM PrecedentClause__c LIMIT 1];
            database.delete(precedentClauseList);
            
            Test.stopTest();
        }
        
        opportunityClauseList = [SELECT Id FROM OpportunityClause__c LIMIT 10];
        system.assertEquals(opportunityClauseList.size(), 10);
    }
    
    /* 
*@author:          Kyle Tan
*@description:     updates precedent clause
*/
    public static testMethod void uponUpdateTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        
        List<PrecedentClause__c> precedentClauseList = [SELECT Id, Type__c, Name, Description__c, 
                                                                Comments__c, EffectiveToDate__c 
                                                                FROM PrecedentClause__c 
                                                                LIMIT 10];
        List<Account> accountList = new List<Account>();
       
        OpportunityClause__c opportunityClauseRecord = new OpportunityClause__c();
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            for(PrecedentClause__c tempPrecedentClauseRecord : precedentClauseList) {
                tempPrecedentClauseRecord.Description__c = 'Test Change Description';
                tempPrecedentClauseRecord.Comments__c = 'Test Change Comments';
                tempPrecedentClauseRecord.EffectiveToDate__c = date.today() + 1;
                tempPrecedentClauseRecord.Nil_Holdover_Increase__c = false;
            }
            
            Database.update(precedentClauseList);
            
            System.debug('UPDATE  ' + precedentClauseList);
            
            Test.stopTest();
            
        }
        for(PrecedentClause__c precedentClauseRecord : [SELECT Id, Description__c, Comments__c, EffectiveToDate__c 
                                                            FROM PrecedentClause__c 
                                                            LIMIT 10]) {
                                                                system.assertEquals('Test Change Description', precedentClauseRecord.Description__c);
                                                                system.assertEquals('Test Change Comments', precedentClauseRecord.Comments__c);
                                                            }
        
    }
    
}