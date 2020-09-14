@isTest
public class UpdatePropertyFieldTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        
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
        accountList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Contact
        Contact cont = new Contact();
        cont.AccountId = accountList[0].Id;
        cont.LastName = 'Test Name';
        cont.Email = 'test@testmail.com';
        insert cont;
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        database.insert(oppList);
        
        //Create Task
        Task tsk = new Task();
        tsk.WhatId = oppList[0].id;
        tsk.Subject = 'Receive Registration Fees';
        tsk.ActivityDate = date.today();
        tsk.Property2__c = NULL;
        tsk.Status = Constants.OPEN;
        insert tsk;
    }
    
    
    public static testMethod void testupdatePropertyOnTask(){
        List<Task> taskList = new List<Task>();
        taskList = [SELECT Id, WhatId, Property2__c FROM Task WHERE Property2__c = NULL AND WhatId != NULL];
       
        Test.startTest();
        UpdatePropertyField.updatePropertyOnTask(taskList);
        Test.stopTest();
       // Property prop = [SELECT Id,Name FROM Property WHERE Id ];
       // System.assertEquals(taskList[0].Property2__c, 'Test Property 1');
        
    }

}