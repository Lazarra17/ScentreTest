@isTest
public class DatabaseSOQLBankTest{
    
    private static Set<Id> propertyIds = new Set<Id>();
    private static List<Id> propertyIdList;
    private static Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
    private static List<Space__c> spaceList;
    private static Account accountRec;
    private static  list<account> accountlist = new list<account>();  
    private static  List<Opportunity> lstOpp = new List<Opportunity>();
    
    
    @TestSetup private static void testSetup() {
        
        //CREATE USER
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id);
        Database.insert(testUser);   
        
        //CREATE PRICEBOOK
        List<Pricebook2> pricebookList1 = TestDataFactory.createPricebook(2);
        database.insert(pricebookList1);
        
        //CREATE PROPERTY
        List <Property__c> propertyList1 = TestDataFactory.createProperty(5, pricebookList1[0]);
        database.insert(propertyList1);
        propertyIds = (new Map<Id,Property__c>([SELECT Id FROM Property__c LIMIT 5])).keySet(); 
        propertyIdList = new List<Id>(propertyIds);
        
        //CREATE PROPERTY_TEAM
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        PropertyTeam__c propTeam = TestDataFactory.createPropertyTeam(propertyIdList[0],constants.TEAM_ROLE_GMLEASING,testUser.Id,propertyTeamRecordTypeMap.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        Database.insert(propTeam);    
        //CREATE Account   
        
        accountRec = TestDataFactory.createAccount(20, propertyIdList[0], accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId());
        accountlist.add(accountRec);
        database.insert(accountlist);
        //accountRec = [SELECT Id, Name FROM Account];
            
        //CREATE Contract
        List<Contract__c> contrList = TestDataFactory.createContract(20, accountRec);
        database.insert(contrList);
        
        
        //CREATE Space
        spaceList = TestDataFactory.createSpace(20, accountRec, propertyList1[0], contrList[0]);
        Database.insert(spaceList);
        spaceList = [SELECT Id, Name,CreateInspectionReport__c FROM Space__c];
        TestDataFactory.createSpaceBudget(5, spaceList[0]);
        
        //CREATE Opportunity
        // property pp = [select id ]
        Map<String, Schema.RecordTypeInfo> OppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OPPORTUNITY);
        lstOpp = TestDataFactory.createIssueLeaseOpportunity(accountlist, pricebookList1[0], spaceList[0],propertyList1[0], OppRecordTypeMapByName.get(CONSTANTS.OPP_RETAIL_LEASING).getRecordTypeId());
        
