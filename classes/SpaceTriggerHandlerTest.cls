/*
* @author:              Sidney Garcia
* @description:         Test class for SpaceTriggerHandler
*/

@isTest
public class SpaceTriggerHandlerTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        Property__c property = TestDataFactory.createProperty(1, priceBookRec)[0];
        Database.insert(property);
        Property__c propRec = [SELECT Id, Name FROM Property__c LIMIT 1];
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(10, property.Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        
        //CREATE OPPORTUNITY
        /*accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
        opportunityList = TestDataFactory.createOpportunity(accountList);
        
        for(Opportunity opp : opportunityList){
            opp.JDESentStatus__c = 'Ready';
        }
        
        database.insert(opportunityList);
        
        Integer counter = 0;
        List<Space__c> spaceList = TestDataFactory.createSpace(200, property);
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
            
            if(counter != (opportunityList.size() - 1)){
                space.LatestAchievedOpportunity__c = opportunityList[counter].Id;
                counter++;
            }
        }
        
        Database.insert(spaceList);
        List<Space__c> newSpaceList = [SELECT Id, RentableArea__c, DevelopmentType__c, RecordTypeId, Type__c, Property__c FROM Space__c LIMIT 200];*/
        
        
    }
    
    @isTest
    private static void testSpaceInsert1() {
        List<Property__c> propertyList = [SELECT Id, Name FROM Property__c];
        List<Space__c> spaceList = TestDataFactory.createSpace(200, propertyList[0]);
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
        
        system.runAs(testUser) {
            test.startTest();
                Database.insert(spaceList);
            test.stopTest();
        }
    }
    
    @isTest
    private static void testSpaceUpdate1() {
        test.startTest();
        List<Account> accountList = new List<Account>();
        List<Property__c> propertyList = [SELECT Id, Name FROM Property__c];
        List<Space__c> spaceList = TestDataFactory.createSpace(10, propertyList[0]);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Opportunity> opportunityTempList = new List<Opportunity>();
        Map<Id, Opportunity> spaceIdOpportunityMap = new Map<Id, Opportunity>();
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        
        Profile retailFinanceProf = [SELECT Id FROM Profile WHERE Name = 'SCG-Retail Finance' LIMIT 1];
        Profile retailCentreMgtProf = [SELECT Id FROM Profile WHERE Name = 'SCG-Retail CentreMgt' LIMIT 1];
        
        UserRole retailCRMRole = [SELECT Id FROM UserRole WHERE Name='Retail CRM' LIMIT 1];
        User retailFinance = TestDataFactory.createUniqueTestUser('John', 'Doe', retailFinanceProf.Id);
        User retailCentreMgt = TestDataFactory.createUniqueTestUser('John', 'Doe', retailCentreMgtProf.Id);
        retailFinance.UserRoleId = retailCRMRole.Id;
        retailCentreMgt.UserRoleId = retailCRMRole.Id;
            
        system.runAs(retailFinance) {
            for(Space__c space : spaceList){
                space.RentableArea__c = 40;
                space.DevelopmentType__c = null;
                space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
            }
            
            Database.insert(spaceList);
            
            //CREATE OPPORTUNITY
            Integer counter = 0;
            accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
            for(Account acc : accountList){
                opportunityTempList = TestDataFactory.createOpportunity(1, acc);
                
                for(Opportunity opp : opportunityTempList){
                    opp.JDESentStatus__c = 'Ready';
                    opp.Space__c = spaceList[counter].Id;
                    counter++;
                }
                
                opportunityList.addAll(opportunityTempList);
            }
            
            database.insert(opportunityList);
            
            for(Opportunity opp : opportunityList){
                spaceIdOpportunityMap.put(opp.Space__c, opp);
            }
            
        
            
            for(Space__c spc : spaceList){
                spc.LatestAchievedOpportunity__c = spaceIdOpportunityMap.get(spc.Id).Id;
                spc.RentableArea__c = 50;
            }
            TriggerHandler.clearBypass('SpaceTriggerHandler');
            spaceList[0].Status__c = 'Project';
            Database.update(spaceList[0]);
            
            
        }
        /*system.runAs(retailCentreMgt) { 
        	spaceList[1].RentableArea__c = 60;
			Database.update(spaceList[1]);       
        }*/
        
        test.stopTest();
    }
    
    
    
    @isTest
    private static void testSpaceUpdate2() {
        test.startTest();
        List<Account> accountList = new List<Account>();
        List<Property__c> propertyList = [SELECT Id, Name FROM Property__c];
        List<Space__c> spaceList = TestDataFactory.createSpace(10, propertyList[0]);
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Opportunity> opportunityTempList = new List<Opportunity>();
        Map<Id, Opportunity> spaceIdOpportunityMap = new Map<Id, Opportunity>();
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        
        Profile retailFinanceProf = [SELECT Id FROM Profile WHERE Name = 'SCG-Retail Finance' LIMIT 1];
        Profile retailCentreMgtProf = [SELECT Id FROM Profile WHERE Name = 'SCG-Retail CentreMgt' LIMIT 1];
        
        UserRole retailCRMRole = [SELECT Id FROM UserRole WHERE Name='Retail CRM' LIMIT 1];
        User retailFinance = TestDataFactory.createUniqueTestUser('John', 'Doe', retailFinanceProf.Id);
        User retailCentreMgt = TestDataFactory.createUniqueTestUser('John', 'Doe', retailCentreMgtProf.Id);
        retailFinance.UserRoleId = retailCRMRole.Id;
        retailCentreMgt.UserRoleId = retailCRMRole.Id;        
        system.runAs(retailCentreMgt) {
            for(Space__c space : spaceList){
                space.RentableArea__c = 40;
                space.DevelopmentType__c = null;
                space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
            }
            
            Database.insert(spaceList);
            
            
            
            //CREATE OPPORTUNITY
            Integer counter = 0;
            accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
            for(Account acc : accountList){
                opportunityTempList = TestDataFactory.createOpportunity(1, acc);
                
                for(Opportunity opp : opportunityTempList){
                    opp.JDESentStatus__c = 'Ready';
                    opp.Space__c = spaceList[counter].Id;
                    counter++;
                }
                
                opportunityList.addAll(opportunityTempList);
            }
            
            database.insert(opportunityList);
            
            for(Opportunity opp : opportunityList){
                spaceIdOpportunityMap.put(opp.Space__c, opp);
            }
            
            
            
            for(Space__c spc : spaceList){
                spc.LatestAchievedOpportunity__c = spaceIdOpportunityMap.get(spc.Id).Id;
                spc.Status__c = 'Trading';
                spc.RentableArea__c = 50;
            }
            spaceList[0].Status__c = 'Inactive';
            TriggerHandler.clearBypass('SpaceTriggerHandler');
            
            try {
                spaceList[0].Type__c = '4';
            	Database.update(spaceList[0]);    
            } catch (Exception e) {
                system.assert(e != null, 'Error not triggered');
            }
            
            try {
                spaceList[1].Type__c = '4';
                Database.update(spaceList[1]);
                system.assert(spaceList[1].Type__c == '4', 'Update Failed');
            } catch (Exception e) { 
                
            }
            
            
            
            test.stopTest();
        }
    }
}