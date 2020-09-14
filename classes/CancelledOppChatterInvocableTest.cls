/*
 *	@description: Test class for CancelledOppChatterInvocable
 *	@startdate: 8/8/2019
 *
 */
@isTest
public class CancelledOppChatterInvocableTest {
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByDeveloperName = RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.OPPORTUNITY);
        
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Space__c> spaceList = new List<Space__c>();
        List<Contract__c> contrList = new List<Contract__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        // CREATE PRICEBOOK
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        // CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        for(Property__c property : propertyList){
            property.PriceBook__c = priceBookRec.Id;
        }
        Database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];


        Set<String> teamRolesToNotify = new Set<String>{ 
            	Constants.TEAM_ROLE_AT,
                Constants.TEAM_ROLE_RDC,
                Constants.TEAM_ROLE_RDM, 
                Constants.TEAM_ROLE_RMR_DESIGN, 
                Constants.TEAM_ROLE_RMR_DELIVERY,
                Constants.TEAM_ROLE_RA
                };
                    

                    
		Id internalTeamRecTypeId;
        List<PropertyTeam__c> propertyTeamList = new List<PropertyTeam__c>();
        Map<String,Schema.RecordTypeInfo> propertyTeamRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName('PropertyTeam__c');
        
        internalTeamRecTypeId = propertyTeamRecordTypeMap.get('PRT - Internal Team Member').getRecordTypeId();
        
        
        List<PropertyTeam__c> propTeams = new List<PropertyTeam__c>();
        List<User> testUserList = new List<User>();
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        Map<String, User> userRoleMap = new Map<String, User>();
        for (String role : teamRolesToNotify) { 
            User newUser = TestDataFactory.createUniqueTestUser('Test', ' ' + role, profileRec.Id);
            testUserList.add(newUser);
            userRoleMap.put(role, newUser);
        }
        
        database.insert(testUserList);  
        
        for (String role : teamRolesToNotify) {
            PropertyTeam__c propteam = TestDataFactory.createPropertyTeam(propertyList[0].id, role,  userRoleMap.get(role).Id, internalTeamRecTypeId);
            propTeams.add(propteam);
        }
        database.insert(propTeams);      
        system.debug('PROP TEAM ' + propTeams);
        
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accountList);
        
        // CREATE SPACE
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].type__c = '1';
        spaceList[0].BillingCategory__c = 'NA';
        database.insert(spaceList);
        
        //CREATE CONTRACT
        spaceList = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceList[0].id;
        database.insert(contrList);
        
        //CREATE OPPORTUNITY
        Id retailOppRecTypeId = oppRecordTypeMapByDeveloperName.get(Constants.OPP_RETAIL_LEASING_API_NAME).getRecordTypeId();
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceList);
        opportunityList[0].RecordTypeId = retailOppRecTypeId;
        database.insert(opportunityList);
    }
    @isTest private static void testCancelledOppChatterPost() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Id> opptyIds = new List<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name, Property__c FROM Opportunity WHERE RecordType.Name='Retail Leasing' AND Property__c != null LIMIT 1]);

        Map<Id, Map<String, PropertyTeam__c>> propTeamMembersMap = DatabaseSOQLBank.getPropertyTeamByProperty(new Set<Id>{oppMap.values().get(0).Property__c});
        system.debug('PROP TEAM ' + oppMap);
        system.debug('PROP TEAM ' + propTeamMembersMap);
        //System.runAs(testUser) {
            Test.startTest();
            CancelledOppChatterInvocable.postChatterToPropTeam(new List<Id>(oppMap.keySet()));
            Test.stopTest();
        //}
        
        // Assertions        
        List<FeedItem> chatterFeedList = [SELECT Id, ParentId, CreatedById FROM FeedItem LIMIT 10];
        for (FeedItem ci : chatterFeedList) {
            System.assertNotEquals(null, ci.Body);
            System.assertEquals(testUser.Id, ci.CreatedById);
        }
    }    
}