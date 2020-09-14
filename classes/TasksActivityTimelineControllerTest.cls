/**
* @author:          Kyle Tan
* @description:     Test class for TasksActivityTimelineController
**/
@isTest
private class TasksActivityTimelineControllerTest {

    @testSetup
    private static void testSetup() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> opportunityRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        TaskTemplateAndCondition__c taskTempConRec = new TaskTemplateAndCondition__c();
        List<Task> taskList = new List<Task>();
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        Contact conRec = new Contact();
        List<Space__c> spaceLst = new List<Space__c>();
        
        //CREATE PRICEBOOK
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //Create Contact
        conRec = TestDataFactory.createContact('Test Contact', account);
        database.insert(conRec);
        
        //CREATE SPACE
        spaceLst = TestDataFactory.createSpace(10, propertyList[0]);
        database.insert(spaceLst);
        spaceLst = [SELECT Id FROM Space__c];
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(10, account, propertyList, spaceLst);
        for(Integer i = 0; i < 10; i++) {
            if(i < 5) {
                opportunityList[i].RecordTypeId = opportunityRecordTypeMapByName.get(Constants.OPP_COMMERCIAL_LEASING).getRecordTypeId();
            } else {
                opportunityList[i].RecordTypeId = opportunityRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
            }
            opportunityList[i].Property__c = propertyList[0].Id;
        }
        database.insert(opportunityList);
        
        //CREATE Task related to Opportunity
        for(Integer i = 0; i < 10; i++){
            Task taskRec = new Task();
            taskRec = TestDataFactory.createTaskRelatedToOpp(opportunityList[i].Id, conRec);
            if(i == 9) {
                taskRec.Status = Constants.COMPLETED;
            }
            taskList.add(taskRec);
        }
        database.insert(taskList);
        
        //CREATE TASK TEMPLATE AND CONDITION
        
        taskTempConRec = TestDataFactory.createTaskTemplate(Constants.OPPORTUNITY, 
                                                            'Leasing Executive',
                                                            null,
                                                            Constants.UNDERSTAND_NEGOTIATE,
                                                            'Test task',
                                                            '17 - Register Lease',
                                                            'Opportunity Team',
                                                             'Commercial');
        system.runAs(testUser) {
            taskTempConRec.IsActive__c = true;
            taskTempConRec.BusinessUnit__c = Constants.COMMERCIAL;
            database.insert(taskTempConRec);
        }
    }
    
    /**
     * @author:         Kyle Tan
     **/
    private static testMethod void getTasksOfOppTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity LIMIT 10]);
        LightningResponse wrapper = new LightningResponse();

        System.runAs(testUser) {
            test.startTest();
            for(Opportunity oppRec :opportunityList) {
                wrapper = TasksActivityTimelineController.getTasksOfOpp(oppRec.Id);
            }
            test.stopTest();
        }
    }
    
    /**
     * @author:         Sidney Garcia
     * @description:    Test updateTaskStatus
     **/
    private static testMethod void updateTaskStatusTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> taskList = [SELECT Id FROM Task LIMIT 10];
        LightningResponse wrapper = new LightningResponse();
        
        System.runAs(testUser) {
            test.startTest();
            for(Task taskRec :taskList) {
                wrapper = TasksActivityTimelineController.updateTaskStatus(String.valueOf(taskRec.Id));
            }
            database.delete(taskList);
             for(Task taskRec :taskList) {
                wrapper = TasksActivityTimelineController.updateTaskStatus(String.valueOf(taskRec.Id));
            }
            test.stopTest();
        }
    }
    
    /**
     * @author:         Sidney Garcia
     * @description:    Test deleteTask
     **/
    private static testMethod void deleteTaskTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Task> taskList = [SELECT Id FROM Task LIMIT 10];
        LightningResponse wrapper = new LightningResponse();

        System.runAs(testUser) {
            test.startTest();
            for(Task taskRec :taskList) {
                wrapper = TasksActivityTimelineController.deleteTask(taskRec.Id);
                wrapper = TasksActivityTimelineController.deleteTask(taskRec.Id);
            }
            test.stopTest();
        }
    }
}