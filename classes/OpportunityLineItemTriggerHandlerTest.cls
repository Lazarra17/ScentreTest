/**
 * @author:        Kyle Tan
 * @desc:        Test Class for OpportunityLineItemTriggerHandler
 **/
@isTest
private class OpportunityLineItemTriggerHandlerTest {
    
    @testSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> clauseLibTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.CLAUSE_LIBRARY_API);
        Map<String, Schema.RecordTypeInfo> oppClauseTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
       
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        propertyList[0].Pricebook__c = Test.getStandardPricebookId();
        database.insert(propertyList);
        
        //Create Account
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        accountList[0].PartnershipSegmentation__c = Constants.GROWTH_PARTNER;
        database.insert(accountList);
        
        //Create Contact
        List<Contact> contactList = new List<Contact>();
        contactList.add(TestDataFactory.createContact('Test Name', accountList[0]));
        database.insert(contactList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);

        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(3, accountList[0], propertyList[0], spaceList[0]);
        oppList[0].TechByPassOnClone__c = true;
        database.insert(oppList);
        
        //Create Product
        List<Product2> productList = new List<Product2>();
        productList.add(TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.PRODUCT_RENT_REVIEW));
        productList.add(TestDataFactory.createProduct(Constants.PRODUCT_PROMO_REVIEW, Constants.PRODUCT_PROMO_REVIEW));
        productList.add(TestDataFactory.createProduct(Constants.FEES_CHARGES, Constants.FEES_CHARGES));
        productList.add(TestDataFactory.createProduct(Constants.RECOVERIES, Constants.RECOVERIES));
        productList[3].OutgoingsCategory__c=Constants.PRODUCT_AIR_CON;
        productList.add(TestDataFactory.createProduct(Constants.CAPITAL, Constants.CAPITAL));
        productList[4].CapitalCategory__c='Contribution';
        database.insert(productList);
        
        //Create Pricebook Entry
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        
        /*for (Integer counter=0; counter<5; counter++) {
            pbEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[counter]));
        }*/
		pbEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[0]));        
        pbEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[1]));        
        pbEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[2]));        
        pbEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[3]));        
        pbEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[4]));        
        database.insert(pbEntryList);
        
        //Create Opportunity Line Items
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        for (Integer pbEntryListCounter=0; pbEntryListCounter<5; pbEntryListCounter++) {
            for (Integer productListCounter=0; productListCounter<5; productListCounter++) {
                for (Integer oppListCounter=0; oppListCounter<3; oppListCounter++) {
                oppLineItemList.add(TestDataFactory.createOpportunityLineItem(0, oppList[oppListCounter], productList[productListCounter], pbEntryList[pbEntryListCounter]));                   
                }
            }   
        }
        
        OpportunityLineItem opportunityLineItemClone = TestDataFactory.createOpportunityLineItem(1, oppList[2], productList[2], pbEntryList[2]);
        opportunityLineItemClone.TechIsClone__c	=false;
        oppLineItemList.add(opportunityLineItemClone);
        
        database.insert(oppLineItemList);
        
        //Create Clause Library
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        clauseLibList = TestDataFactory.createClauseLibrary(2);
        clauseLibList[1].Type__c = 'RCA';
        clauseLibList[1].SubType__c = 'Rent Review';
        clauseLibList[1].RiskApplies__c = true;
        database.insert(clauseLibList);
        
        //Create Opportunity Clause
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        oppClauseList = TestDataFactory.createOpportunityClause(2, oppList[0], clauseLibList[0]);
        oppClauseList[0].Type__c = 'RCA';
        oppClauseList[0].SubType__c = 'Rent Review';
        database.insert(oppClauseList);
    }
    
    
    

    public static testMethod void testNationalAgreement() {
        //CREATE PRECEDENT CLAUSE
        Map<String, Schema.RecordTypeInfo> precclasueRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PRECEDENT_CLAUSE_API); 
        Account acc = [Select id from Account limit 1];
        PrecedentClause__c precRecord = TestDataFactory.createPrecedentClause(1, acc.Id, precclasueRecordTypeMapByName.get(CONSTANTS.NATIONAL_AGREEMENTS).getRecordTypeId());
        database.insert(precRecord);
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
         List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT Id, StandardReviewType__c,Opportunityid FROM OpportunityLineItem LIMIT 1];
        
        
        Opportunity opportunityRecord = [select id,NationalAgreement__c from Opportunity where id =: opportunityLineItemList[0].Opportunityid limit 1];
        opportunityRecord.NationalAgreement__c = precRecord.Id;
        database.update(opportunityRecord);
        
        System.runAs(testUser) {
            
            Test.startTest();
            for(OpportunityLineItem oppLineItem : opportunityLineItemList){
                oppLineItem.StandardReviewType__c = 'CPI';
            }
            update opportunityLineItemList;
            
            Test.stopTest();
        }
        
        
        
    }       
    public static testMethod void testUpdateSecurityDeposit() {
       
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT Id, UnitPrice FROM OpportunityLineItem LIMIT 1];
        //RUN TEST
        System.runAs(testUser) {
            
            Test.startTest();
            for(OpportunityLineItem oppLineItem : opportunityLineItemList){
                oppLineItem.UnitPrice = 1000;
            }
            update opportunityLineItemList;
            
            Test.stopTest();
        }
        
        
        
        List<Opportunity> assertOpportunityList = new List<Opportunity>([SELECT Id, SecurityDeposit__c FROM Opportunity]);
        
        //ASSERTION
        for(Opportunity opp : assertOpportunityList) {
            System.assertNotEquals(0, opp.SecurityDeposit__c);
        }
    }
    public static testMethod void testUpdateOpportunityLineRecover() {
       
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT isActive__c,Id,Description FROM OpportunityLineItem LIMIT 1];
        List<product2> prod2list = [select id,Family from Product2 limit 1];
        prod2list[0].Family = Constants.RECOVERIES;
        prod2list[0].OutgoingsCategory__c = 'Air Con';
        database.update(prod2list);
        //RUN TEST
        System.runAs(testUser) {
         
            Test.startTest();
            opportunityLineItemList[0].Description = 'test desc12';
            opportunityLineItemList[0].isActive__c = false;
            opportunityLineItemList[0].unitprice = 122;
            database.update(opportunityLineItemList);
            opportunityLineItemList[0].isActive__c = true;
            database.update(opportunityLineItemList);
            Test.stopTest();
        }
    }  
    public static testMethod void testUpdateOpportunityLineFees() {
       
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT isActive__c,Id,Description FROM OpportunityLineItem LIMIT 1];
        List<product2> prod2list = [select id,Family from Product2 limit 1];
        //RUN TEST
        System.runAs(testUser) {
         Test.startTest();
            prod2list[0].Family = Constants.FEES_CHARGES;
            prod2list[0].OutgoingsCategory__c = 'Air Con';
            database.update(prod2list);
            
            opportunityLineItemList[0].Description = 'test desc13';
            opportunityLineItemList[0].isActive__c = false;
            opportunityLineItemList[0].unitprice = 123;
            database.update(opportunityLineItemList);
            opportunityLineItemList[0].isActive__c = true;
            database.update(opportunityLineItemList);

        Test.stopTest();
        }
    }
    public static testMethod void testUpdateOpportunityLineCapital() {
       
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT isActive__c,Id,Description FROM OpportunityLineItem LIMIT 1];
        List<product2> prod2list = [select id,Family from Product2 limit 1];
        //RUN TEST
        System.runAs(testUser) {
         Test.startTest();

            prod2list[0].Family = Constants.CAPITAL;
            prod2list[0].capitalcategory__c = 'Lessor Works';
            database.update(prod2list);
            
            opportunityLineItemList[0].Description = 'test desc14';
            opportunityLineItemList[0].isActive__c = false;
            opportunityLineItemList[0].totalprice = 124;
            database.update(opportunityLineItemList);
            opportunityLineItemList[0].isActive__c = true;
            database.update(opportunityLineItemList);
            
        Test.stopTest();
        }
    }           
    public static testMethod void testDeleteOpportunityLine() {
       
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        
        //RUN TEST
        System.runAs(testUser) {
            
            Test.startTest();
            
            delete opportunityLineItemList;
            
            Test.stopTest();
        }
        
        
        
        List<Opportunity> assertOpportunityList = new List<Opportunity>([SELECT Id, SecurityDeposit__c FROM Opportunity]);
        //ASSERTION
        for(Opportunity opp : assertOpportunityList) {
            System.assertNotEquals(0, opp.SecurityDeposit__c);
        }
    }
    
    /**
     * @author:        Kyle Tan
     **/
    @isTest
    private static void highRiskClauseTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>([SELECT Id, StandardReviewType__c FROM OpportunityLineItem]);
        for(OpportunityLineItem oppLineItemRec :oppLineItemList) {
            oppLineItemRec.StandardReviewType__c = 'NZ CPI+2.0';
        }
        system.runAs(testUser) {
            test.startTest();
            database.update(oppLineItemList[1]);
            test.stopTest();
        }
    }
}