/**
* @author:         Kyle Tan
* @description:    Test Class for ACRTriggerHandler
**/
@isTest
private class ACRTriggerHandlerTest {
    
    @testSetup
    private static void testSetup(){
        List<Account> accountList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<Opportunity> oppList = new List<Opportunity>();
        Contact contactRec = new Contact();
        List<Contact> contactList = new List<Contact>();
        List<Space__c> spaceList = new List<Space__c>();
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY 
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        accountList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT).get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        accountList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        for(Account acc : accountList){
            contactRec = TestDataFactory.createContact('Test Name', accountList[0]);
            
            contactList.add(contactRec);
        }
        
        database.insert(contactList);
        
        //CREATE SPACE
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].type__c = '1';
        spaceList[0].BillingCategory__c = 'NA';
        database.insert(spaceList);
        
        spaceList = [SELECT Id, Type__c FROM Space__c];
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceList);
        AccountContactRelation acrRec = [SELECT Id, IsActive FROM AccountContactRelation Limit 1];
        System.debug('ACR REC ===== ' + acrRec);
        for(Opportunity opp : oppList){
            opp.JDESentStatus__c = 'Ready';
            opp.PrimaryContact__c = contactRec.Id;
        }
        
        database.insert(oppList);
        
        oppList = [SELECT Id, AccountId,JDESentStatus__c, PrimaryContact__c FROM Opportunity];
        System.debug('Oppplist ==== ' + oppList);
        
        
    }
    
    /**
* @author:         Kyle Tan
* @description:    Test Method for inserting an Account Contact Relationship
**/
    private static testMethod void testInsertACR() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        AccountContactRelation ACRRec = [SELECT ID FROM AccountContactRelation LIMIT 1];
        
        System.debug('Acr REc ==== ' + ACRRec);
        system.runAs(testUser) {
            test.startTest();
            ACRTriggerHandler acrhandler = new ACRTriggerHandler();
            
            List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 200];
            List<Account> accountList = [SELECT Id, Property__c FROM Account LIMIT 200];
            List<Property__c> propertyList = [Select Id FROM Property__c LIMIT 200];
            List<Space__c> spaceList = [SELECT Id FROM Space__c LIMIT 200];
            Contact contactRec = [SELECT Id FROM Contact LIMIT 1];
            oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceList);
            for(Opportunity opp : oppList){
                opp.JDESentStatus__c = 'Ready';
                opp.PrimaryContact__c = contactRec.Id;
            }
            database.insert(oppList);
            for(Opportunity opp : oppList){
                opp.JDESentStatus__c = 'Processing';
            }
            TriggerHandler.clearAllBypasses();
            database.update(oppList);
            
            acrhandler.beforeUpdate(ACRRec, ACRRec);
            acrhandler.beforeDelete(ACRRec);
            acrhandler.afterUpdate(ACRRec, ACRRec);
            acrhandler.afterDelete(ACRRec);
            
            //TODO: put some value on acEvents or satisfy the conditon for conW.sendEvent
            
            test.stopTest();
        }
    }
    
    @isTest
    private static void testRDIContactCount(){
        AccountContactRelation ACRRec = [SELECT ID,AccountId, Roles FROM AccountContactRelation LIMIT 1];
        ACRRec.Roles = Label.Applicable_RDI_Contact_Roles.split(',')[0];
        Test.startTest();
        update ACRRec;
        Test.stopTest();
        Account acc = [SELECT Id, No_of_RDI_Applicable_Contact_Relation__c FROM Account WHERE Id =: ACRRec.AccountId];
        System.assert(acc.No_of_RDI_Applicable_Contact_Relation__c != null);
    }
    
}