        //insert lstopp;
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
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, account, propertyList[0], spaceList[0]);
        database.insert(oppList);
        
        //CREATE PRICEBOOK
        pricebookRecord = TestDataFactory.createPricebook();
        database.insert(pricebookRecord);
        pricebookRecord = [SELECT Id FROM Pricebook2 LIMIT 1];
        
        //CREATE PRODUCTS
        productList = TestDataFactory.createProduct(10);
        database.insert(productList);
        
        //CREATE PRICEBOOK ENTRY
        List<Opportunity> oppList2;
        for(Integer i = 0; i < 10; i++) {
            pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[i]));
        }
        propertyList[0].PriceBook__c = TestDataFactory.createStandardPriceBookEntry(1, productList[1])[0].Id;
        oppList2 = TestDataFactory.createOpportunity(1, account, propertyList[0], spaceList[0]);
        database.insert(oppList2);
        database.insert(pricebookEntryList);
        
        //CREATE CLAUSE LIBRARY
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        clauseLibList = TestDataFactory.createClauseLibrary(10);
        database.insert(clauseLibList);
        
        //CREATE OPPORTUNITY CLAUSE
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        oppClauseList = TestDataFactory.createOpportunityClause(10,  oppList[0], clauseLibList[0]);
        oppClauseList[0].TechPrecedentClauseId__c = precedentClauseList[0].Id;
        Database.insert(oppClauseList);  
        
        //Create Task Template
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>();
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Pre-DS REAA Approval', 
                                                                '59 - Pre-DS REAA Approval', 
                                                                'Property Team', 
                                                                'Commercial'));
        database.insert(taskTemplateList);
        //Depedent Task Template
        List<TaskTemplateAndCondition__c> taskTemplateListTemp = new List<TaskTemplateAndCondition__c>();
        taskTemplateListTemp.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                    'Retail Administrator', 
                                                                    taskTemplateList[0].Id, 
                                                                    'Propose & Accept', 
                                                                    'Pre-DS REAA Approval', 
                                                                    '59 - Pre-DS REAA Approval', 
                                                                    'Property Team', 
                                                                    'Commercial'));
        database.insert(taskTemplateListTemp);
        
        //Create Opportunity Line Item
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        oppLineItemList.add(TestDataFactory.createOpportunityLineItem(1, oppList2[0], pricebookEntryList[0]));
        database.insert(oppLineItemList);
        
        //Create Task
        Task taskRec = new Task();
        taskRec.WhatId = oppList2[0].Id;
        database.insert(taskRec);
        
        //Create Space
        List<Space__c> spaceLst = TestDataFactory.createSpace(5, propertyList[0]);
        for(Space__c spaceRecord :spaceLst) {
            spaceRecord.Type__c = '4';
        }
        database.insert(spaceLst);
        
        //Create Space Group
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        spaceGroupList.add(TestDataFactory.createSpaceGroup(spaceLst[3], spaceLst[4]));
        spaceGroupList[0].EffectiveDate__c = null;
        database.insert(spaceGroupList);
        
        //Create PropertyOwnership
        List<PropertyOwnership__c> propertyOwnershipList = TestDataFactory.createPropertyOwnership(5, propertyList.get(0).Id, account.Id);
        database.insert(propertyOwnershipList);
    }
    
    public static testMethod void getPropertyTest () {    
        Test.startTest();
        List<Property__c> propertyList = null;
        propertyList = DatabaseSOQLBank.getProperty(propertyIds);
        System.assertEquals(true, propertyList <> null);
        
        DatabaseSOQLBank.getPropertyOwnership((new Map<Id,Property__c>(propertyList)).keySet());
        
        Test.stopTest();
    }
    
    
    public static testMethod void getAccountTest () {    
        Test.startTest();
        List<Account> accountList = null;
        accountList = DatabaseSOQLBank.getAccount (propertyIds);
        
        System.assertEquals(true, accountList <> null);
        Test.stopTest();
    }
    
    public static testMethod void getPrecedentClauseOfAccountTest () {    
        Test.startTest();
        List<Account> accList = DatabaseSOQLBank.getAccount (propertyIds);
        
        Set<Id> accountIds = (new Map<Id,Account>(accList)).keySet();
        List<Id> accountIdList = new List<Id>(accountIds);
        Id accRecordTypeId = accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId();
        
        
        List<PrecedentClause__c> recList = null;
        recList = DatabaseSOQLBank.getPrecedentClauseOfAccount (accountIdList, accRecordTypeId);
        
        System.assertEquals(true, recList <> null);
        Test.stopTest();
    }
    
    public static testMethod void getProductsToPopulateTest () {    
        Test.startTest();
        List<Product2> recList = null;
        recList = DatabaseSOQLBank.getProductsToPopulate(new List<String>{'test1'});
        
        System.assertEquals(true, recList <> null);
        
        //DatabaseSOQLBank.getProduct('test1');
        
        Test.stopTest();
    }
    
    public static testMethod void getPriceBookEntryTest () {    
        Test.startTest();
        List<PriceBookEntry> recList = new List<PriceBookEntry>();
        recList = DatabaseSOQLBank.getPriceBookEntry (DatabaseSOQLBank.getProductsToPopulate(new List<String>{'test1'}));
        
        System.assertEquals(true, recList <> null);
        
        DatabaseSOQLBank.getStandardPricebookId();
        DatabaseSOQLBank.getPropertyPricebookMap();
        Test.stopTest();
    }
    
    public static testMethod void getOpportunitySpaceMapTest () {    
        Test.startTest();
        Map<Id, Space__c> recList = new Map<Id, Space__c>();
        
        spaceList = [SELECT Id, Name,CreateInspectionReport__c FROM Space__c];
        Set<Id> spaceIds = (new Map<Id,Space__c>(spaceList).keySet());
        List<Id> spaceIdList = new List<Id>(spaceIds );
        
        recList = DatabaseSOQLBank.getOpportunitySpaceMap(spaceIdList);
        
        System.assertEquals(true, recList <> null);
        
        DatabaseSOQLBank.getSpaces(spaceIds);
        DatabaseSOQLBank.getMaxSpaceGroupNumber();
        
        propertyIds = (new Map<Id,Property__c>([SELECT Id FROM Property__c LIMIT 5])).keySet(); 
        propertyIdList = new List<Id>(propertyIds);
        DatabaseSOQLBank.getActiveSpaces(propertyIdList[0]);
        DatabaseSOQLBank.getSpaceBudget(spaceIds);
        
        Test.stopTest();
    }
    
    public static testMethod void getOpportunityDealTypeSetTest () {    
        set<id> oppid = new set<id>();
        for(opportunity ops: lstopp){
            oppid.add(ops.id);
        }
        
        Test.startTest();
        
        DatabaseSOQLBank.getOpportunityDealTypeSet();
        DatabaseSOQLBank.getOpportunityLineItemAggregate([Select Id from Opportunity]);
        //  DatabaseSOQLBank.getOpportunityMap(oppid);
        //  DatabaseSOQLBank.getOpportunity(oppid);
        //  DatabaseSOQLBank.getAccountByPrecedentClause 
        //  DatabaseSOQLBank.getReviewRecord();
        
        Test.stopTest();
    }
    
    
    public static testMethod void getTaskTest () {    
        Test.startTest();
        
        
        //DatabaseSOQLBank.getTask();
        
        
        Test.stopTest();
    }
    public static testMethod void MyTestMethod () {    
        Test.startTest();
        
        List<Opportunity> oppList = [Select Id from Opportunity];
        Set<ID> oppSetIds =  (new Map<Id,Opportunity>(oppList)).keySet();
        
        Account accountRec = [SELECT Id, Property__c from Account LIMIT 1];
        Set<ID> accSetIds =  new Set<ID>();
        accSetIds.add(accountRec.Id);
        
        
        DatabaseSOQLBank.getOpportunityLineItemAggregate(oppList);
        DatabaseSOQLBank.getOpportunityMap(oppSetIds);
        DatabaseSOQLBank.getOpportunity(accSetIds);
        DatabaseSOQLBank.getAccountByPrecedentClause(accSetIds);
        DatabaseSOQLBank.getReviewRecord(oppSetIds);
        
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Name, Product2Id FROM PriceBookEntry];
        Set<ID> pbeSetIds =  (new Map<Id,PricebookEntry>(pbeList)).keySet();
        DatabaseSOQLBank.getPriceBookEntry(pbeSetIds, pbeList[0].Name );
        
        Test.stopTest();
    }
    
    public static testMethod void getOpportunityClauseTest() {
        Set<Id> precClauseIdSet = new Set<Id>();
        for(OpportunityClause__c oppClauseRec : [SELECT TechPrecedentClauseId__c FROM OpportunityClause__c WHERE TechPrecedentClauseId__c != null]) {
            precClauseIdSet.add(oppClauseRec.TechPrecedentClauseId__c);
        }
        test.startTest();
        DatabaseSOQLBank.getOpportunityClause(precClauseIdSet);
        test.stopTest();
    }
    
    public static testMethod void getProductTest() {
        test.startTest();
        DatabaseSOQLBank.getProduct(Constants.PRODUCT_RENT_REVIEW);
        test.stopTest();
    }
    
    public static testMethod void getChildTaskTemplateTest() {
        Map<Id, TaskTemplateAndCondition__c> taskTemplateMap = new Map<Id, TaskTemplateAndCondition__c>([SELECT Id FROM TaskTemplateAndCondition__c]);
        test.startTest();
        DatabaseSOQLBank.getChildTaskTemplate('Opportunity', taskTemplateMap.keySet());
        test.stopTest();
    }
    
    public static testMethod void getOpportunityLineItemTest() {
        List<OpportunityLineItem> oppLineItemList = [SELECT Id, OpportunityId, Product2Id, Product2.Family, PriceBookEntry.Pricebook2Id FROM OpportunityLineItem WHERE OpportunityId != null AND Product2Id != null];
        test.startTest();
        DatabaseSOQLBank.getOpportunityLineItem(oppLineItemList[0].OpportunityId, oppLineItemList[0].Product2Id);
        DatabaseSOQLBank.getOpportunityLineItem(oppLineItemList[0].Product2.Family, oppLineItemList[0].Product2Id, oppLineItemList[0].OpportunityId);
        DatabaseSOQLBank.getOpportunity(oppLineItemList[0].OpportunityId);
        test.stopTest();
    }
    
    public static testMethod void getFlexiOppLineItemsTest() {
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        for(OpportunityLineItem oppLineItemRec :[SELECT Id, OpportunityId, Product2Id FROM OpportunityLineItem WHERE OpportunityId != null AND Product2Id != null]) {
            oppIdSet.add(oppLineItemRec.OpportunityId);
            productIdSet.add(oppLineItemRec.Product2Id);
        }
        test.startTest();
        DatabaseSOQLBank.getFlexiOppLineItems(oppIdSet, productIdSet);
        test.stopTest();
    }
    
    public static testMethod void getPricebookEntryTest2() {
        List<PricebookEntry> pricebookEntryList = [SELECT Product2.Family, Pricebook2Id FROM PricebookEntry WHERE Product2.DealType__c != null];
        test.startTest();
        DatabaseSOQLBank.getPricebookEntry(pricebookEntryList[0].Product2.Family, pricebookEntryList[0].Pricebook2Id);
        test.stopTest();
    }
    
    public static testMethod void getProfileTest() {
        Profile profileRec = [SELECT Id FROM Profile LIMIT 1];
        test.startTest();
        DatabaseSOQLBank.getProfile(profileRec.Id);
        test.stopTest();
    }
    
    public static testMethod void getContentVersionTest() {
        //Create Content Version
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        contentVersionList.add(TestDataFactory.createContentVersion('Lease Plan Test File', 'Plans', 'Lease Plan'));
        database.insert(contentVersionList);
        Set<Id> documentIdSet;
        for(ContentVersion contentVersionRec : contentVersionList) {
            if(contentVersionRec.ContentDocumentId != null) {
                documentIdSet.add(contentVersionRec.ContentDocumentId);
            }
        }
        test.startTest();
        DatabaseSOQLBank.getContentVersion(documentIdSet);
        test.stopTest();
    }
    
    public static testMethod void getTasksTest() {
        List<Task> taskList = [SELECT Id, WhatId FROM Task WHERE WhatId != null];
        Set<Id> oppIdSet = new Set<Id>();
        for(Task taskRec : taskList) {
            oppIdSet.add(taskRec.WhatId);
        }
        test.startTest();
        DatabaseSOQLBank.getTask(taskList[0].Id);
        DatabaseSOQLBank.getTasks(oppIdSet);
        test.stopTest();
    }
    
    public static testMethod void getTaskTemplateByStageTest() {
        List<TaskTemplateAndCondition__c> taskTemplateList = [SELECT Id, BusinessUnit__c, Object__c FROM TaskTemplateAndCondition__c WHERE BusinessUnit__c != null];
        test.startTest();
        DatabaseSOQLBank.getTaskTemplateByStage(taskTemplateList[0].BusinessUnit__c);
        DatabaseSOQLBank.getTaskTemplateByBusUnit(taskTemplateList[0].BusinessUnit__c);
        DatabaseSOQLBank.getTaskTemplate(taskTemplateList[0].Object__c);
        test.stopTest();
        System.debug('');
    }
    
    public static testMethod void getOpportunityByAccountIdAndStageNameTest() {
        accountlist = [SELECT Id, TenantNo__c FROM Account LIMIT 10];
        Set<Id> accSetIds = (new Map<Id, Account>(accountlist)).keySet();
        for (Integer i=0; i<accountlist.size();i++) {
            accountlist[i].TenantNo__c = String.valueOf(i).leftPad(4,'0');
        }
        //update accountlist;
        
        test.startTest();
        Set<Id> accountIdsDedup = DatabaseSOQLBank.getOpportunityByAccountIdAndStageName(accSetIds);
        test.stopTest();
        
    }
    
    public static testMethod void getOpportunityTest() {
        spaceList = [SELECT Id FROM Space__c];
        Set<Id> spaceSetIds = (new Map<Id, Space__c>(spaceList)).keySet();
        
        test.startTest();
        Map<Id, List<Opportunity>> spaceIdOpportunityListMap = DatabaseSOQLBank.getActiveOpportunityPerSpace(spaceSetIds);
        test.stopTest();
    }
    
    public static testMethod void getSpaceGroupTest() {
        Set<Id> childSpaceSetIds = new Set<Id>();
        Set<Decimal> spaceGroupNumberSet =  new Set<Decimal>();
        for (SpaceGroup__c sg : [SELECT Id, ChildSpace__c, SpaceGroupNumber__c FROM SpaceGroup__c WHERE ChildSpace__c!='']) {
            childSpaceSetIds.add(sg.ChildSpace__c);
            spaceGroupNumberSet.add(sg.SpaceGroupNumber__c);
        }
        
        test.startTest();
        DatabaseSOQLBank.getSpaceGroupOfChildSpace(childSpaceSetIds);
        DatabaseSOQLBank.getSpaceGroupBySpaceGroupNumber(spaceGroupNumberSet);
        test.stopTest();
    }
    
    public static testMethod void getMatrixMetadataTest() {
		test.startTest();
        Map<String, Map<String, String>> approvalMatrixMap = DatabaseSOQLBank.getApprovalMatrixMetadata();
        test.stopTest();
        
        System.assert(approvalMatrixMap <> null);
        
    }
    
    public static testMethod void getPropertyTeamTest() {
        
        propertyIds = (new Map<Id,Property__c>([SELECT Id FROM Property__c LIMIT 5])).keySet(); 
        propertyIdList = new List<Id>(propertyIds);
        DatabaseSOQLBank.getActiveSpaces(propertyIdList[0]);
        
        test.startTest();
        DatabaseSOQLBank.getPropertyTeam(propertyIds);
        DatabaseSOQLBank.getPropertyTeamByProperty(propertyIds);
        test.stopTest();
    }
    public static testMethod void getOpportunitiesOfAccountTest() {
        
        Set<Id> accIdSet = (new Map<Id,Account>([SELECT Id FROM Account LIMIT 5])).keySet(); 
        
        
        test.startTest();
        DatabaseSOQLBank.getOpportunitiesOfAccount(accIdSet);
        test.stopTest();
    }
    
    public static testMethod void getPrepareCounterOfferTasksTest() {
        
        Set<Id> accIdSet = (new Map<Id,Account>([SELECT Id FROM Account LIMIT 5])).keySet(); 
        
        test.startTest();
        DatabaseSOQLBank.getPrepareCounterOfferTasks(accIdSet);
        test.stopTest();
    }
    
    public static testMethod void getOpportunityClauseListForStandardResponseTest() {
        Set<Id> oppIdSet = (new Map<Id,Opportunity>([SELECT Id FROM Opportunity LIMIT 5])).keySet(); 
        
        test.startTest();
        DatabaseSOQLBank.getOpportunityClauseListForStandardResponse(oppIdSet);
        test.stopTest();  
    }
    
    public static testMethod void getOppContactRoleListByAccountTest() {
        
        Set<Id> accIdSet = (new Map<Id,Account>([SELECT Id FROM Account LIMIT 5])).keySet(); 
        
        test.startTest();
        DatabaseSOQLBank.getOppContactRoleListByAccount(accIdSet);
        test.stopTest();
    }
    
    public static testMethod void getAccountListTest() {
        
        test.startTest();
        DatabaseSOQLBank.getAccountList('Test', 'Test');
        test.stopTest();
    }
    public static testMethod void getChildCaseTest() {
        
        Set<Id> caseIdSet = (new Map<Id,Case>([SELECT Id FROM Case WHERE ParentId=null LIMIT 5])).keySet();
        
        test.startTest();
        DatabaseSOQLBank.getChildCase(caseIdSet);
        test.stopTest();
    }
    
    public static testMethod void getSpacesOfPropertyTest() {
        
        Set<Id> propIdSet = (new Map<Id,Property__c>([SELECT Id FROM Property__c LIMIT 5])).keySet();
        
        test.startTest();
        DatabaseSOQLBank.getSpacesOfProperty(propIdSet);
        test.stopTest();
    }
    
    public static testMethod void getCaseTest() {
        Set<Id> caseIdSet = (new Map<Id,Case>([SELECT Id FROM Case LIMIT 5])).keySet();
        
        test.startTest();
        DatabaseSOQLBank.getCase(caseIdSet);
        test.stopTest();
    }
    
    public static testMethod void getOppConRolesMapTest() {
        
        Set<String> rolesSet = new Set<String>{Constants.COMP_PERSONAL_GUARANTEES, Constants.COMP_PARENT_GUARANTEES, Constants.PERSONAL_GUARANTEES_FRANCHISEE};
        Set<Id> oppIdSet = (new Map<Id,Opportunity>([SELECT Id FROM Opportunity LIMIT 5])).keySet(); 
        
        test.startTest();
        DatabaseSOQLBank.getOppConRolesMap(oppIdSet, rolesSet);
        test.stopTest();
    }        
}