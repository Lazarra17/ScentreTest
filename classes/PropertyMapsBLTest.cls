/*
* @author:              Sidney Garcia
* @description:         Test class for PropertyMapsBL
*/
@isTest
public class PropertyMapsBLTest {
	@TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        List<PropertyMaps__c> propertyMapsList = new List<PropertyMaps__c>();
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        Property__c property = TestDataFactory.createProperty(1, priceBookRec)[0];
        Database.insert(property);
        Property__c propRec = [SELECT Id, Name FROM Property__c LIMIT 1];
        //CREATE PROPERTYMAPS
        propertyMapsList = TestDataFactory.createPropertyMaps(1, propRec.Id);
        for(PropertyMaps__c propMapRec : propertyMapsList){
            propMapRec.Floor__c = '1';
            propMapRec.URL__c = 'https://test.test/testPic.svg';
        }
        Database.insert(propertyMapsList);
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(10, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
        opportunityList = TestDataFactory.createOpportunity(accountList);
        
        database.insert(opportunityList);
        
        List<Space__c> spaceList = TestDataFactory.createSpace(10, property);
        for(Space__c space : spaceList){
            space.MainFloor__c = '1';
            space.DevelopmentType__c = null;
            
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
        Database.insert(spaceList);
        List<Space__c> newSpaceList = [SELECT Id, RentableArea__c, DevelopmentType__c, RecordTypeId, Type__c, Property__c FROM Space__c LIMIT 10];
        
        Account accountRecord = [SELECT Id, Name FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() LIMIT 1];
        
        contractList = TestDataFactory.createContract(10, accountRecord);
        for(Integer i = 0; i<contractList.size();i++){
            contractList[i].space__c = newSpaceList[i].id;
            contractList[i].ActualVacateDate__c = date.today() -5;
            contractList[i].Property__c = propRec.Id;
        }
        database.insert(contractList);
        contractList = [SELECT Id, ActualVacateDate__c FROM Contract__c];
        
    }
    public static testMethod void testUpdateCurrentAndPreviousTenant(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Property__c propertyRec = [SELECT Id FROM Property__c LIMIT 1];
        List<Space__c> spaceList = [SELECT Id, Property__c, MainFloor__c, FloorPlanURL__c FROM Space__c WHERE Property__c =:propertyRec.Id];
        PropertyMaps__c propertyMapsRec = [SELECT Id, Property__c, Floor__c, URL__c FROM PropertyMaps__c WHERE Property__c =:propertyRec.Id];
        Map<Id, List<Space__c>> propertySpaceMap = new Map<Id, List<Space__c>>();
        
        propertySpaceMap.put(propertyRec.Id, spaceList);
        
        List<Space__c> updatedSpaceList = new List<Space__c>();
        System.runAs(testUser){
            Test.startTest();
            updatedSpaceList = PropertyMapsBL.updateSpaceFloorPlanURL(propertySpaceMap, propertyMapsRec);
            Test.stopTest();
        }
        
        String tempURL = propertyMapsRec.URL__c.replace(Constants.SVG, Constants.PNG);
        for(Space__c spaceRec : updatedSpaceList){
            System.assertEquals(tempURL, spaceRec.FloorPlanURL__c);
        }
    }
}