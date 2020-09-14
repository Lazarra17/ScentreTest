/*
Copyright 2017 OpFocus, Inc

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.		
*/
@isTest
public class LightningLookupControllerTest {

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
        account.Name = 'abc';
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
        LightningLookupController.LookupRecords res = new LightningLookupController.LookupRecords();
        System.runAs(testUser){
            Test.startTest();
            res = LightningLookupController.getRecords('Account', 'Id', 'TradingName__c', '', 'TradingName__c LIKE \'%ABCZ%\'','ShippingCountry','Australia');
            System.debug('RESULT ' +  res);
            Test.stopTest();
        }
        System.assert(res <> null);
    }
    
    private static testMethod void testGetRecordsNoReturnValue() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningLookupController.LookupRecords res = new LightningLookupController.LookupRecords();
        System.runAs(testUser){
            Test.startTest();
            res = LightningLookupController.getRecords('Account', 'Id', 'TradingName__c', '', 'TradingName__c LIKE \'%123%\'','ShippingCountry','Australia');
            System.debug('RESULT ' +  res);
            Test.stopTest();
        }
        System.assert(true, res == null);
    }
    
    private static testMethod void testGetRecordsNullDisplayNameValueFieldName() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        LightningLookupController.LookupRecords res = new LightningLookupController.LookupRecords();
        System.runAs(testUser){
            Test.startTest();
            res = LightningLookupController.getRecords('Account', '', '', '', 'TradingName__c LIKE \'123%\'','ShippingCountry','Australia');
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
            LightningLookupController.LookupRecords res = LightningLookupController.getFieldValue('Account', accountRec.Id, 'Name');
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
            String s = LightningLookupController.getHelpText('Account.Name');
            
            Test.stopTest();
        }
    }
    
    private static testMethod void testGetReference(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accountRec = [SELECT Id FROM Account Limit 1];
        
        System.runAs(testUser){
            Test.startTest();
            String s = LightningLookupController.getReference('Account.OwnerId');
            
            Test.stopTest();
        }
    }
	
}