/*
* @author:              Kyle Tan
* @description:         Test class for OpportunityTriggerHandler
  @history:
*/
@isTest
private class OpportunityTriggerHandlerTest {
    
    @TestSetup private static void testSetup() { 
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList = new List<Property__c>();
        Pricebook2 standardPricebook = new Pricebook2();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        Account accountRecord = new Account();
        PrecedentClause__c precedentClauseRecord;
        
        //CREATE TEST USERS
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        
        Database.insert(testUserList);
        
        //CREATE STANDARD PRICEBOOK
        standardPricebook = TestDataFactory.createPricebook(1)[0];
        database.insert(standardPricebook); 
        
        
        
        List<Product2> prodList = TestDataFactory.createProduct(3);
        prodList[0].Name = 'Outgoings - Semi Gross';
        prodList[1].Name = Constants.PRODUCT_RENT_REVIEW;
        prodList[2].Name = Constants.PRODUCT_PROMO_REVIEW;
        database.insert(prodList);
        
        PricebookEntry pbStandEntry = TestDataFactory.createStandardPriceBookEntry(1,prodList[0])[0];
        database.insert(pbStandEntry);
        
        PricebookEntry pbStandTemp2 = TestDataFactory.createStandardPriceBookEntry(1,prodList[1])[0];
        database.insert(pbStandTemp2);
        
        PricebookEntry pbStandTemp3 = TestDataFactory.createStandardPriceBookEntry(1,prodList[2])[0];
        database.insert(pbStandTemp3);
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1, standardPricebook);
        propertyList[0].pricebook__c = standardPricebook.id;
        propertyList[0].RentReviewType__c = 'CPI+1.5';
        database.insert(propertyList);
        
        //Create Space
        List<Space__c> spaceLst = TestDataFactory.createSpace(5, propertyList[0]);
        for(Space__c spaceRecord :spaceLst) {
            spaceRecord.Type__c = '4';
        }
        database.insert(spaceLst);
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(100, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
 
        List<Affiliation__c> affList = new List<Affiliation__c>();
        for(Account acc: accountList){
            Affiliation__c affRec = new Affiliation__c();
            affRec.Account__c = acc.Id;
            affRec.PrimaryAffiliationAccount__c = acc.Id;
            affRec.Status__c = 'Current';
            affRec.Type__c = 'Contractor';
            
            affList.add(affRec);
        }
        Database.insert(affList);
        
        tempAccountList = [SELECT Id FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() LIMIT 100];
        accountList = new List<Account>();
        
        for(Integer counter = 0; counter < 100; counter++) {
            accountRecord = TestDataFactory.createAccountwithParent(counter, null, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), tempAccountList.get(counter).Id);
            accountRecord.Property__c = propertyList.get(0).Id;
            accountList.add(accountRecord);
        }
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> sr2 = database.insert(accountList, dml);
        //system.assertnotequals(sr2,sr2);
        
        //CREATE PRECEDENT CLAUSE
        tempAccountList = [SELECT Id FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() LIMIT 100];
        
