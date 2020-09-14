/**
 * @author:         Kyle Tan
 * @desc:           Test class for OpportunityRejectApproval
 **/
@IsTest
private class OpportunityRejectApprovalTest {

    public static testMethod void rejectApprovalFromOpportunityTest() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('PropertyTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SpaceTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> accountList = new List<Account>();
        accountList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(2, propertyList[0]);
        spaceList[1].Type__c = '4';		// Prince 4/25; Space Type: Store Room
        spaceList[1].MainFloor__c = '1';	
        spaceList[0].MainFloor__c = '1';	
        database.insert(spaceList);
        
        //Create User
        List<User> userList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('Pablo', 'Escobar', profileRec.Id);
        userList.add(testUser);
        User testUser2 = TestDataFactory.createUniqueTestUser('John', 'Watson', profileRec.Id);
        userList.add(testUser2);
        database.insert(userList);
        
        //Create Opportunity
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        oppList[0].RecordTypeId = oppRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
        oppList[0].RMLARS__c = userList[1].Id;
        //oppList[0].ApprovalStatus__c = 'Final Approval Rejected';
        database.insert(oppList);
        
		// --- 4/16/19
		// Create Property Team
		Map<String, Schema.RecordTypeInfo> propTeamRecordTypeByDevName = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.PROPERTY_TEAM_API);
        Schema.RecordTypeInfo internalTeamMember = propTeamRecordTypeByDevName.get(Constants.PRT_INTERNAL_TEAM_MEMBER_API);
        PropertyTeam__c propertyTeam = TestDataFactory.createPropertyTeam(propertyList[0].Id, Constants.TEAM_ROLE_REV_ADMIN, userList[0].Id, internalTeamMember.getRecordTypeId());
        propertyTeam.StartDate__c = date.today().addYears(-1);
        propertyTeam.EndDate__c = date.today().addYears(1);        
        database.insert(propertyTeam);   
        
        // --- 4/22/19
        // Create Task
        Task opptyTask = new Task();
        opptyTask.Opportunity__c = oppList[0].Id;
        opptyTask.WhatId = oppList[0].Id;
        opptyTask.Status = Constants.COMPLETED;
        opptyTask.TaskType__c = Constants.TASK_TYPE_INSTRUCT_SOLICITOR;
        database.insert(opptyTask);
        // ---
    
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT SpecialityLeaseType__c,ApprovalStatus__c,RecordTypeId,RMLARS__c,Id FROM Opportunity order by createddate desc limit 1]);
        List<Id> oppListId = new List<Id>();
        oppListId.addAll(oppMap.keySet());
        //system.assertnotequals(oppMap.values(),oppMap.values());
        //Create Approval Process
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(oppListId[0]);
        approvalRequest.setProcessDefinitionNameOrId('RetailInitialApproval_v2');
        
        system.runAs(testUser) {
            Approval.ProcessResult result = Approval.process(approvalRequest);   
            OpportunityRejectApproval.rejectApprovalFromOpportunity(oppListId);
        }
    }
}