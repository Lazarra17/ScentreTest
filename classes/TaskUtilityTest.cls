/**
 * @author          :Kyle Tan
 * @desc            :test class for TaskUtility
 **/
@isTest
private class TaskUtilityTest {
    
    @testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> propTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PROPERTY_TEAM_API);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        database.insert(oppList);
        
        //Create Content Version
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        contentVersionList.add(TestDataFactory.createContentVersion('Lease Plan Test File', 'Plans', 'Lease Plan'));
        database.insert(contentVersionList);
        contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        
        //Create DocumentLink
        List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();
        contentDocLinkList.add(TestDataFactory.createContentDocumentLink(spaceList[0].Id, contentVersionList[0]));
        database.insert(contentDocLinkList);
        
        //Create Property Ownership
        List<PropertyOwnership__c> propOwnershipList = new List<PropertyOwnership__c>();
        propOwnershipList.addAll(TestDataFactory.createPropertyOwnership(1, propertyList[0].Id, accountList[0].Id));
        database.insert(propOwnershipList);
        
        //Create Users
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        database.insert(testUserList);
        
        //Create Property Team
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        propertyTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 
                                                                'Administration Manager', 
                                                                testUserList[0].Id, 
                                                                propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        propertyTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 
                                                                'Administration Manager', 
                                                                testUserList[1].Id, 
                                                                propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        database.insert(propertyTeamList);
        
        //Create Opportunity Team Member
        List<OpportunityTeamMember> opportunityTeamMemberList = new List<OpportunityTeamMember>();
        opportunityTeamMemberList.add(TestDataFactory.createOpportunityTeamMember(oppList[0], testUserList[0], 'Retail Delivery'));
        opportunityTeamMemberList.add(TestDataFactory.createOpportunityTeamMember(oppList[0], testUserList[1], 'Retail Delivery'));
        database.insert(opportunityTeamMemberList);
        
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
        List<TaskTemplateAndCondition__c> taskTemplateListTemp = new List<TaskTemplateAndCondition__c>();
        taskTemplateListTemp.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                    'Retail Administrator', 
                                                                    taskTemplateList[0].Id, 
                                                                    'Propose & Accept', 
                                                                    'Pre-DS REAA Approval', 
                                                                    '59 - Pre-DS REAA Approval', 
                                                                    'Property Team', 
                                                                    'Commercial'));
        taskTemplateListTemp.add(TestDataFactory.createTaskTemplate('Opportunity', 
                                                                    'Retail Administrator', 
                                                                    taskTemplateList[0].Id, 
                                                                    'Propose & Accept', 
                                                                    'Pre-DS REAA Approval', 
                                                                    '59 - Pre-DS REAA Approval', 
                                                                    'Property Team', 
                                                                    'Commercial'));
        taskTemplateListTemp.add(TestDataFactory.createCaseTaskTemplate('Case', 
                                                                        'Retail Administrator', 
                                                                        'Pre-DS REAA Approval', 
                                                                        '59 - Pre-DS REAA Approval',
                                                                        'Property Team', 
                                                                        Constants.ASSIGN_OF_A_LEASE, 
                                                                        taskTemplateList[0].Id));
        taskTemplateListTemp.add(TestDataFactory.createCaseTaskTemplate('Case', 
                                                                        'Retail Administrator', 
                                                                        'Retail Administrator Review', 
                                                                        'Retail Administrator Review',
                                                                        'Property Team', 
                                                                        Constants.LVI_COVID19, 
                                                                        taskTemplateList[0].Id));
        taskTemplateListTemp.add(TestDataFactory.createCaseTaskTemplate('Case', 
                                                                        'Retail Administrator', 
                                                                        'Accept Offer Letter', 
                                                                        'Accept Offer Letter',
                                                                        'Property Team', 
                                                                        Constants.LVI_COVID19, 
                                                                        taskTemplateList[0].Id));
        database.insert(taskTemplateListTemp);
        
        //Create Contract
        List<Contract__c> contractList = new List<Contract__c>();
        contractList.addAll(TestDataFactory.createContract(1, accountList[0]));
        database.insert(contractList);
        
        //Create Case
        List<Case> caseList = new List<Case>();
        caseList.add(TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.REQUEST_FOR_REFUND).getRecordTypeId()));
        
        Case covidCase = TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.LVI_COVID19).getRecordTypeId());
        covidCase.Type = Constants.CASE_TYPE_LV18MISCELLANEOUS;
        covidCase.SubType__c = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
        caseList.add(covidCase);
        
        database.insert(caseList);
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void getSpaceWithLeasePlanTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> cDocumentIdSet = new Set<Id>();
        Map<Id, Space__c> spaceMap = new Map<Id, Space__c>([SELECT Id FROM Space__c]);
        system.runAs(testUser) {
            test.startTest();
            cDocumentIdSet = TaskUtility.getSpaceWithLeasePlan(spaceMap.keySet());
            test.stopTest();
        }
        system.assertEquals(1, cDocumentIdSet.size());
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void isJVRequiredTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Boolean> isJVrequiredList = new List<Boolean>();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, JVBudgetRent__c , AnnualMinimumRent__c, JVBudgetCapital__c, TotalForecastCapital__c, JVRentVariance__c, JVCapitalVariance__c FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, DexusProperty__c, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c FROM Property__c]);
        List<PropertyOwnership__c> propOwnershipList = new List<PropertyOwnership__c>([SELECT Id, RentApprovalTolerance__c, CapitalApprovalTolerance__c, CapitalApprovalToleranceCurrency__c FROM PropertyOwnership__c]);
        
        system.runAs(testUser) {
            test.startTest();
            isJVrequiredList.add(TaskUtility.isJVRequired(oppList[0], propertyList[0], propOwnershipList));
            propertyList[0].HoldingCompaniesName__c = Label.TaskCreationDEXUS;
            propertyList[0].DexusProperty__c = true;
            isJVrequiredList.add(TaskUtility.isJVRequired(oppList[0], propertyList[0], propOwnershipList));
            test.stopTest();
        }
        system.assertEquals(false, isJVrequiredList[0]);
        system.assertEquals(true, isJVrequiredList[1]);
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void getPropertyTeamPerPropertyTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, Map<String, PropertyTeam__c>> propertyIdPropertyTeamMapMap = new Map<Id, Map<String, PropertyTeam__c>>();
        Map<Id, Property__c> propertyMap = new Map<Id, Property__c>([SELECT Id, DexusProperty__c FROM Property__c]);
        system.runAs(testUser) {
            test.startTest();
            propertyIdPropertyTeamMapMap = TaskUtility.getPropertyTeamPerProperty(propertyMap.keySet());
            test.stopTest();
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void getOpportunityTeamPerOpportunityTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<Id, Map<String, OpportunityTeamMember>> opportunityIdOppTeamMapMap = new Map<Id, Map<String, OpportunityTeamMember>>();
        for(OpportunityTeamMember oppTeamMemberRec :[SELECT Id, Name, OpportunityId, 
                                                     TeamMemberRole, UserId
                                                     FROM OpportunityTeamMember]) {
                                                         opportunityIdSet.add(oppTeamMemberRec.OpportunityId);
                                                     }
        system.runAs(testUser) {
            opportunityIdOppTeamMapMap = TaskUtility.getOpportunityTeamPerOpportunity(opportunityIdSet);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void getDependentTaskTemplateTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, List<TaskTemplateAndCondition__c>> taskTemplateMap = new Map<Id, List<TaskTemplateAndCondition__c>>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>([SELECT Id, DependentTask__c 
                                                                                                    FROM TaskTemplateAndCondition__c]);
        system.runAs(testUser) {
            taskTemplateMap = TaskUtility.getDependentTaskTemplate(taskTemplateList);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createCaseTaskTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>([SELECT ApplicableCountry__c,Id, AssigneesTeam__c, 
                                                                                                    CaseRecordType__c, TaskName__c, 
                                                                                                    TaskType__c, TaskDescription__c, 
                                                                                                    DueDate__c, AccountTeamRole__c, SkipWeekends__c
                                                                                                    FROM TaskTemplateAndCondition__c]);
        List<Case> caseList = new List<Case>([SELECT TECHPropertyCountry__c,Id, TechPropertyId__c, RecordTypeId, SubType__c FROM Case]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            newTaskList = TaskUtility.createCaseTask(caseList[0], 
                                                     Constants.ASSIGN_OF_A_LEASE, 
                                                     taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                     taskTemplateList, 
                                                     wrapper, 
                                                     accountList[0]);
        }
    }
    
    @isTest
    private static void createCovidCaseTaskTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>([SELECT ApplicableCountry__c,Id, AssigneesTeam__c, 
                                                                                                    CaseRecordType__c, TaskName__c, 
                                                                                                    TaskType__c, TaskDescription__c, 
                                                                                                    DueDate__c, AccountTeamRole__c, SkipWeekends__c
                                                                                                    FROM TaskTemplateAndCondition__c]);
        List<Case> caseList = new List<Case>([SELECT TECHPropertyCountry__c,Id, TechPropertyId__c, RecordTypeId, SubType__c, OwnerId, Status FROM Case WHERE SubType__c = :Constants.CASE_SUBTYPE_COVID_RENT_REQUEST]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            newTaskList = TaskUtility.createCaseTask(caseList[0], 
                                                     Constants.ASSIGN_OF_A_LEASE, 
                                                     taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                     taskTemplateList, 
                                                     wrapper, 
                                                     accountList[0]);
        }
    }

    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createOpportunityTaskTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c
            FROM TaskTemplateAndCondition__c]
        );
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, StageName, Group_Renewal_Retail_Admin__c,
                                                           CurrencyIsoCode, SpecialityLeaseType__c, 
                                                           TECHJVRequired__c, Type, Space__c, Property__c, OwnerId, Account_Type__c,Tech_PropertyState__c,
                                                           Tech_IsCreatedFromGroupRenew__c
                                                           FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            taskTemplateList[0].BusinessUnit__c = Constants.COMMERCIAL;
            taskTemplateList[0].LeaseType__c = oppList[0].Type;
            taskTemplateList[0].OpportunityStage__c = oppList[0].StageName;
            taskTemplateList[0].AssigneesTeam__c = Constants.PROPERTY_TEAM;
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_COMMERCIAL_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true, spaceLst[0]);
            taskTemplateList[0].BusinessUnit__c = Constants.RETAIL;
            taskTemplateList[0].ApplicableCountry__c = 'NZD';
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_RETAIL_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createOpportunityTaskTest2() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c 
            FROM TaskTemplateAndCondition__c]
        );
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, StageName, 
                                                           CurrencyIsoCode, SpecialityLeaseType__c, 
                                                           TECHJVRequired__c, Type, Space__c, Property__c, OwnerId
                                                           FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
                List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            taskTemplateList[0].BusinessUnit__c = Constants.STOREROOMTYPE;
            taskTemplateList[0].LeaseType__c = oppList[0].Type;
            taskTemplateList[0].OpportunityStage__c = oppList[0].StageName;
            oppList[0].SpecialityLeaseType__c = 'Variation of Lease';
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_STORE_ROOM_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createOpportunityTaskTest3() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c
            FROM TaskTemplateAndCondition__c]
        );
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, StageName, 
                                                           CurrencyIsoCode, SpecialityLeaseType__c, 
                                                           TECHJVRequired__c, Type, Space__c, Property__c, OwnerId
                                                           FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
                List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        system.runAs(testUser) {
            taskTemplateList[0].BusinessUnit__c = Constants.STOREROOMTYPE;
            taskTemplateList[0].LeaseType__c = oppList[0].Type;
            taskTemplateList[0].OpportunityStage__c = oppList[0].StageName;
            oppList[0].SpecialityLeaseType__c = null;
            taskTemplateList[0].SpecialtyLeaseType__c = 'Variation to Lease';
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_STORE_ROOM_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createOpportunityTaskTest4() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c
            FROM TaskTemplateAndCondition__c]
        );
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, StageName, 
                                                           CurrencyIsoCode, SpecialityLeaseType__c, 
                                                           TECHJVRequired__c, Type, Space__c, Property__c, OwnerId
                                                           FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
                List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        system.runAs(testUser) {
            taskTemplateList[0].BusinessUnit__c = Constants.COMMERCIAL;
            oppList[0].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            taskTemplateList[0].LeaseType__c = oppList[0].Type;
            taskTemplateList[0].OpportunityStage__c = oppList[0].StageName;
            taskTemplateList[0].AssigneesTeam__c = Constants.PROPERTY_TEAM;
            taskTemplateList[0].JVApproval__c = Constants.NOT_REQUIRED;
            oppList[0].TECHJVRequired__c = true;
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_COMMERCIAL_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
            taskTemplateList[0].JVApproval__c = Constants.REQUIRED;
            oppList[0].TECHJVRequired__c = false;
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_COMMERCIAL_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createOpportunityTaskTest5() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c
            FROM TaskTemplateAndCondition__c]
        );
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, StageName, Group_Renewal_Retail_Admin__c,
                                                           CurrencyIsoCode, SpecialityLeaseType__c, 
                                                           TECHJVRequired__c, Type, Space__c, Property__c, OwnerId, Account_Type__c,Tech_PropertyState__c,
                                                           Tech_IsCreatedFromGroupRenew__c
                                                           FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            taskTemplateList[0].BusinessUnit__c = Constants.COMMERCIAL;
            taskTemplateList[0].LeaseType__c = oppList[0].Type;
            taskTemplateList[0].OpportunityStage__c = oppList[0].StageName;
            taskTemplateList[0].AssigneesTeam__c = Constants.OPPORTUNITY_OWNER;
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_COMMERCIAL_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createOpportunityTaskTest6() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c
            FROM TaskTemplateAndCondition__c]
        );
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, StageName, Group_Renewal_Retail_Admin__c,
                                                           CurrencyIsoCode, SpecialityLeaseType__c, 
                                                           TECHJVRequired__c, Type, Space__c, Property__c, OwnerId, Account_Type__c,Tech_PropertyState__c,
                                                           Tech_IsCreatedFromGroupRenew__c
                                                           FROM Opportunity]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            taskTemplateList[0].BusinessUnit__c = Constants.COMMERCIAL;
            taskTemplateList[0].LeaseType__c = oppList[0].Type;
            taskTemplateList[0].OpportunityStage__c = oppList[0].StageName;
            taskTemplateList[0].AssigneesTeam__c = Constants.OPPORTUNITY_TEAM;
            newTaskList = TaskUtility.createOpportunityTask(oppList[0], 
                                                            null,
                                                            Constants.OPP_COMMERCIAL_LEASING, 
                                                            taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                            taskTemplateList, 
                                                            wrapper, 
                                                            accountList[0], propertyList[0], 
                                                            true,spaceLst[0]);
        }
    }
    
    /**
     * @author:             Kyle Tan
     **/
    @isTest
    private static void createTaskTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> newTaskList = new List<Task>();
        List<Opportunity> oppList = new List<Opportunity>(
            [SELECT Id, Property__c, TotalFitoutContribution__c, TotalDCCost__c, TotalLessorWorksCost__c, 
             TECH_UpdateCostEstimateRequired__c, FitoutContribution__c, RecordType.Name, Group_Renewal_Retail_Admin__c, Tech_IsCreatedFromGroupRenew__c
             FROM Opportunity]
        );
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>(
            [SELECT Id, AssigneesTeam__c, CaseRecordType__c, TaskName__c, TaskType__c, TaskDescription__c, 
            DueDate__c, AccountTeamRole__c, IsStageChange__c, BusinessUnit__c, LeaseType__c, OpportunityStage__c, 
            ApplicableCountry__c, SpecialtyLeaseType__c, JVApproval__c, Object__c, SkipWeekends__c
            FROM TaskTemplateAndCondition__c]);
        List<Account> accountList = new List<Account>([SELECT Id FROM Account]);
        List<Property__c> propertyList = new List<Property__c>([SELECT Id, Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, DexusProperty__c FROM Property__c]);
        List<Space__c> spaceLst = new List<Space__c>([SELECT Id,Status__c FROM Space__c]);
        List<Case> caseList = new List<Case>([SELECT Id, TechPropertyId__c, OwnerId, SubType__c, RecordTypeId FROM Case]);
        List<Case> covidCaseList = new List<Case>([SELECT Id, TechPropertyId__c, OwnerId, SubType__c, RecordTypeId, Is_Lease_Variation_Required__c, TECH_RetailAdministratorReviewCompleted__c FROM Case WHERE Subtype__c = :Constants.CASE_SUBTYPE_COVID_RENT_REQUEST]);
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        TaskUtility.TaskOwnerWrapper wrapper = new TaskUtility.TaskOwnerWrapper();
        system.runAs(testUser) {
            test.startTest();
            taskTemplateList[0].AssigneesTeam__c = Constants.OPPORTUNITY_OWNER;
            taskTemplateList[0].TaskType__c = Constants.OBLIGATIONS_RECEIVED_TASK_API;
            oppList[0].FitoutContribution__c = 0;
            oppList[0].TECH_UpdateCostEstimateRequired__c = false;
            newTaskList = TaskUtility.createTask(oppList[0], 
                                                 taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                 taskTemplateList, 
                                                 wrapper, 
                                                 accountList[0],propertyList[0],spaceLst[0] );
            taskTemplateList[0].TaskType__c = Constants.UPDATE_COSE_ESTIMATE;
            newTaskList = TaskUtility.createTask(oppList[0], 
                                                 taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                 taskTemplateList, 
                                                 wrapper, 
                                                 accountList[0],propertyList[0],spaceLst[0] );
            newTaskList = TaskUtility.createTask(caseList[0], 
                                                 taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                 taskTemplateList, 
                                                 wrapper, 
                                                 accountList[0],propertyList[0],spaceLst[0] );
            taskTemplateList[0].AssigneesTeam__c = Constants.OPPORTUNITY_TEAM;
            newTaskList = TaskUtility.createTask(caseList[0], 
                                                 taskRecordTypeMapByName.get('TAS - Adhoc').getRecordTypeId(), 
                                                 taskTemplateList, 
                                                 wrapper, 
                                                 accountList[0],propertyList[0],spaceLst[0] );
            newTaskList = TaskUtility.createTask(covidCaseList[0], 
                                                 taskRecordTypeMapByName.get(Constants.TASK_AUTOMATIC).getRecordTypeId(), 
                                                 taskTemplateList, 
                                                 wrapper, 
                                                 accountList[0],propertyList[0],spaceLst[0] );
            test.stopTest();
        }
    }
        /**
    * @author:             Lean Flores
    **/
    @isTest
    private static void getDueDateTest() {
        
        Date reference = Date.newInstance(2019, 6, 12); // Wednesday
        
        // Null check
        try {
            TaskUtility.getDueDate(reference, null);
        } catch (TaskUtility.MethodParameterValueException e) {
            system.assertNotEquals(null, e);
        }
        
        // Thursday
        system.assertEquals(Date.newInstance(2019, 6, 13), TaskUtility.getDueDate(reference, 1));
        // Friday
        system.assertEquals(Date.newInstance(2019, 6, 14), TaskUtility.getDueDate(reference, 2));
        // Monday
        system.assertEquals(Date.newInstance(2019, 6, 17),TaskUtility.getDueDate(reference, 3));
        // Tuesday
        system.assertEquals(Date.newInstance(2019, 6, 18),TaskUtility.getDueDate(reference, 4));
        // Wednesday
        system.assertEquals(Date.newInstance(2019, 6, 19),TaskUtility.getDueDate(reference, 5));
        // Thursday
        system.assertEquals(Date.newInstance(2019, 6, 20),TaskUtility.getDueDate(reference, 6));
        // Friday
        system.assertEquals(Date.newInstance(2019, 6, 21),TaskUtility.getDueDate(reference, 7));
        // Monday
        system.assertEquals(Date.newInstance(2019, 6, 24),TaskUtility.getDueDate(reference, 8));
        // Tuesday
        system.assertEquals(Date.newInstance(2019, 6, 25),TaskUtility.getDueDate(reference, 9));
        // Wednesday
        system.assertEquals(Date.newInstance(2019, 6, 26),TaskUtility.getDueDate(reference, 10));
        // Thursday
        system.assertEquals(Date.newInstance(2019, 6, 27),TaskUtility.getDueDate(reference, 11));
        // Friday
        system.assertEquals(Date.newInstance(2019, 6, 28),TaskUtility.getDueDate(reference, 12));
        // Monday
        system.assertEquals(Date.newInstance(2019, 7, 1),TaskUtility.getDueDate(reference, 13));
        

        // RPP-10241
        for (Integer i = 0; i < 65; i++) {
            Date dueDate = TaskUtility.getDueDate(reference, 13);
            Date startOfWeek = dueDate.toStartOfWeek();
            Integer dueDatedayOfWeek  = dueDate.day() - startOfWeek.day();
            Set<Integer> weekEnds = UserInfo.getLocale() == 'en_US' ? new Set<Integer>{0, 6} : new Set<Integer>{5,6};
            System.assert(!weekEnds.contains(dueDatedayOfWeek), 'Due date fell on a weekend');
        }

        system.assertEquals(Date.newInstance(2019, 7, 10),TaskUtility.getDueDate(reference, 20));
        system.assertEquals(Date.newInstance(2019, 9, 11),TaskUtility.getDueDate(reference, 65));
        

    }    
}