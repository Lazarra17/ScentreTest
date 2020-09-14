/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CreateForecastOpportunityTest {

    @isTest
    static void myUnitTest() {
		Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        Property__c property = TestDataFactory.createProperty(1, priceBookRec)[0];
        property.PropertyStatus__c = 'Active';
        Database.insert(property);
        Property__c propRec = [SELECT Id, Name FROM Property__c LIMIT 1];

        //CREATE ACCOUNT
        //accountList.addAll(TestDataFactory.createAccountBulk(10, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        //database.insert(accountList);
        test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type = 'Forecast';
        acc.Property__c = propRec.Id;
        acc.TradingName__c = 'ABCZ';
        acc.RecordTypeId = accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId();
        acc.ShippingCountry = 'Australia';
        acc.ShippingStreet = '1234 Test Street Drive';
        acc.ShippingCity = 'Sydney';
        acc.ShippingState = 'Queensland';
        acc.ShippingPostalCode = '1234';
        acc.BillingCountry = 'Australia';
        acc.BillingStreet = '1234 Test Street Drive';
        acc.BillingCity = 'Sydney';
        acc.BillingState = 'Queensland';
        acc.BillingPostalCode = '1234';
        acc.BillingEmailAddress__c = 'testemail@address.com';
        acc.ACN__c = 'ACN';
        acc.Category__c = 'S420';
        acc.SuperfineCategory__c = 'S421';
        acc.LesseeName__c = 'Test Lessee';
        
        insert acc;
        
        
        List<Space__c> spaceList = TestDataFactory.createSpace(5, propRec);
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
            //test.startTest();
                Database.insert(spaceList);
        		CreateForecastOpportunity.checkSpaceCriteria(spaceList);
            test.stopTest();
    }
    
    @isTest
    static void myUnitTest1() {
		Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        Property__c property = TestDataFactory.createProperty(1, priceBookRec)[0];
        property.PropertyStatus__c = 'Active';
        Database.insert(property);
        Property__c propRec = [SELECT Id, Name FROM Property__c LIMIT 1];

        //CREATE ACCOUNT
        //accountList.addAll(TestDataFactory.createAccountBulk(10, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        //database.insert(accountList);
        List<Account> accList = new List<Account>();
        test.startTest();
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type = 'Forecast';
        acc.Property__c = propRec.Id;
        acc.TradingName__c = 'ABCZ';
        acc.RecordTypeId = accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId();
        acc.ShippingCountry = 'Australia';
        acc.ShippingStreet = '1234 Test Street Drive';
        acc.ShippingCity = 'Sydney';
        acc.ShippingState = 'Queensland';
        acc.ShippingPostalCode = '1234';
        acc.BillingCountry = 'Australia';
        acc.BillingStreet = '1234 Test Street Drive';
        acc.BillingCity = 'Sydney';
        acc.BillingState = 'Queensland';
        acc.BillingPostalCode = '1234';
        acc.BillingEmailAddress__c = 'testemail@address.com';
        acc.ACN__c = 'ACN';
        acc.Category__c = 'S420';
        acc.SuperfineCategory__c = 'S421';
        acc.LesseeName__c = 'Test Lessee';
        
        Account acc1 = new Account();
        acc1.Name = 'Account Test';
        acc1.Type = 'Forecast';
        acc1.Property__c = propRec.Id;
        acc1.TradingName__c = 'ABCZ';
        acc1.RecordTypeId = accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId();
        acc1.ShippingCountry = 'Australia';
        acc1.ShippingStreet = '1234 Test Street Drive';
        acc1.ShippingCity = 'Sydney';
        acc1.ShippingState = 'Queensland';
        acc1.ShippingPostalCode = '1234';
        acc1.BillingCountry = 'Australia';
        acc1.BillingStreet = '1234 Test Street Drive';
        acc1.BillingCity = 'Sydney';
        acc1.BillingState = 'Queensland';
        acc1.BillingPostalCode = '1234';
        acc1.BillingEmailAddress__c = 'testemail@address.com';
        acc1.ACN__c = 'ACN1';
        acc1.Category__c = 'S420';
        acc1.SuperfineCategory__c = 'S421';
        acc1.LesseeName__c = 'Test Lessee1';
        
        accList.add(acc);
        accList.add(acc1);
        
        insert accList;
        
        
        List<Space__c> spaceList = TestDataFactory.createSpace(5, propRec);
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
            //test.startTest();
                Database.insert(spaceList);
        		CreateForecastOpportunity.checkSpaceCriteria(spaceList);
            test.stopTest();
    }
}