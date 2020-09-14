@isTest
public class TaskUtilityInvocableTest {
    
    private static Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
    
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
        
        //Create Users
        List<User> testUserList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 1', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 2', profileRec.Id));
        testUserList.add(TestDataFactory.createUniqueTestUser('Test', 'User 3', profileRec.Id));
        database.insert(testUserList);        
        
        //Create Property Team
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        propertyTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 
                                                                Constants.TEAM_ROLE_PRA, 
                                                                testUserList[0].Id, 
                                                                propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        propertyTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 
                                                                Constants.TEAM_ROLE_RA, 
                                                                testUserList[1].Id, 
                                                                propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        propertyTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 
                                                                'Group Renewal Admin Team', 
                                                                testUserList[2].Id, 
                                                                propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));        
        database.insert(propertyTeamList);       
        
        //Create Task Template
        List<TaskTemplateAndCondition__c> taskTemplateList = new List<TaskTemplateAndCondition__c>();
        TaskTemplateAndCondition__c sendDocsTemplate = TestDataFactory.createTaskTemplate(Constants.TASK, 
                                                                'Retail Administrator', 
                                                                null, 
                                                                'Propose & Accept', 
                                                                'Send Documents for Execution', 
                                                                '23 - Send Documents for Execution', 
                                                                'Property Team', 
                                                                Constants.RETAIL);
        
        sendDocsTemplate.GroupRenewalRole__c = 'Group Renewal Admin Team';
        taskTemplateList.add(sendDocsTemplate);
        database.insert(taskTemplateList);
        
        
        //Create Contract
        List<Contract__c> contractList = new List<Contract__c>();
        contractList.addAll(TestDataFactory.createContract(1, accountList[0]));
        database.insert(contractList);
        
        //Create Case
        List<Case> caseList = new List<Case>();
        Case sampleCase = TestDataFactory.createCase(contractList[0], spaceList[0], caseRecordTypeMapByName.get(Constants.LEASING_CHECKSHEET).getRecordTypeId());
        sampleCase.Opportunity__c = oppList[0].Id;
        sampleCase.Type = 'Checksheet';
        sampleCase.SubType__c = 'Variation Checksheet';
        
        caseList.add(sampleCase);
        database.insert(caseList);
        
    }
    @isTest
    private static void sendDocsPRATest() {
        Case case1 = [SELECT Id, Opportunity__c, Space__c, Space__r.Property__c, OwnerId, Type FROM Case LIMIT 1];
        Opportunity opp =  [SELECT Id, Tech_isCreatedFromGroupRenew__c, RecordType.DeveloperName, SpecialityLeaseType__c, CurrencyIsoCode, Type
                                      FROM Opportunity
                                      WHERE Id=:case1.Opportunity__c];
        
        Map<String, PropertyTeam__c> propTeamMap = DatabaseSOQLBank.getPropertyTeamByProperty(new Set<Id>{case1.Space__r.Property__c}).get(case1.Space__r.Property__c);
        
        
        system.debug('ZZZ Case Type -- ' + case1.Type);
        update case1;

        Test.startTest();        
        system.debug('Record Type -- ' + opp.RecordType.DeveloperName);
        system.debug('Type -- ' + opp.Type);
        system.debug('SpecialityLeaseType -- ' + opp.SpecialityLeaseType__c);
        system.debug('Currency -- ' + opp.CurrencyIsoCode);
        
        TaskUtilityInvocable.createSendDocsFromCase(new List<Id>{case1.Id});
        
        system.debug('PRA -- ' + propTeamMap.get(Constants.TEAM_ROLE_PRA).TeamMember__c);
        system.debug('RA -- ' + propTeamMap.get(Constants.TEAM_ROLE_RA).TeamMember__c);
        system.debug('GRAT -- ' + propTeamMap.get('Group Renewal Admin Team').TeamMember__c);
        system.debug('Case owner -- ' + case1.OwnerId);
        
        
        for (Task createdTask : [SELECT Id, TaskType__c, OwnerId FROM Task WHERE WhatId=:opp.Id AND TaskType__c='23 - Send Documents for Execution']) {
            system.debug('task owner -- ' + createdTask.OwnerId);
            System.assert(createdTask.OwnerId == propTeamMap.get(Constants.TEAM_ROLE_RA).TeamMember__c);
        }
        
        
        Test.stopTest();
    }
    @isTest
    private static void sendDocsRATest(){
        Case case1 = [SELECT Id, Opportunity__c, Space__c, Space__r.Property__c, OwnerId, Type FROM Case LIMIT 1];
        Opportunity opp =  [SELECT Id, Tech_isCreatedFromGroupRenew__c, RecordType.DeveloperName, SpecialityLeaseType__c, CurrencyIsoCode, Type
                            FROM Opportunity
                            WHERE Id=:case1.Opportunity__c];
        
        Map<String, PropertyTeam__c> propTeamMap = DatabaseSOQLBank.getPropertyTeamByProperty(new Set<Id>{case1.Space__r.Property__c}).get(case1.Space__r.Property__c);
        
        
        system.debug('ZZZ Case Type -- ' + case1.Type);
        update case1;
        
        Test.startTest();        
        
        opp.RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
        update opp;
        
        Space__c space1 = [SELECT Id, Status__c FROM Space__c WHERE Id =:case1.Space__c];
        space1.Status__c = Constants.SPACE_STATUS_PROJECT;
        update space1;
        
        TaskUtilityInvocable.createSendDocsFromCase(new List<Id>{case1.Id});
        
        for (Task createdTask : [SELECT Id, TaskType__c, OwnerId FROM Task WHERE WhatId=:opp.Id AND TaskType__c='23 - Send Documents for Execution']) {
            system.debug('task owner -- ' + createdTask.OwnerId);
            System.assert(createdTask.OwnerId == propTeamMap.get(Constants.TEAM_ROLE_PRA).TeamMember__c);
        }
        
        
        Test.stopTest();
    }
    @isTest
    private static void sendDocsGRATTest(){
        Case case1 = [SELECT Id, Opportunity__c, Space__c, Space__r.Property__c, OwnerId, Type FROM Case LIMIT 1];
        Opportunity opp =  [SELECT Id, Tech_isCreatedFromGroupRenew__c, RecordType.DeveloperName, SpecialityLeaseType__c, CurrencyIsoCode, Type
                            FROM Opportunity
                            WHERE Id=:case1.Opportunity__c];
        
        Map<String, PropertyTeam__c> propTeamMap = DatabaseSOQLBank.getPropertyTeamByProperty(new Set<Id>{case1.Space__r.Property__c}).get(case1.Space__r.Property__c);
        
        
        system.debug('ZZZ Case Type -- ' + case1.Type);
        update case1;
        
        Test.startTest();        

        opp.Tech_IsCreatedFromGroupRenew__c = true;
        update opp;
        TaskUtilityInvocable.createSendDocsFromCase(new List<Id>{case1.Id});
        
        
        for (Task createdTask : [SELECT Id, TaskType__c, OwnerId FROM Task WHERE WhatId=:opp.Id AND TaskType__c='23 - Send Documents for Execution']) {
            system.debug('task owner -- ' + createdTask.OwnerId);
            System.assert(createdTask.OwnerId == propTeamMap.get('Group Renewal Admin Team').TeamMember__c);
        }
        
        
        Test.stopTest();
    }   
}