@isTest
public class CaseMilestoneTest {
    
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
        
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        database.insert(spaceLst);
    }
    
    @isTest
    private static void updateCaseMilestoneTest(){
        
        Map<String,Schema.RecordTypeInfo> caseRecordTypeByNameMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        
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
        Case newCase = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.LVI_COVID19).getRecordTypeId(), contractList[0].Id);
        newCase.Status = Constants.CASE_STATUS_PENDING_APPROVAL;
        newCase.Space__c = spaceList[0].Id;
        //newCase.Contract__c = contractList[0].Id;
        //newCase.Opportunity__c = opportunityList[0].Id;
        newCase.AccountId = accountList[0].Id;
        newCase.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        newCase.Type = 'LV18 - Miscellaneous';
        newCase.Rental_Assistance_Period__c = casePeriodVal;
        newCase.Rental_Assistance_Start_Date__c = NULL;
        newCase.Rental_Assistance_End_Date__c = NULL;
        
        caseList.add(newCase);    
        TriggerHandler.bypass('CaseTriggerHandler');
        database.insert(caseList);
        
        Task tsk = new Task();
        tsk.Status = 'New';
        tsk.TaskType__c =  Constants.TASKTEMPLATE_GENERATE_OFFER_LETTER;
        tsk.Case__c = caseList[0].Id;
        tsk.WhatId = caseList[0].Id;
        tsk.RecordTypeId = taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId();
        insert tsk;
        
        TriggerHandler.clearAllBypasses();
        
        Map<Id, Task> oldMap = new Map<Id, Task>();
        oldMap.put(tsk.Id, tsk);
        
        tsk.status = 'Completed';
        update tsk;
                
        List<Task> newList = new List<Task>();
        newList.add(tsk);
        
        //CaseMilestoneHandler.getCovidCasesMap(oldMap, newList);
        //CaseMilestoneHandler.updateCaseMilestone(tsk, tsk, caseList[0]);
        
        Test.stopTest();
    }
    
    @isTest
    private static void updateMilestoneBatch(){
        
        Map<String,Schema.RecordTypeInfo> caseRecordTypeByNameMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        
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
        Case newCase = TestDataFactory.CreateCase(accountList[0], caseRecordTypeByNameMap.get(Constants.LVI_COVID19).getRecordTypeId(), contractList[0].Id);
        newCase.Status = Constants.CASE_STATUS_PENDING_APPROVAL;
        newCase.Space__c = spaceList[0].Id;
        //newCase.Contract__c = contractList[0].Id;
        //newCase.Opportunity__c = opportunityList[0].Id;
        newCase.AccountId = accountList[0].Id;
        newCase.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        newCase.Type = 'LV18 - Miscellaneous';
        newCase.Rental_Assistance_Period__c = casePeriodVal;
        newCase.Rental_Assistance_Start_Date__c = NULL;
        newCase.Rental_Assistance_End_Date__c = NULL;
        
        caseList.add(newCase);    
        TriggerHandler.bypass('CaseTriggerHandler');
        database.insert(caseList);
        
        List<Task> tasksToInsert = new List<Task>();
        
        Task tsk = new Task();
        tsk.Status = 'New';
        tsk.TaskType__c =  Constants.TASKTEMPLATE_GENERATE_OFFER_LETTER;
        tsk.Case__c = caseList[0].Id;
        tsk.WhatId = caseList[0].Id;
        tsk.RecordTypeId = taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId();
        
        Task tsk1 = new Task();
        tsk1.Status = 'New';
        tsk1.TaskType__c =  Constants.TASKTEMPLATE_ISSUE_OFFER_LETTER;
        tsk1.Case__c = caseList[0].Id;
        tsk1.WhatId = caseList[0].Id;
        tsk1.RecordTypeId = taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId();
        
        Task tsk2 = new Task();
        tsk2.Status = 'New';
        tsk2.TaskType__c =  Constants.TASKTEMPLATE_ACCEPT_OFFER_LETTER;
        tsk2.Case__c = caseList[0].Id;
        tsk2.WhatId = caseList[0].Id;
        tsk2.RecordTypeId = taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId();
        
        tasksToInsert.add(tsk);
        tasksToInsert.add(tsk1);
        tasksToInsert.add(tsk2);
        
        insert tasksToInsert;
        
        TriggerHandler.clearAllBypasses();
              
        List<Task> tasksToUpdate = new List<Task>();
        
        tsk.status = 'Completed';
                
        tsk1.status = 'Completed';
                
        tsk2.status = 'Completed';
        
        tasksToUpdate.add(tsk);
        tasksToUpdate.add(tsk1);
        tasksToUpdate.add(tsk2);
        
        update tasksToUpdate;
                
        
        TriggerHandler.bypass('CaseTriggerHandler');
        newCase.Milestone__c = NULL;
        update newCase;
        
        //UpdateCaseMilestones obj = new UpdateCaseMilestones();
        //Database.executeBatch(obj);
        String CRON_EXP = '0 0 0 3 9 ? 2022';
		
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new UpdateCaseMilestones());
        
        Test.stopTest();
    }
}