        for(Integer counter = 0; counter < 100; counter++) {
            if(counter < 80) {
                precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, tempAccountList.get(counter).Id);
            } else {
                precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, tempAccountList.get(counter - 1).Id);
            }
            precedentClauseRecord.SecurityDepositType__c = 'Cash';
            precedentClauseList.add(precedentClauseRecord);
        }
        
        database.insert(precedentClauseList);
        
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>();
        taskTemplateList.add(
            TestDataFactory.createTaskTemplate(
                Constants.OPPORTUNITY, 'Leasing Executive', null, 'Understand & Negotiate', 'Provide Lease Plan', '14 - Provide Lease Plan','',''
            )
        );
        
        taskTemplateList.add(
            TestDataFactory.createTaskTemplate(
                Constants.OPPORTUNITY, 'Retail Administrator', null, 'Approve', 'Add Clauses', '02 - Add Clauses and Special Conditions','',''
            )
        );
        
        taskTemplateList.add(
            TestDataFactory.createTaskTemplate(
                Constants.OPPORTUNITY, 'Retail Administrator', null, 'Approve', 'Add Conditions', '02 - Add Clauses and Special Conditions','',''
            )
        );
        
        Database.insert(taskTemplateList);
        
        Id internalTeamRecTypeId;
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        
        propertyTeamList.add(
            TestDataFactory.createPropertyTeam(propertyList[0].Id, 'Retail Administrator', testUserList[0].Id, internalTeamRecTypeId)
        );
        
        propertyTeamList.add(
            TestDataFactory.createPropertyTeam(propertyList[0].Id, 'Leasing Executive', testUserList[1].Id, internalTeamRecTypeId)
        );
        
        Database.insert(propertyTeamList);
        
        //Create Clause Library
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        clauseLibList.addAll(TestDataFactory.createClauseLibrary(2));
        clauseLibList[0].Name = 'Capped Outgoings';
        clauseLibList[0].Type__c = 'RCA';
        clauseLibList[0].SubType__c = 'Capped Outgoings, statutory charges';
        clauseLibList[0].ClauseDetails__c = 'Rentable != Recoverable';
        database.insert(clauseLibList);
        
        //Create Property Ownership
        List<PropertyOwnership__c> propOwnerList = new List<PropertyOwnership__c>();
        propOwnerList.addAll(TestDataFactory.createPropertyOwnership(1, propertyList[0].Id, accountList[0].Id));
        propOwnerList[0].Type__c = Constants.JV;
        database.insert(propOwnerList);
        
        //Create Space
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        spaceGroupList.add(TestDataFactory.createSpaceGroup(spaceLst[3], spaceLst[4]));
        spaceGroupList[0].EffectiveDate__c = null;
        database.insert(spaceGroupList);
        
    }

    
    /**
* @author:      Kyle Tan
* @description: test if an opportunity clause is created when inserting an opportunity
**/
    public static testMethod void createOppoClauseFromPrecClause() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Account> accountsWithParentList = new List<Account>([SELECT Id, Property__c FROM Account WHERE ParentId != null LIMIT 100]);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        Map<Id, PrecedentClause__c> precedentClauseMap = new Map<Id, PrecedentClause__c>();
        
        for(PrecedentClause__c precedentClauseRecord :[SELECT Id, Name, Type__c, Description__c, Comments__c, EffectiveToDate__c FROM PrecedentClause__c WHERE Account__c != null]) {
            precedentClauseMap.put(precedentClauseRecord.Id, precedentClauseRecord);
        }
        
        opportunityList.addAll(TestDataFactory.createOpportunity(accountsWithParentList));
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            database.insert(opportunityList, false);
            
            Test.stopTest();
            
        }
        
        
        for(OpportunityClause__c opportunityClauseRecord :[SELECT Id, TechPrecedentClauseId__c, Name, Type__c, ClauseDetails__c, LeasingComment__c, EffectiveToDate__c FROM OpportunityClause__c WHERE Opportunity__r.AccountId IN :accountsWithParentList]) {
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Name, opportunityClauseRecord.Name);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Type__c, opportunityClauseRecord.Type__c);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Description__c, opportunityClauseRecord.ClauseDetails__c);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Comments__c, opportunityClauseRecord.LeasingComment__c);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).EffectiveToDate__c, opportunityClauseRecord.EffectiveToDate__c);
        }
    }
    public static testMethod void testAutoCreateOppoProduct() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Account> accountsWithParentList = new List<Account>([SELECT Id FROM Account WHERE ParentId != null LIMIT 100]);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        Map<Id, PrecedentClause__c> precedentClauseMap = new Map<Id, PrecedentClause__c>();
        List<Space__c> spaceLst = [Select id, type__c from Space__c limit 1];
        List<Property__c> propLst = [Select id from Property__c limit 1];
        
        Map<String, Schema.RecordTypeInfo> opportunityRecTypeMap = RecordTypeUtil.getAllRecordTypesByName('Opportunity');
        
        for(PrecedentClause__c precedentClauseRecord :[SELECT Id, Name, Type__c, Description__c, Comments__c, EffectiveToDate__c FROM PrecedentClause__c WHERE Account__c != null]) {
            precedentClauseMap.put(precedentClauseRecord.Id, precedentClauseRecord);
        }
        
        opportunityList.addAll(TestDataFactory.createOpportunity(1, accountsWithParentList[0].id));
        opportunityList[0].Space__c = spaceLst[0].id;
        opportunityList[0].Pricebook2Id = Test.getStandardPricebookId();
        opportunityList[0].Property__c = propLst[0].id;
        opportunityList[0].RecordTypeId = opportunityRecTypeMap.get('Commercial Leasing').getRecordTypeId();
        
        System.runAs(testUser) {
            Test.startTest();
            database.insert(opportunityList);
            Test.stopTest();
        }
        List<OpportunityLineItem> oppLineItemLst = [SELECT Id FROM OpportunityLineItem WHERE Opportunityid IN :opportunityList];
        
    }
    
    public static TestMethod void testAutoTaskCreation(){
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account LIMIT 10]);
        Opportunity oppRecord = new Opportunity();
        Map<String, Schema.RecordTypeInfo> opportunityRecTypeMap = RecordTypeUtil.getAllRecordTypesByName('Opportunity');
        
        for(Account account : accountList){
            oppRecord = TestDataFactory.createOpportunity(1, account.Id)[0];
            oppRecord.Property__c = account.Property__c;
            oppRecord.StageName = 'Understand & Negotiate';
            oppRecord.RecordTypeId = opportunityRecTypeMap.get('Commercial Leasing').getRecordTypeId();
            opportunityList.add(oppRecord);
        }
        
        Test.startTest();
        Database.insert(opportunityList);
        Test.stopTest();
    }
    /**
* @author:          Kyle Tan
* @description:     test method that tests if rent review line item are created
*                   upon insertion of an opportunity and if the national agreement
*                   record is used to get the standard review type
**/
    private static testMethod void reviewTypeFromClause() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        PrecedentClause__c precClauseRec = new PrecedentClause__c();
        List<PrecedentClause__c> precClauseList = new List<PrecedentClause__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        List<Account> childAccount = new List<Account>();
        List<Account> parentAccountList = new List<Account>([SELECT Id FROM Account WHERE ParentId = null]);
        List<PricebookEntry> priceBookEntryList = new List<PriceBookEntry>([SELECT Id, PriceBook2Id FROM PricebookEntry WHERE Name = :Constants.PRODUCT_RENT_REVIEW]);
        Set<Id> oppIdSet = new Set<Id>();
        Map<String, Schema.RecordTypeInfo> precClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        
        //Create National Agreement
        precClauseRec = TestDataFactory.createPrecedentClause(1, parentAccountList[0].Id, precClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
        precClauseRec.PercentageRentPercent__c = 10;
        precClauseRec.Type__c = 'Usage';
        precClauseRec.FitOutPeriod__c = 5;
        precClauseRec.GuaranteesType__c = 'Company with Parent Guarantees';
        precClauseRec.RequiredSecurityDepositMonths__c = 0;
        precClauseRec.RequiredSecurityDepositWeeks__c = 0;
        precClauseRec.RequiredSecurityDepositDays__c = 4;
        precClauseList.add(precClauseRec);
        precClauseRec = TestDataFactory.createPrecedentClause(1, parentAccountList[1].Id, precClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
        precClauseRec.PercentageRentPercent__c = 10;
        precClauseRec.Type__c = 'Usage';
        precClauseRec.FitOutPeriod__c = 5;
        precClauseRec.GuaranteesType__c = 'Company with Parent Guarantees';
        precClauseRec.RequiredSecurityDepositMonths__c = 0;
        precClauseRec.RequiredSecurityDepositWeeks__c = 4;
        precClauseRec.RequiredSecurityDepositDays__c = 0;
        precClauseList.add(precClauseRec);
        TriggerHandler.clearAllBypasses();
        database.insert(precClauseList); 
        
        childAccount = [SELECT Id, Property__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        //opportunityList[0].CurrencyISOCode = 'NZD';		// -- 4/11/19
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
        
        for(Opportunity oppRec : opportunityList) {
            oppRec.TermYr__c = 3;
        }
        
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(opportunityList);
            test.stopTest();
        }
        for(Opportunity oppRec : opportunityList) {
            oppIdSet.add(oppRec.Id);
        }
        for(OpportunityLineItem oppLineItemRec : [SELECT Id, StandardReviewType__c FROM OpportunityLineItem WHERE OpportunityId IN :oppIdSet]) {
            //system.assertEquals(precClauseRec.StandardReviewTypes__c, oppLineItemRec.StandardReviewType__c);
        }
    }
    
    /**
* @author:         Kyle Tan
* @description:    Test whether the standard review type is taken from the property
**/
    private static testMethod void reviewTypeFromProperty() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Account> accountList = new List<Account>([SELECT Id FROM Account WHERE ParentId = null LIMIT 100]);
        List<Property__c> propertyList = new List<Property__c>();
        List<PricebookEntry> priceBookEntryList = new List<PriceBookEntry>([SELECT Id, PriceBook2Id, Product2Id FROM PricebookEntry WHERE Name = :Constants.PRODUCT_RENT_REVIEW]);        
        Set<Id> oppIdSet = new Set<Id>();
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        
        for(Property__c propertyRec : [SELECT Id, RentReviewType__c FROM Property__c]) {
            propertyRec.RentReviewType__c = 'CPI+2.5';
            propertyRec.PriceBook__c = priceBookEntryList[0].PriceBook2Id;
            propertyList.add(propertyRec);
        }
        TriggerHandler.clearAllBypasses();
        database.update(propertyList);
        
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0].Id);
        for(Opportunity oppRec : opportunityList) {
            oppRec.Property__c = propertyList[0].Id;
            oppRec.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
        }
        database.insert(opportunityList);
        
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        oppLineItemList.add(TestDataFactory.createOpportunityLineItem(1, opportunityList[0], priceBookEntryList[0]));
        oppLineItemList.add(TestDataFactory.createOpportunityLineItem(1, opportunityList[0], priceBookEntryList[0]));
        database.insert(oppLineItemList);
        for(Opportunity oppRec : opportunityList) {
            oppRec.TermYr__c = 5;
        }
        
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(opportunityList);
            test.stopTest();
        }
        for(Opportunity oppRec : opportunityList) {
            oppIdSet.add(oppRec.Id);
        }
        for(OpportunityLineItem oppLineItemRec : [SELECT Id, StandardReviewType__c FROM OpportunityLineItem WHERE OpportunityId IN :oppIdSet]) {
            //system.assertEquals('CPI+2.5',oppLineItemRec.StandardReviewType__c);
        }
    }
    
    /**
* @author:         Kyle Tan
* @description:    Test whether a precedent clause is copied down to the oppportunity
*                  as opportunity clause
**/
    private static testMethod void oppClauseFromPrecClause() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        system.runAs(testUser) {
            test.startTest();
            test.stopTest();
        }
    }
    
    private static testMethod void testUpdateProposedStartDate() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Account> accountList = new List<Account>([SELECT Id FROM Account WHERE ParentId = null LIMIT 10]);
        List<Property__c> propertyList = new List<Property__c>();
        List<PricebookEntry> priceBookEntryList = new List<PriceBookEntry>([SELECT Id, PriceBook2Id FROM PricebookEntry WHERE Name = :Constants.PRODUCT_RENT_REVIEW]);        
        Set<Id> oppIdSet = new Set<Id>();
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        
        for(Property__c propertyRec : [SELECT Id, RentReviewType__c FROM Property__c]) {
            propertyRec.RentReviewType__c = 'CPI+2.5';
            propertyRec.PriceBook__c = priceBookEntryList[0].PriceBook2Id;
            propertyList.add(propertyRec);
        }
        TriggerHandler.clearAllBypasses();
        database.update(propertyList);
        
        opportunityList = TestDataFactory.createOpportunity(5, accountList[0].Id);
        for(Opportunity oppRec : opportunityList) {
            oppRec.Property__c = propertyList[0].Id;
            oppRec.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
        }
        database.insert(opportunityList);
        
        for(Opportunity oppRec : opportunityList) {
            oppRec.ProposedStartDate__c = date.today() + 13;
            oppRec.ProposedEndDate__c = date.today() + 26;
        }
        
        system.runAs(testUser) {
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(opportunityList);
            test.stopTest();
        }
        
    }
    
    /**
     * @author:                 Kyle Tan
     **/
    @isTest
    private static void chatterPostOppListTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>([SELECT Id, ChildSpace__c FROM SpaceGroup__c]);
        List<Opportunity> oppList = new List<Opportunity>();
        Space__c spaceRec = [SELECT Id FROM Space__c WHERE Id = :spaceGroupList[0].ChildSpace__c];
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceRec);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId();
        system.runAs(testUser) {
            test.startTest();
            database.insert(oppList);
            TriggerHandler.clearAllBypasses();
            oppList[0].TECH_ReceivedSignedLicenceAgreement__c = true;
            oppList[0].StageName = 'Closed - Completed';
            oppList[0].ApprovalStatus__c = Constants.STRAPPOVALREJ;
            oppList[0].Reason_for_No_Promo_Levy__c = 'test';
            database.update(oppList);
            test.stopTest();
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void newOppClauseListTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<Space__c> spaceList = new List<Space__c>([SELECT Id FROM Space__c]);
        List<Opportunity> oppList = new List<Opportunity>();
        propertyList[0].PropertyState__c = Constants.ACT;
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
        oppList[0].SecurityDepositMonths__c = 1;
        oppList[0].NumberofGuarantors__c = 1;
        oppList[0].SpecialityLeaseType__c = 'Variation to Lease';
        system.runAs(testUser) {
            test.startTest();
            database.update(propertyList);
            TriggerHandler.clearAllBypasses();
            database.insert(oppList);
            TriggerHandler.clearAllBypasses();
            oppList[0].NumberofGuarantors__c = 100;
            database.update(oppList);
            test.stopTest();
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void techJVRequiredTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<Space__c> spaceList = new List<Space__c>([SELECT Id FROM Space__c]);
        List<Opportunity> oppList = new List<Opportunity>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].Type__c = '2';
        database.insert(spaceLst);
        List<Contract__c> contractList = new List<Contract__c>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], null, spaceLst[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
        oppList[0].SecurityDepositMonths__c = 1;
        oppList[0].NumberofGuarantors__c = 1;
        oppList[0].NationalFitoutPeriod__c = 0;
        oppList[0].ProposedHandoverDate__c = date.today();
        oppList[0].FitoutDays__c = 10;
        oppList[0].BestBet__c = false;
        
        system.runAs(testUser) {
            database.insert(oppList);
            TriggerHandler.clearAllBypasses();
            contractList.addAll(TestDataFactory.createContract(1, accountList[0], propertyList[0], oppList[0]));
            database.insert(contractList);
            
            test.startTest();
            
            TriggerHandler.clearAllBypasses();
            oppList[0].Space__c = spaceList[0].Id;
            oppList[0].TECHJVRequired__c = true;
            oppList[0].TECHJVCompleted__c = true;
            oppList[0].ApprovalStatus__c = constants.FINALAPPR_GRANT;
            oppList[0].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId();
            oppList[0].ApprovalStatus__c = constants.STRAPPOVALGRANTED;
            oppList[0].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            oppList[0].AnnualMinimumRent__c = 4000;
            oppList[0].PercentageRentPercent__c = 5;
            oppList[0].BestBet__c = true;
            database.update(oppList);
            oppList[0].SpecialityLeaseType__c = Constants.VARIATION_OF_LEASE;
            oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId();
            oppList[0].ApprovalStatus__c = constants.STRAPPOVALGRANTED;
            oppList[0].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            oppList[0].TECHJVCompleted__c = true;
            oppList[0].TECHJVRequired__c = false;
            database.update(oppList);
            test.stopTest();
        }
    }
    
    @isTest
    private static void techJVRequiredTest_test() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<Space__c> spaceList = new List<Space__c>([SELECT Id FROM Space__c]);
        List<Opportunity> oppList = new List<Opportunity>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].Type__c = '2';
        database.insert(spaceLst);
        List<Contract__c> contractList = new List<Contract__c>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], null, spaceLst[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
        oppList[0].SecurityDepositMonths__c = 1;
        oppList[0].NumberofGuarantors__c = 1;
        oppList[0].NationalFitoutPeriod__c = 0;
        oppList[0].ProposedHandoverDate__c = date.today();
        oppList[0].FitoutDays__c = 10;
        oppList[0].BestBet__c = TRUE;
        system.runAs(testUser) {
            test.startTest();
            database.insert(oppList);
            TriggerHandler.clearAllBypasses();
            contractList.addAll(TestDataFactory.createContract(1, accountList[0], propertyList[0], oppList[0]));
            database.insert(contractList);
            TriggerHandler.clearAllBypasses();
            oppList[0].Space__c = spaceList[0].Id;
            oppList[0].BestBet__c = true;
            database.update(oppList);
            test.stopTest();
        }
    }
    
    
    //added on 23-10-2019
    @isTest
    private static void techJVRequiredTest_test1() {
        
        
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);  //getAccount
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);  //get Property
        //List<Space__c> spaceList = new List<Space__c>([SELECT Id FROM Space__c]);              //get Space
        
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].Type__c = '2';
        database.insert(spaceLst);                                                             //insert space
        
        List<Opportunity> oppList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceLst[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();        
        oppList[0].CurrencyIsoCode = 'NZD';
        oppList[0].ProposedHandoverDate__c = date.today();
        //oppList[0].FitoutDays__c = 10;
        database.insert(oppList);
        
        oppList[0].FitoutDays__c = 10;
        
        System.debug('oppList[0].CurrencyIsoCode >>>' + oppList[0].CurrencyIsoCode);
         {
            test.startTest();
            System.debug('oppList >>>'+oppList);
            database.update(oppList);
            test.stopTest();
        }
    }
    //added on 23-10-2019 */
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void highRiskClauseTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id FROM Property__c]);
        List<Space__c> spaceList = new List<Space__c>([SELECT Id FROM Space__c]);
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>([SELECT Id FROM ClauseLibrary__c]);
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], null, spaceList[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
        test.startTest(); // added here SOQL 101
        database.insert(oppList);
        TriggerHandler.clearAllBypasses();
        
        //Create Opportunity Clause
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        oppClauseList.addAll(TestDataFactory.createOpportunityClause(3, oppList[0], clauseLibList[0]));
        for(OpportunityClause__c oppClauseRec :oppClauseList) {
            oppClauseRec.IsAutomated__c = true;
            oppClauseRec.RiskApplies__c = false;
        }
        database.insert(oppClauseList,false);
        //test.startTest();  removed from here
        TriggerHandler.clearAllBypasses();
        system.runAs(testUser) {
            
            database.update(oppList);
            test.stopTest();
        }
    }
    /**
	* @author:             Lean Flores
	**/
    @isTest
    public static void virtualVacancyInsertTest() {
        Test.startTest();
        
        //List<Opportunity> oppList = [SELECT Id, Space__c, ForecastedRentTerminationDate__c, ForecastRent__c, ForecastRentCommencementDate__c, CurrentLeaseVirtualVacancy__c,
        //                             VirtualVacancyEndDate__c, VirtualVacancyRent__c, VirtualVacancyStartDate__c FROM Opportunity WHERE Space__c != null LIMIT 10];
        List<Id> spaceIdList = new List<Id>();
        Map<Id, Space__c> oppIdSpaceMap = new Map<Id, Space__c>();
        Account acc = [SELECT Id, Property__c FROM Account LIMIT 1];
        Property__c prop = [SELECT Id FROM Property__c WHERE Id =:acc.Property__c LIMIT 1];
        List<Space__c> spaceList = TestDataFactory.createSpace(2, acc, prop);
        spaceList[0].Status__c = Constants.SPACE_STATUS_ATRISK;
        
        spaceList[1].Status__c = Constants.SPACE_STATUS_TRADING;
        insert spaceList;
        
        List<Opportunity> oppList = TestDataFactory.createOpportunity(2, acc);
        oppList[0].ForecastRent__c = 30000;
        oppList[0].ForecastedRentTerminationDate__c = Date.today().addYears(-1);
        oppList[0].ForecastRentCommencementDate__c = Date.today();
        oppList[0].BestBet__c = false;
        oppList[0].CurrentLeaseVirtualVacancy__c = Constants.NO;
        oppList[0].Space__c = spaceList[0].Id;
            
        oppList[1].ForecastRent__c = 30000;
        oppList[1].ForecastedRentTerminationDate__c = Date.today().addYears(-1);
        oppList[1].ForecastRentCommencementDate__c = Date.today();
        oppList[1].BestBet__c = false;
        oppList[1].CurrentLeaseVirtualVacancy__c = 'V_H';
        oppList[1].Space__c = spaceList[1].Id;
        
        insert oppList;
        
        system.assert(oppList.size() > 0, 'No Opportunities test records');
        system.assert(spaceList.size() > 1, 'Need atleast 2 unique spaces');
        
        Map<Id,Space__c> spaceMap = new Map<Id, Space__c>([SELECT Status__c, OccupancyStatus__c FROM Space__c WHERE Id IN:spaceList]);
        
        //system.assertEquals(Constants.SPACE_STATUS_TRADING, spaceMap.get(oppList[0].Space__c).Status__c, 'Space Status should be Trading');
        //system.assertEquals(Constants.SPACE_STATUS_ATRISK, spaceMap.get(oppList[1].Space__c).Status__c, 'Space Status should be At Risk');
        
        oppList = [SELECT Id, Space__c, ForecastedRentTerminationDate__c, ForecastRent__c, ForecastRentCommencementDate__c, CurrentLeaseVirtualVacancy__c,
                   VirtualVacancyEndDate__c, VirtualVacancyRent__c, VirtualVacancyStartDate__c FROM Opportunity WHERE Id IN:oppList ORDER BY Name ASC];
        
        system.assert(oppList[0].VirtualVacancyRent__c == null && oppList[0].VirtualVacancyStartDate__c == null && oppList[0].VirtualVacancyEndDate__c == null, 'VV fields should be null if VV is NO/Empty');
        system.assert(oppList[1].VirtualVacancyRent__c != null && oppList[1].VirtualVacancyStartDate__c != null && oppList[1].VirtualVacancyEndDate__c != null, 'VV fields should be NOT null if VV is NOT NO/Empty');

        // Set Space Status and Occupancy Status
        spaceList[1].Status__c = Constants.SPACE_STATUS_ATRISK;
        spaceList[1].OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LBNT;
        
        spaceList[0].Status__c = Constants.SPACE_STATUS_TRADING;       
        
        update spaceList;
        
        oppList[0].CurrentLeaseVirtualVacancy__c = 'V_H';
        oppList[1].CurrentLeaseVirtualVacancy__c = Constants.NO;
        TriggerHandler.clearAllBypasses();
        update oppList;
        
        oppList = [SELECT Id, Space__c, ForecastedRentTerminationDate__c, ForecastRent__c, ForecastRentCommencementDate__c, CurrentLeaseVirtualVacancy__c,
                   VirtualVacancyEndDate__c, VirtualVacancyRent__c, VirtualVacancyStartDate__c FROM Opportunity WHERE Id IN:oppList ORDER BY Name ASC];
        
        system.assert(oppList[1].VirtualVacancyRent__c == null && oppList[1].VirtualVacancyStartDate__c == null && oppList[1].VirtualVacancyEndDate__c == null, 'VV fields should be null if VV is NO/Empty');
        system.assert(oppList[0].VirtualVacancyRent__c != null && oppList[0].VirtualVacancyStartDate__c != null && oppList[0].VirtualVacancyEndDate__c != null, 'VV fields should be NOT null if VV is NOT NO/Empty');
                
        test.stopTest();
    }
    /**
	* @author: Lean Flores
	**/
    @isTest
    public static void virtualVacancyUpdateTest() {
        Test.startTest();
        Account acc = [SELECT Id, Property__c FROM Account LIMIT 1];
        List<Opportunity> oppList = TestDataFactory.createOpportunity(1, acc);
        oppList[0].ForecastRent__c = 30000;
        oppList[0].ForecastedRentTerminationDate__c = Date.today().addYears(-1);
        oppList[0].ForecastRentCommencementDate__c = Date.today();
        oppList[0].BestBet__c = false;
        oppList[0].CurrentLeaseVirtualVacancy__c = 'V_H';
        
        insert oppList;
        system.assertNotEquals(0, oppList.size());
        
        oppList[0].ForecastRent__c = 300;
        oppList[0].ForecastedRentTerminationDate__c = Date.today().addYears(-2);
        oppList[0].ForecastRentCommencementDate__c = Date.today().addDays(-1);
        oppList[0].VirtualVacancyStartDate__c = Date.today().addYears(-2);
        
        TriggerHandler.clearAllBypasses();
        update oppList;
        oppList = [SELECT CurrentLeaseVirtualVacancy__c, VirtualVacancyRent__c, ForecastRent__c, VirtualVacancyStartDate__c  FROM Opportunity WHERE Id =:oppList[0].Id];
        system.assertEquals('V_H', oppList[0].CurrentLeaseVirtualVacancy__c);
        system.assertEquals(oppList[0].ForecastRent__c, oppList[0].VirtualVacancyRent__c, 'Individual fields should be updated separately');
        //system.assertEquals(Date.today().addYears(-2), oppList[0].VirtualVacancyStartDate__c, 'Individual fields should be updated separately');
        Test.stopTest();
    }
    /**
	* @author: Lean Flores
	**/
    @isTest
    public static void bestBetTest() {
        Test.startTest();
        Account acc = [SELECT Id, Property__c FROM Account LIMIT 1];
        List<Opportunity> oppList = TestDataFactory.createOpportunity(2, acc);
        Property__c prop = [SELECT Id FROM Property__c WHERE Id =:acc.Property__c LIMIT 1];
        List<Space__c> spaceList = TestDataFactory.createSpace(1, acc, prop);

        spaceList[0].Name = 'space1';
        insert spaceList;
        Space__c spa1 = [SELECT Id FROM Space__c WHERE Name='space1' LIMIT 1];
        
        
        for (Opportunity opp : oppList) {
            opp.BestBet__c = true;
            opp.Space__c = spa1.Id;
            
        }
        //TriggerHandler.clearAllBypasses();
        Database.insert(oppList);
        Approval.lock(oppList);
        
        List<Opportunity> newOppList = TestDataFactory.createOpportunity(1, acc);
        
        newOppList[0].Space__c = spa1.Id;
        newOppList[0].BestBet__c = true;
        //TriggerHandler.clearAllBypasses();
        Database.insert(newOppList); 
        
        List<Opportunity> validOppsList = [SELECT Id, Name, BestBet__c, Space__c 
                                           FROM Opportunity 
                                           WHERE IsClosed = FALSE AND BestBet__c = True AND Space__c =:spa1.Id];
        
        Map<Id, List<Opportunity>> spaceIdOpportunityListMap = DatabaseSOQLBank.getActiveOpportunityPerSpace(new Set<Id>{spaceList[0].Id});
        
        Test.stopTest();
        
        //System.assert(validOppsList.size() == 1, 'More than 1 Best bet Opportunity');
    }
     //added on 27-11-2019
    @isTest
    private static void NZOppoTest() {
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY); 
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> propertyList2 = new List<Property__c>();  //27-11-2019
        List<Account> accountList2 = new List<Account>();           //27-11-2019
        Pricebook2 standardPricebookNZ = new Pricebook2();
        
        //CREATE STD PRICEBOOK
        standardPricebookNZ = TestDataFactory.createPricebook(1)[0];
        standardPricebookNZ.CurrencyIsoCode = 'NZD';
        database.insert(standardPricebookNZ);   
        
        //CREATE NZ PROPERTY   27-11-2019
        propertyList2 = TestDataFactory.createProperty(1, standardPricebookNZ);
        propertyList2[0].pricebook__c = standardPricebookNZ.id;
        propertyList2[0].Country__c = 'New Zealand';
        propertyList2[0].RentReviewType__c = 'CPI+1.5';
        database.insert(propertyList2);
        
        /*/CREATE NZ ACCOUNT   27-11-2019
        accountList2 = [SELECT Id, Property__c FROM Account LIMIT 5]; */
        
        //CREATE NZ ACCOUNT
        Account acc = new Account();
            acc.Name = 'Test Account ';
            acc.Type = 'Retailer';
            acc.Property__c = propertyList2[0].Id;
            acc.TradingName__c = 'ABCZ ';
            acc.RecordTypeId = accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId();
            acc.ShippingCountry = 'New Zealand';
            acc.ShippingStreet = '1234 Test Test Test';
            acc.ShippingCity = 'Auckland';
            //acc.ShippingState = 'Queensland';
            acc.ShippingPostalCode = '1234';
            acc.BillingCountry = 'New Zealand';
            acc.BillingStreet = '1234 Test Test Test';
            acc.BillingCity = 'Auckland';
            //acc.BillingState = 'Queensland';
            acc.BillingPostalCode = '1234';
            acc.BillingEmailAddress__c = 'testemailNZ@address.com';
            acc.ACN__c = 'ACN1';
            acc.Category__c = 'S420';
            acc.SuperfineCategory__c = 'S421';
            acc.LesseeName__c = 'Test Lessee NZ';
        insert acc;
        
        //insert space
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList2[0]);
        spaceLst[0].Type__c = '2';
        database.insert(spaceLst); 
        
        //INSERT OPPOERTUNITY
        List<Opportunity> oppList = new List<Opportunity>();
        
        oppList = TestDataFactory.createOpportunity(2, acc, propertyList2[0], spaceLst[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();        
        oppList[0].CurrencyIsoCode = 'NZD';
        oppList[0].ProposedHandoverDate__c = date.today();
        oppList[0].FitoutDays__c = 10;
        oppList[1].ProposedHandoverDate__c = NULL;
        oppList[1].ProposedStartDate__c = date.today();
         {
            test.startTest();
            database.insert(oppList);
            test.stopTest();
        }
    }
    
    //added on 27-11-2019 */
    
   
}