@isTest
public class LightningLookupControllerFlowTest {
    
@testSetup
    private static void testSetup(){
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        List<AccountContactRelation> accConRecList = new List<AccountContactRelation>([Select Id, ContactId, AccountId From AccountContactRelation]);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> opportunityRecTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        Contact conRec = new Contact();
        Pricebook2 pricebookRec = new Pricebook2();
        
        //Create Pricebook
        pricebookRec = TestDataFactory.createPricebook();
        pricebookRec.CurrencyIsoCode = 'AUD';
        database.insert(pricebookRec);
        
        //Create Property
        propertyList = TestDataFactory.createProperty(10, pricebookRec);
        database.insert(propertyList);
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        account.TradingName__c = 'Test Name';
        database.insert(account);
        account = [SELECT Id, Property__c, Name, TradingName__c, ShippingCountry from Account LIMIT 1];
        System.debug('Account ' + account);
        //Create Contact
        conRec = TestDataFactory.createContact('Test Contact', account);
        database.insert(conRec);
        
        
    }
    
    
    private static testMethod void testGetRecords() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningLookupControllerFlow.LookupRecords res = new LightningLookupControllerFlow.LookupRecords();
        System.runAs(testUser){
            Test.startTest();
            res = LightningLookupControllerFlow.getRecords('Account', 'Id', 'TradingName__c', '', 'TradingName__c LIKE \'ABCZ%\'','ShippingCountry','Australia');
            System.debug('RESULT ' +  res);
            Test.stopTest();
        }
        System.assert(res <> null);
    }
    
    private static testMethod void testGetRecordsNoReturnValue() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningLookupControllerFlow.LookupRecords res = new LightningLookupControllerFlow.LookupRecords();
        System.runAs(testUser){
            Test.startTest();
            res = LightningLookupControllerFlow.getRecords('Account', 'Id', 'TradingName__c', '', 'TradingName__c LIKE \'123%\'','ShippingCountry','Australia');
            System.debug('RESULT ' +  res);
            Test.stopTest();
        }
        System.assert(true, res == null);
    }
    
    private static testMethod void testGetRecordsNullDisplayNameValueFieldName() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningLookupControllerFlow.LookupRecords res = new LightningLookupControllerFlow.LookupRecords();
        System.runAs(testUser){
            Test.startTest();
            res = LightningLookupControllerFlow.getRecords('Account', '', '', '', 'TradingName__c LIKE \'123%\'','ShippingCountry','Australia');
            System.debug('RESULT ' +  res);
            Test.stopTest();
        }
        System.assert(true, res == null);
    }
    
    private static testMethod void testGetFieldValue(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accountRec = [SELECT Id FROM Account Limit 1];
        
        System.runAs(testUser){
            Test.startTest();
            LightningLookupControllerFlow.LookupRecords res = LightningLookupControllerFlow.getFieldValue('Account', accountRec.Id, 'Name');
            System.debug('RESULT ' +  res);
            Test.stopTest();
        }
    }
    private static testMethod void testGetHelpText(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accountRec = [SELECT Id FROM Account Limit 1];
        
        System.runAs(testUser){
            Test.startTest();
            String s = LightningLookupControllerFlow.getHelpText('Account.Name');
            
            Test.stopTest();
        }
    }
    
    private static testMethod void testGetReference(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accountRec = [SELECT Id FROM Account Limit 1];
        
        System.runAs(testUser){
            Test.startTest();
            String s = LightningLookupControllerFlow.getReference('Account.OwnerId');
            
            Test.stopTest();
        }
    }
    
}