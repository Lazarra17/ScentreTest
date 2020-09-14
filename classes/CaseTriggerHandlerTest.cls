/*
* @author:              Dave Camongol
* @description:         Test class for CaseTriggerHandler
*/
@isTest
public class CaseTriggerHandlerTest{
    
    @TestSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<User> testUserList = new List<User>();
        List<Account> parentAccList = new List<Account>();
        
        Account account = new Account();
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        
        Database.insert(testUserList);    
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, null, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        for(Integer i = 0; i < 10; i++){
            account = TestDataFactory.createAccountwithParent(i, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
            accountList.add(account);
        }
        database.insert(accountList);
        accountList = [SELECT Id, Name FROM Account LIMIT 100];
        
        //CREATE ACCOUNTTEAMMEMBER
        List<AccountTeamMember> AccTeamMemberList = new List<AccountTeamMember>();
        AccountTeamMember AccTeamMemberRec = TestDataFactory.createAccountTeamMember(parentAccList[0].id, testUserList[0].id);
        AccTeamMemberList.add(AccTeamMemberRec);
        database.insert(AccTeamMemberList);
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        database.insert(spaceLst);
        
        contrList = TestDataFactory.createContract(1, account);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
    
        Id internalTeamRecTypeId;
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, constants.TEAM_ROLE_GMLEASING,  testUserList[0].Id, internalTeamRecTypeId);
        database.insert(propteam);
         
        List<Space__c> spaceList = TestDataFactory.createSpace(20, account, propertyList[0], contrList[0]);
        Database.insert(spaceList);
        
