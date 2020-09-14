@isTest
public class OpportunityReversalTest{
    
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
        
        tempAccountList = [SELECT Id FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() LIMIT 100];
        accountList = new List<Account>();
        
        for(Integer counter = 0; counter < 100; counter++) {
            accountRecord = TestDataFactory.createAccountwithParent(counter, null, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), tempAccountList.get(counter).Id);
            accountRecord.Property__c = propertyList.get(0).Id;
            //accountRecord.Pre_Qualification__c = 'Not Required';
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
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest()    {
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
        
        

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].PercentageRentPercent__c = 3;
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'Completed';
        t.TaskType__c = '39 - Instruct Solicitor';
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        OpportunityReversal.getOppty(opportunityList[0].Id);
        OpportunityReversal.createTaskOnnewOpptyReversal(opportunityList[0]);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest_1()    {
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
        
        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
            tempOpp.LatestCompletedMilestone__c = Constants.Opp_Send_DISCLOSURE_STATEMENT;
        }
        database.insert(opportunityList);
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].LatestCompletedMilestone__c = 'Initial Approval';
        opportunityList[0].PercentageRentPercent__c = 3;
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'New';
        t.TaskType__c = Constants.RECEIVE_DISCLOSURE_STATEMENT;
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        OpportunityReversal.getOppty(opportunityList[0].Id);
        OpportunityReversal.createTaskOnnewOpptyReversal(opportunityList[0]);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest_2()    {
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
        
        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
            tempOpp.LatestCompletedMilestone__c = Constants.Opp_RECEIVE_DISCLOSURE_STATEMENT;
        }
        database.insert(opportunityList);
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].LatestCompletedMilestone__c = 'Initial Approval';
        opportunityList[0].PercentageRentPercent__c = 3;
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'New';
        t.TaskType__c = Constants.ACCEPT_DISCLOSURE_STATEMENT_API;
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        OpportunityReversal.getOppty(opportunityList[0].Id);
        OpportunityReversal.createTaskOnnewOpptyReversal(opportunityList[0]);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest_3s(){
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

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
            tempOpp.LatestCompletedMilestone__c = 'Initial Approval';
        }
        database.insert(opportunityList);
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].LatestCompletedMilestone__c = 'Initial Approval';
        opportunityList[0].PercentageRentPercent__c = 3;
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'New';
        t.TaskType__c = Constants.SEND_DISCLOSURE_STATEMENT;
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        OpportunityReversal.getOppty(opportunityList[0].Id);
        OpportunityReversal.createTaskOnnewOpptyReversal(opportunityList[0]);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest_4(){
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

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
            tempOpp.LatestCompletedMilestone__c = Constants.DEAL_ACHIEVED;
        }
        database.insert(opportunityList);
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].LatestCompletedMilestone__c = 'Initial Approval';
        opportunityList[0].PercentageRentPercent__c = 3;
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'New';
        t.TaskType__c = Constants.GENERATE_ACCEPTANCE;
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        OpportunityReversal.getOppty(opportunityList[0].Id);
        OpportunityReversal.createTaskOnnewOpptyReversal(opportunityList[0]);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest1(){
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
        
        

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id;        
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].PercentageRentPercent__c = 3;
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'Completed';
        //t.TaskType__c = '39 - Instruct Solicitor';
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest2(){
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
        
        

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id; 
        
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].ApprovalStatus__c = 'Final Approval Granted';
        opportunityList[0].PercentageRentPercent__c = 3;
        opportunityList[0].ProposedStartDate__c = System.today();
        opportunityList[0].ProposedRentCommencementDate__c = System.today();
        opportunityList[0].RentInAdvance__c = 10000;
        opportunityList[0].SecurityDeposit__c = 5000;
        opportunityList[0].TechByPassOnClone__c = TRUE;
        opportunityList[0].PromoLevyIncluded__c = 'N/A';
               
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'Completed';
        //t.TaskType__c = '39 - Instruct Solicitor';
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        upsert opportunityList[0];
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest3(){
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
        
        

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id; 
        
        opportunityList[0].StageName = 'Initial Approval Granted';
        opportunityList[0].ApprovalStatus__c = 'Initial Approval Granted';
        opportunityList[0].PercentageRentPercent__c = 3;
        opportunityList[0].ProposedStartDate__c = System.today();
        opportunityList[0].ProposedRentCommencementDate__c = System.today();
        opportunityList[0].RentInAdvance__c = 10000;
        opportunityList[0].SecurityDeposit__c = 5000;
        opportunityList[0].TechByPassOnClone__c = TRUE;
        opportunityList[0].PromoLevyIncluded__c = 'N/A';
               
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
                
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'Completed';
        //t.TaskType__c = '39 - Instruct Solicitor';
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        upsert opportunityList[0];
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest4(){
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
        
        

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id; 
        
        opportunityList[0].PercentageRentPercent__c = 3;
        opportunityList[0].ProposedStartDate__c = System.today();
        opportunityList[0].ProposedRentCommencementDate__c = System.today();
        opportunityList[0].RentInAdvance__c = 10000;
        opportunityList[0].SecurityDeposit__c = 5000;
        opportunityList[0].TechByPassOnClone__c = TRUE;
               
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
        
        
        
        //insert opportunityList[0];
        
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'Completed';
        //t.TaskType__c = '39 - Instruct Solicitor';
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        Test.stopTest();
    }
    
    @isTest
    private static void createTaskOnnewOpptyReversalTest5(){
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
        
        

        childAccount = [SELECT Id, Property__c, Property__r.Country__c, Property__r.PropertyCity__c FROM Account WHERE ParentId = :parentAccountList[0].Id OR ParentId = :parentAccountList[1].Id];
        System.debug('Child Account ' + childAccount);
        
        opportunityList = TestDataFactory.createOpportunity(5, childAccount[0].Id);
        opportunityList[1].AccountId = childAccount[1].Id; 
        
        opportunityList[0].PercentageRentPercent__c = 3;
        opportunityList[0].ProposedStartDate__c = System.today();
        opportunityList[0].ProposedRentCommencementDate__c = System.today();
        opportunityList[0].RentInAdvance__c = 10000;
        opportunityList[0].SecurityDeposit__c = 5000;
        opportunityList[0].TechByPassOnClone__c = TRUE;
               
        for(Opportunity tempOpp : opportunityList) {
            tempOpp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            tempOpp.Pricebook2Id = priceBookEntryList[0].PriceBook2Id;
            tempOpp.Property__c = childAccount[0].Property__c;
            tempOpp.AnnualMinimumRent__c = 10000;
        }
        database.insert(opportunityList);
                
        Task t = new Task();
        t.subject = 'Test Subject';
        t.Status = 'Completed';
        t.WHATID = opportunityList[0].Id;
        insert t;
        
        Test.startTest();
        OpportunityReversal.reverseOpportunity(opportunityList[0].Id);
        Test.stopTest();
    }
    
    public static void method1(){
        OpportunityReversal opp = new OpportunityReversal();
        //opp.Response res = new opp.Response();
    }
}