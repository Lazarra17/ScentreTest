/*
* @author:              Miguel Paguio
* @description:         Test class for ChatterToApprovedOppRMRiskTest
*/
@isTest
public class ChatterToApprovedOppRMRiskTest {
     @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        List<User> userList = new List<User>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
         
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        Property__c propRec = [SELECT Id FROM Property__c LIMIT 1];
         
         //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        
        //CREATE OPPORTUNITY
        account = [SELECT Id, Property__c FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(10, account);
        System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        
        for(Integer i = 0; i < 10; i++){
            User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME + ' ' + i, CONSTANTS.TEST_LNAME + ' ' + i, profileRec.Id);
            userList.add(testUser);
        }
        Database.insert(userList); 
    }
  	
    public static testMethod void testgetRoleId() {
       
        List<Opportunity> opplst = [select id from opportunity limit 1];
        List<Id> oppIdLst = new List<Id>();
        oppIdLst.add(opplst[0].id);
      
        ChatterToApprovedOppRMRisk.getFinanceRoleId(oppIdLst);
    }
}