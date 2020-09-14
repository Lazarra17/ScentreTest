/**
* @author          : Yana Navarro
* @desc            : Test class for TaskTriggerHandler
**/
@isTest
private class TaskTriggerHandlerTest {
    
    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        Map<String, Schema.RecordTypeInfo> opportuntiyRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        Map<String, Schema.RecordTypeInfo> propTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PROPERTY_TEAM_API);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        dml.optAllOrNone = true;
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        Account gLevelAccount = TestDataFactory.createAccountBulk(1, null, accountRecordTypeMapByName.get(Constants.GROUP_LEVEL).getRecordTypeId())[0];
        Database.insert(gLevelAccount);
        
        List<Account> childAccountList = new List<Account>();
        childAccountList = TestDataFactory.createAccountBulk(2, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(childAccountList, dml);
        
        childAccountList[0].ParentId = childAccountList[1].Id;
        childAccountList[1].ParentId = gLevelAccount.Id;
        
        TriggerHandler.bypass('AccountTriggerHandler');
        database.update(childAccountList, dml);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(2, propertyList[0]);
        spaceList[0].Type__c = '1';
        spaceList[1].Type__c = '4';
        database.insert(spaceList);
        
        //Create Users
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        database.insert(testUserList);
        
        //Create Property Team
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        propertyTeamList.add(TestDataFactory.createPropertyTeam(
            propertyList[0].Id, 
            'Administration Manager', 
            testUserList[0].Id, 
            propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId())
                            );
        
        propertyTeamList.add(TestDataFactory.createPropertyTeam(
            propertyList[0].Id, 
            'Administration Manager', 
            testUserList[1].Id, 
            propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId())
                            );
        database.insert(propertyTeamList);
        
        //Create Opportunity
        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList = TestDataFactory.createOpportunity(3, childAccountList[0], propertyList[0], spaceList[0]);
        opportunityList[0].RecordTypeId = opportuntiyRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
        opportunityList[1].RecordTypeId = opportuntiyRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
        opportunityList[2].RecordTypeId = opportuntiyRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId();
        opportunityList[2].Space__c = spaceList[1].Id;
        opportunityList[0].BestBet__c = true;
        database.insert(opportunityList);
        
        //CREATE CLAUSE LIBRARY
        List<ClauseLibrary__c> clauseLibList = TestDataFactory.createClauseLibrary(1);
        Database.insert(clauseLibList);
        
        //CREATE OPPORTUNITY CLAUSE
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        
        for(Opportunity opp : opportunityList){
            oppClauseList.addAll(
                TestDataFactory.createOpportunityClause(1, opp, clauseLibList[0])
            );
        }
        
        Database.insert(oppClauseList);     
        
        for(Opportunity opp : opportunityList){
            opp.BestBet__c = false;
            if(opp.RecordTypeId == opportuntiyRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId()){
                opp.StageName = 'Propose & Accept';
                opp.AnnualMinimumRent__c = 1000000;
                opp.PercentageRentPercent__c = 10;
                opp.ApprovalStatus__c = 'Final Approval Granted';
                opp.TermYr__c = 0;
                opp.TermMonths__c = 6;
                opp.PromoLevyIncluded__c = 'No';
                opp.Type = 'New Lease';
            }
        }
        TriggerHandler.bypass('OpportunityTriggerHandler');
        //database.update(opportunityList);
        
        //Create Task Template
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>();
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Send Disclosure Statement', 
                                                                '22 - Send Disclosure Statement', 
                                                                'Property Team', 
                                                                'Retail'));
        
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Task', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Send Documents for Execution', 
                                                                '23 - Send Documents for Execution', 
                                                                'Property Team', 
                                                                'Retail'));
        
        taskTemplateList.add(TestDataFactory.createCaseTaskTemplate('Case', 
                                                                    'Retail Administrator', 
                                                                    'Conditions of Assignment', 
                                                                    '46 - Conditions of Assignment',
                                                                    'Property Team', 
                                                                    Constants.ASSIGN_OF_A_LEASE, 
                                                                    null));
        
        taskTemplateList.add(TestDataFactory.createCaseTaskTemplate('Task', 
                                                                    'Retail Administrator', 
                                                                    'Send Documents for Execution', 
                                                                    '23 - Send Documents for Execution',
                                                                    'Property Team', 
                                                                    Constants.ASSIGN_OF_A_LEASE, 
                                                                    null));
        
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Send Documents for Execution', 
                                                                '23 - Send Documents for Execution', 
                                                                'Property Team', 
                                                                'Commercial'));
        
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Send Documents for Execution', 
                                                                '23 - Send Documents for Execution', 
                                                                'Property Team', 
                                                                'Storeroom'));
        
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Prepare Counter Offer', 
                                                                '37 - Prepare Counter Offer', 
                                                                'Property Team', 
                                                                'Retail'));
        
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'JV Approval', 
                                                                '41 - JV Approval',
                                                                'Property Team',
                                                                'Retail'));
        
        taskTemplateList.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Accept Disclosure Statement', 
                                                                '01 - Accept Disclosure Statement', 
                                                                'Property Team', 
                                                                'Retail'));
        Test.startTest();
        database.insert(taskTemplateList);
        List<TaskTemplateAndCondition__c> childTaskTemplateList = new List<TaskTemplateAndCondition__c>();
        childTaskTemplateList.add(TestDataFactory.createTaskTemplate('Task', 
                                                                     'Retail Administrator', 
                                                                     taskTemplateList[0].Id, 
                                                                     'Propose & Accept', 
                                                                     'Update Deal Terms', 
                                                                     '36 - Update Deal Terms',
                                                                     'Property Team',
                                                                     'Retail'));
        
        childTaskTemplateList.add(TestDataFactory.createCaseTaskTemplate('Task', 
                                                                         'Retail Administrator', 
                                                                         'Lessee Application Form', 
                                                                         '47 - Lessee Application Form',
                                                                         'Property Team', 
                                                                         Constants.ASSIGN_OF_A_LEASE, 
                                                                         taskTemplateList[2].Id));
        Database.insert(childTaskTemplateList);
        //Create Contract
        List<Contract__c> contractList = new List<Contract__c>();
        contractList.addAll(TestDataFactory.createContract(1, childAccountList[0]));
        database.insert(contractList);
        
        //Create Case
        List<Case> caseList = new List<Case>();
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.ASSIGN_OF_A_LEASE).getRecordTypeId()));
        TriggerHandler.bypass('CaseTriggerHandler');
        database.insert(caseList);
        
        Test.stopTest();
    }
    
    @isTest
    private static void testTaskInsert1() {
        Opportunity oppTemp;
        Profile profileRec;
        Set<Id> taskIdSet = new Set<Id>();
        List<Task> taskList = new List<Task>();
        List<Case> caseList = [SELECT Id FROM Case];
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, Type, RecordType.Name FROM Opportunity]
        );
        Map<String, TaskTemplateAndCondition__c> objectTypeTaskTemplateMap = new Map<String, TaskTemplateAndCondition__c>();
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        Map<String, TaskTemplateAndCondition__c> businessUnitTaskTemplateMap = new Map<String, TaskTemplateAndCondition__c>();
        
        profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        System.debug('JAmesDebug' + [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR limit 1]);
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        for(TaskTemplateAndCondition__c taskTemplate : [SELECT Id, Name, Object__c, CaseRecordType__c, OpportunityStage__c, 
                                                        BusinessUnit__c
                                                        FROM TaskTemplateAndCondition__c 
                                                        WHERE TaskType__c = '23 - Send Documents for Execution']){
                                                            if(taskTemplate.CaseRecordType__c != null){
                                                                objectTypeTaskTemplateMap.put('Case', taskTemplate);
                                                            } else if(taskTemplate.OpportunityStage__c != null){
                                                                objectTypeTaskTemplateMap.put('Opportunity', taskTemplate);
                                                                
                                                                businessUnitTaskTemplateMap.put(taskTemplate.BusinessUnit__c, taskTemplate);
                                                            }
                                                        }
        
        for(Opportunity opp : opportunityMap.values()){
            taskList.add(
                TestDataFactory.createTask(
                    taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                    opp.Id,
                    null,
                    'Send Documents for Execution',
                    '23 - Send Documents for Execution'
                )
            );
        }
        Opportunity opp = [SELECT Id, Name, Type, RecordType.Name FROM Opportunity LIMIT 1];
        taskList.add(
            TestDataFactory.createTask(
                taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                opp.Id,
                null,
                'Send Documents for Execution',
                '23 - Send Documents for Execution'
            )
        );
        taskList[0].Opportunity__c = opp.Id;
        
        system.runAs(runningUser){
            Test.startTest();
            Database.insert(taskList);
            Test.stopTest();
        }
        
        for(Task tas : taskList){
            taskIdSet.add(tas.Id);
        }
        
        taskList = [SELECT Id, WhatId, TECHTaskTemplateId__c FROM Task WHERE Id IN: taskIdSet];
        
        String oppBusinessUnit;
        for(Task tas : taskList){
            if(tas.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                oppTemp = opportunityMap.get(tas.WhatId);
                if(Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(oppTemp.RecordType.Name)){
                    oppBusinessUnit = Constants.COMMERCIAL;
                } else if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(oppTemp.RecordType.Name)){
                    oppBusinessUnit = Constants.RETAIL;
                }else if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(oppTemp.RecordType.Name)){
                    oppBusinessUnit = Constants.STOREROOMTYPE;
                }
                if(businessUnitTaskTemplateMap.containskey(oppBusinessUnit)){
                    system.assertEquals(
                        tas.TECHTaskTemplateId__c, 
                        businessUnitTaskTemplateMap.get(oppBusinessUnit).Id, 
                        'Id : ' + tas.TECHTaskTemplateId__c + '>>>' + businessUnitTaskTemplateMap);
                }
                
            } else if(tas.WhatId.getSObjectType() == Schema.Case.SObjectType){
                system.assertEquals(tas.TECHTaskTemplateId__c, objectTypeTaskTemplateMap.get('Case').Id);
            }
        }
    }
    
    @isTest
    private static void testTaskUpdate1() {
        Id whatId;
        Task taskTemp;
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> taskIdSet = new Set<Id>();
        List<Task> taskList = new List<Task>();
        List<Case> caseList = [SELECT Id FROM Case];
        List<Opportunity> opportunityList = [SELECT Id, Name FROM Opportunity];
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        
        Set<String> objectTypeSet = new Set<String>{
            'Opportunity',
                'Case'
                };
                    
                    Set<String> taskTypeSet = new Set<String>{
                        '01 - Accept Disclosure Statement',
                            '41 - JV Approval',
                            '37 - Prepare Counter Offer'
                            };
                                
                                Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        for(TaskTemplateAndCondition__c taskTemplate : [SELECT Id, Name, Object__c, TaskType__c, TaskName__c
                                                        FROM TaskTemplateAndCondition__c 
                                                        WHERE Object__c IN: objectTypeSet OR TaskType__c IN: taskTypeSet]){
                                                            if('Opportunity'.equalsIgnoreCase(taskTemplate.Object__c) || taskTypeSet.contains(taskTemplate.TaskType__c)){
                                                                whatId = opportunityList[0].Id;
                                                            } else if('Case'.equalsIgnoreCase(taskTemplate.Object__c)){
                                                                whatId = caseList[0].Id;
                                                            }
                                                            
                                                            taskTemp = 
                                                                TestDataFactory.createTask(
                                                                    taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                                                                    whatId,
                                                                    null,
                                                                    taskTemplate.TaskName__c,
                                                                    taskTemplate.TaskType__c
                                                                );
                                                            
                                                            taskTemp.TECHTaskTemplateId__c = taskTemplate.Id;
                                                            taskTemp.Opportunity__c = opportunityList[0].Id;
                                                            taskList.add(taskTemp);
                                                        }
        
        system.runAs(runningUser){
            Database.insert(taskList);
            
            Test.startTest();
            for(Task tas : taskList){
                taskIdSet.add(tas.Id);
                oppIdSet.add(tas.WhatId);
                
                if(!'37 - Prepare Counter Offer'.equalsIgnoreCase(tas.TaskType__c)){
                    tas.Status = 'Completed';
                }
            }
            
            TriggerHandler.clearBypass('TaskTriggerHandler');
            Database.update(taskList);
            Test.stopTest();
        }
        
        Integer newTasks = 0;
        taskList = [SELECT Id, WhatId, TECHTaskTemplateId__c, Status, TaskType__c FROM Task];
        opportunityMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, TECHJVCompleted__c FROM Opportunity WHERE Id IN: oppIdSet]
        );
        
        for(Task tas : taskList){
            if('37 - Prepare Counter Offer'.equalsIgnoreCase(tas.TaskType__c)){
                system.assertEquals(tas.Status, Constants.CANCELLED);
            }
            
            if('41 - JV Approval'.equalsIgnoreCase(tas.TaskType__c) && opportunityMap.containsKey(tas.WhatId)){
                system.assert(opportunityMap.get(tas.WhatId).TECHJVCompleted__c);
            }
            
            if('36 - Update Deal Terms'.equalsIgnoreCase(tas.TaskType__c) 
               || '47 - Lessee Application Form'.equalsIgnoreCase(tas.TaskType__c)){
                   newTasks++;
               }
        }
        //system.assertnotequals(taskList,taskList);
        //system.assertEquals(newTasks, 0);
    }
   /* public static testMethod void testTaskUpdate() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Task tsk = [Select id,tasktype__c from task limit 1];
        // System.runAs(testUser) {
        Test.startTest();
        tsk.tasktype__c = constants.TASK_TYPE_CONFIRM_JV_APPROVAL;
        database.update(tsk);
        Test.stopTest();
        // }
    }*/
    
    @isTest
    public static void taskInsert2(){
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        List<Task> taskList = new List<Task>();
        List<Case> caseList = [SELECT Id FROM Case];
        Opportunity opp = [SELECT Id, Name, Type, RecordType.Name FROM Opportunity LIMIT 1];
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        taskList.add(
            TestDataFactory.createTask(
                taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                opp.Id,
                null,
                'Initial Cost Estimate',
                '70 - Initial Cost Estimate'
            )
        );
        
        taskList.add(
            TestDataFactory.createTask(
                taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                opp.Id,
                null,
                'Sketch Plan',
                '71 - Sketch Plan'
            )
        );
        
        system.runAs(runningUser){
            Test.startTest();
            Database.insert(taskList);
            Test.stopTest();
            Date todaysDate = System.today();
            for(Task t : [SELECT Id, TaskType__c, ActivityDate, KPI__c FROM Task]){
                if(t.TaskType__c == '70 - Initial Cost Estimate'){
                    System.assertEquals(DateUtils.AddBusinessDays(system.today(),10), t.ActivityDate);
                }
                
                if(t.TaskType__c == '71 - Sketch Plan'){
                    System.assertEquals(DateUtils.AddBusinessDays(system.today(),5), t.ActivityDate);
                }
            }
            
        }
    }
}