        //CREATE PROPERTYTEAM
        Map<String, Schema.RecordTypeInfo> PropertyTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PROPERTYTEAM);
        List<PropertyTeam__c> lstPropertyTeam = new List<PropertyTeam__c>();
        string teamrole = Constants.TEAM_ROLE_RDM;
        PropertyTeam__c PropertyTeamRec = TestDataFactory.createPropertyTeam(propertyList[0].id, teamrole, testUserList[0].id, PropertyTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        //system.debug('Active '+ PropertyTeamRec.Active__c);
        lstPropertyTeam.add(PropertyTeamRec);
        database.insert(lstPropertyTeam);
        //system.debug('Active '+ lstPropertyTeam[0].Active__c);
        //system.debug('EndDate '+ lstPropertyTeam[0].EndDate__c);
        //system.debug('StartDate '+ lstPropertyTeam[0].StartDate__c);
        
        //CREATE Case
        accountList = [SELECT Id, ParentId, Property__c FROM Account WHERE ParentId != null LIMIT 2];
        
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(accountList);
        System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        opportunityList = [SELECT Id FROM Opportunity LIMIT 200];
        Map<String, Schema.RecordTypeInfo> CaseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        
        Case CaseRec11 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId());
        CaseRec11.AccountId = accountList[0].Id;
        CaseRec11.Opportunity__c = opportunityList[0].Id;
        //lstCase.add(CaseRec1);
        insert CaseRec11;
        
        List<Case> lstCase = new List<Case>();
        Case CaseRec1 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.CASE_RECORDTYPE_INSPECTIONREPORT).getRecordTypeId());
        CaseRec1.AccountId = accountList[0].Id;
        CaseRec1.Opportunity__c = opportunityList[0].Id;
        CaseRec1.ParentId = CaseRec11.Id;
        lstCase.add(CaseRec1);
        Case CaseRec2 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.RETAIL_DESIGN_BILLING).getRecordTypeId());
        CaseRec2.AccountId = accountList[0].Id;
        CaseRec2.Opportunity__c = opportunityList[0].Id;
        CaseRec2.ParentId = CaseRec11.Id;
        lstCase.add(CaseRec2);
        Case CaseRec3 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.STATEMENT_OF_COMPLETION).getRecordTypeId());
        CaseRec3.AccountId = accountList[1].Id;
        CaseRec3.Opportunity__c = opportunityList[0].Id;
        CaseRec3.ParentId = CaseRec11.Id;
        lstCase.add(CaseRec3);
        Case CaseRec4 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get(CONSTANTS.LEASING_CHECKSHEET).getRecordTypeId());
        CaseRec4.AccountId = accountList[1].Id;
        CaseRec4.Opportunity__c = opportunityList[0].Id;
        CaseRec4.ParentId = CaseRec11.Id;
        // CaseRec4.Status = CONSTANTS.CASE_STATUS_MANUAL;      // --- code coverage
        lstCase.add(CaseRec4);
        Case CaseRec5 = TestDataFactory.createCase(contrList[0], spaceLst[0], CaseRecordTypeMapByName.get('LVI - COVID19').getRecordTypeId());
        CaseRec5.AccountId = accountList[1].Id;
        CaseRec5.Opportunity__c = opportunityList[0].Id;
        //CaseRec5.ParentId = CaseRec11.Id;
        CaseRec5.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        CaseRec5.Status = 'New';
        CaseRec5.Type = 'LV18 - Miscellaneous';
        //cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('LVI - COVID19').getRecordTypeId();
        lstCase.add(CaseRec5);
        
        database.insert(lstCase);
        
    }
    
    @isTest
    private static void testgetRoleId() {
      List<Contract__c> contrlst = [select id from contract__c limit 1];
      List<Id> contrIdLst = new List<Id>();
      contrIdLst.add(contrlst[0].id);
      CaseBL.getRoleId(contrIdLst,constants.TEAM_ROLE_ACCREVPAYABLES);
    }  
    
    @isTest
    private static void getSpaceDetails() {
        Space__c spaceRec = [SELECT Id,CurrentLease__c from Space__c where CurrentLease__c != null limit 1];
        List<Contract__c> contractList = [SELECT Id, Property__c, Name, Property__r.Name, Space__c, Space__r.Name,
                                            Space__r.CurrentLease__c, Account__r.Name, LeaseEndDate__c,
                                            Account__c, Account__r.ParentId, Opportunity__c
                                          FROM Contract__c 
                                          WHERE Id =: spaceRec.CurrentLease__c limit 1];
        List<Case> CaseList = [Select Id, Contract__c, Space__c, Status, Description, ReviewDate__c, EffectiveDate__c FROM Case limit 3];
        
        List<Id> contractIds = new List<Id>();
        for (Contract__c contract: contractList){
            contractIds.add(contract.id);
        }
        for (Case caserec: CaseList){
            contractIds.add(caserec.id);
        }
        
        List<Case> caseToCreate = new List<Case>();
        List<CaseEvent__e> caseEvents = new List<CaseEvent__e>();
        
        //List Payloads
        List<string> lstPayloads = new List<string>();
        lstPayloads=TestDataFactory.lstPayload(5);
        
        Test.startTest();
            caseToCreate = CaseBL.CreateInspectionforContract(contractList);
            caseEvents = CaseBL.generateCaseEvents(lstPayloads);
            CaseBL.retailDesignBillingCase(contractIds);
            CreateInspectionBatch inspectionBatch = new CreateInspectionBatch(); 
            Id batchId = Database.executeBatch(inspectionBatch);
        Test.stopTest();
        
        System.assertEquals(true, caseToCreate <> null);
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void unlockCaseRecordIdSetTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        system.runAs(testUser) {
            List<Case> caseList = [SELECT Id, Status FROM Case LIMIT 200];
            
            for(Case caseRec : caseList){
                caseRec.Status = 'Invalid Request';
            }
            
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(caseList);
            test.stopTest();
        }
    }
    
    @isTest
    private static void unlockCaseRecordIdSetTestManual() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        system.runAs(testUser) {
            List<Case> caseList = [SELECT Id, Status FROM Case WHERE RecordType.Name!='Inspection Report' LIMIT 200];
            
            for(Case caseRec : caseList){
                caseRec.Status = constants.CASE_STATUS_MANUAL;
            }
            
            test.startTest();
            TriggerHandler.clearAllBypasses();
            database.update(caseList);
            List<Case> casesInManualList = [SELECT Id, Status, ReasonforCancellation__c FROM Case WHERE Status=:constants.CASE_STATUS_MANUAL];
            System.assert(casesInManualList.size() > 0);
            
            casesInManualList[0].OwnerId = testUser.Id;
            TriggerHandler.clearAllBypasses();
            database.update(casesInManualList[0]);
            casesInManualList[0].Status = Constants.CASE_STATUS_COMPLETED_CANCELLED;
            casesInManualList[0].ReasonforCancellation__c = 'Test';
            TriggerHandler.clearAllBypasses();
            update casesInManualList[0];
            System.assertEquals(Constants.CASE_STATUS_COMPLETED_CANCELLED, casesInManualList[0].Status, 'Case Status not changed to Cancelled');
            test.stopTest();
        }
    }
    @isTest
    private static void updateOppRentTerminationDateAndSpaceStatus(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name =: Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Flamingo', profileRec.Id);
        Map<String,Schema.RecordTypeInfo> caseRecordTypeByNameMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        List<Property__c> propertyList = [SELECT Id,Name FROM Property__c LIMIT 1];
        List<Space__c> spaceList = [SELECT Id,Name,CurrentLease__c,Status__c FROM Space__c WHERE Property__c =: propertyList[0].Id LIMIT 1];
        List<Account> accountList = [SELECT Id,Name,Property__c FROM Account WHERE Property__c =: propertyList[0].Id LIMIT 1];
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        List<Contract__c> contractList = TestDataFactory.createContract(1, accountList[0], propertyList[0], opportunityList[0]);
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        database.insert(opportunityList);
        
        TriggerHandler.bypass('ContractTriggerHandler');
        database.insert(contractList);
        
        spaceList[0].CurrentLease__c = contractList[0].Id;
        spaceList[0].Status__c = Constants.SPACE_STATUS_ATRISK;
        spaceList[0].LatestAchievedOpportunity__c = opportunityList[0].Id;
        TriggerHandler.bypass('SpaceTriggerHandler');
        database.update(spaceList);
        
        System.runAs(testUser){
            test.startTest();
                Case newCase = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.TERMINATE_A_LEASE).getRecordTypeId(), contractList[0].Id);
                newCase.Status = Constants.CASE_STATUS_PENDING_APPROVAL;
                newCase.Space__c = spaceList[0].Id;
                newCase.Contract__c = contractList[0].Id;
                newCase.Opportunity__c = opportunityList[0].Id;
                newCase.AccountId = accountList[0].Id;
                newCase.JDESentStatus__c = Constants.OPPO_JDE_STATUS_READY;
                newCase.TechHasChildCase__c = true;
                database.insert(newCase);
            
                Case newCase2 = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.MANAGE_BANK_GUARANTEE).getRecordTypeId(), contractList[0].Id);
                newCase2.ParentId = newCase.Id;
                database.insert(newCase2);
            
                newCase.Status = Constants.CASE_STATUS_APPROVED;
                newCase.TerminateLeaseDate__c = Date.today();
                newCase.Type = Constants.CASE_TYPE_LV04BANK_GUARANTEE;
                database.update(newCase);
            test.stopTest();
        }
    }
    
    @isTest
    private static void populateCaseTeamMembers_test() {
        Map<String,Schema.RecordTypeInfo> caseRecordTypeByNameMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        List<Property__c> propertyList = [SELECT Id,Name FROM Property__c LIMIT 1];
        List<Space__c> spaceList = [SELECT Id,Name,CurrentLease__c,Status__c FROM Space__c WHERE Property__c =: propertyList[0].Id LIMIT 1];
        List<Account> accountList = [SELECT Id,Name,Property__c, Is_National_Account__c FROM Account WHERE Property__c =: propertyList[0].Id LIMIT 1];
        
        for(Account acc : accountList){
            acc.Is_National_Account__c = TRUE;
        }
        update accountList;
        
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        List<Contract__c> contractList = TestDataFactory.createContract(1, accountList[0], propertyList[0], opportunityList[0]);
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        database.insert(opportunityList);
        
        TriggerHandler.bypass('ContractTriggerHandler');
        database.insert(contractList);
        
        spaceList[0].CurrentLease__c = contractList[0].Id;
        spaceList[0].Status__c = Constants.SPACE_STATUS_ATRISK;
        spaceList[0].LatestAchievedOpportunity__c = opportunityList[0].Id;
        TriggerHandler.bypass('SpaceTriggerHandler');
        database.update(spaceList);
        
            test.startTest();
                Case newCase = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.LVI_COVID19).getRecordTypeId(), contractList[0].Id);
                newCase.Status = Constants.CASE_STATUS_PENDING_APPROVAL;
                newCase.Space__c = spaceList[0].Id;
                newCase.Contract__c = contractList[0].Id;
                newCase.Opportunity__c = opportunityList[0].Id;
                newCase.AccountId = accountList[0].Id;
                newCase.JDESentStatus__c = Constants.OPPO_JDE_STATUS_READY;
                newCase.TechHasChildCase__c = true;
        		newCase.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        		newCase.Type = 'LV18 - Miscellaneous';
                database.insert(newCase);
            
                /*Case newCase2 = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.MANAGE_BANK_GUARANTEE).getRecordTypeId(), contractList[0].Id);
                newCase2.ParentId = newCase.Id;
                database.insert(newCase2);
            
                newCase.Status = Constants.CASE_STATUS_APPROVED;
                newCase.TerminateLeaseDate__c = Date.today();
                newCase.Type = Constants.CASE_TYPE_LV04BANK_GUARANTEE;
                database.update(newCase);*/
            test.stopTest();
    }
    
    @isTest
    public static void createTaskForCovidCaseTest(){
        Case cs = [SELECT Id, Status 
                   FROM Case 
                   WHERE SubType__c =: Constants.CASE_SUBTYPE_COVID_RENT_REQUEST
                   AND ParentId = null
                   LIMIT 1];
        
        Test.startTest();
        
        cs.Status = Constants.CASE_STATUS_COMPLETED_REJECTED;
        update cs;
        
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    public static void autoFillRentalDatesOnInsertTest(){
        Map<String,Schema.RecordTypeInfo> caseRecordTypeByNameMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        List<Property__c> propertyList = [SELECT Id,Name FROM Property__c LIMIT 1];
        List<Space__c> spaceList = [SELECT Id,Name,CurrentLease__c,Status__c FROM Space__c WHERE Property__c =: propertyList[0].Id LIMIT 1];
        List<Account> accountList = [SELECT Id,Name,Property__c FROM Account WHERE Property__c =: propertyList[0].Id LIMIT 1];
        List<Opportunity> opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        List<Contract__c> contractList = TestDataFactory.createContract(1, accountList[0], propertyList[0], opportunityList[0]);
        
        //get picklist values from Case
        String casePeriodVal;
        List<String> RentalAsstPeriodValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = case.Rental_Assistance_Period__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			RentalAsstPeriodValuesList.add(pickListVal.getLabel());
		} 
        
        casePeriodVal = RentalAsstPeriodValuesList[0];
        
        Test.startTest();
        	List<Case> caseList = New List<Case>();
            for(Integer i = 0; i < 5; i++){
                Case newCase = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.LVI_COVID19).getRecordTypeId(), contractList[0].Id);
                newCase.Status = Constants.CASE_STATUS_PENDING_APPROVAL;
                newCase.Space__c = spaceList[0].Id;
                newCase.Contract__c = contractList[0].Id;
                newCase.Opportunity__c = opportunityList[0].Id;
                newCase.AccountId = accountList[0].Id;
        		newCase.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        		newCase.Type = 'LV18 - Miscellaneous';
                newCase.Rental_Assistance_Period__c = casePeriodVal;
                newCase.Rental_Assistance_Start_Date__c = NULL;
                newCase.Rental_Assistance_End_Date__c = NULL;
                caseList.add(newCase);    
            }
        
        	database.insert(caseList);
        
        Test.stopTest();
    }
    
    @isTest
    public static void autoFillRentalDatesOnUpdateTest(){
        
        //get picklist values from Case
        String casePeriodVal;
        List<String> RentalAsstPeriodValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = case.Rental_Assistance_Period__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			RentalAsstPeriodValuesList.add(pickListVal.getLabel());
		} 
        
        casePeriodVal = RentalAsstPeriodValuesList[0];
        
        String caseSubtype = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        List<Case> caseList = [Select Id, SubType__c, Type, Rental_Assistance_Period__c, Rental_Assistance_Start_Date__c, Rental_Assistance_End_Date__c 
                              FROM Case
                              WHERE SubType__c =: caseSubtype AND Type = 'LV18 - Miscellaneous']; 
        
        if(caseList.size() > 0){
            for(Case updateCase : caseList){
                updateCase.Rental_Assistance_Period__c = casePeriodVal;
            }
        }
        
        Test.startTest();
        	TriggerHandler.clearAllBypasses();
            database.update(caseList);
        Test.stopTest();
    }
}