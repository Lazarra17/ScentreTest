/**
 * @author:				Kyle Tan
 * @desc:				Test Class for OpportunityChatterNotificationHelper
 **/
@isTest
private class OpportunityChatterNotificationHelperTest {

    @testSetup
    static void testSetup() {
        //Create Users
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        List<User> userList = new List<User>();
        User userRecord = new User();
        for(Integer i = 0; i < 2; i++) {
            userRecord = TestDataFactory.createUniqueTestUser('fName' + i, 'lName' + i, profileRec.Id);
            userRecord.IsActive = true;
            userList.add(userRecord);
        }
        database.insert(userList);
        
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
        accountList = TestDataFactory.createAccountBulk(5, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(accountList);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        database.insert(spaceList);
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = TestDataFactory.createOpportunity(1, accountList[0], propertyList[0], spaceList[0]);
        for(Opportunity oppRec :oppList) {
            oppRec.GMLARS__c = userList[0].Id;
            oppRec.RMLARS__c = userList[0].Id;
            oppRec.GMRetailAdmin__c = userList[0].Id;
            oppRec.DirectorLARSNZDevelopment__c = userList[0].Id;
            oppRec.CorporateLegal__c = userList[0].Id;
            oppRec.COO__c = userList[0].Id;
        }
        database.insert(oppList);
        
        //Create Property Team
        List<PropertyTeam__c> propTeamList = new List<PropertyTeam__c>();
        Map<String, Schema.RecordTypeInfo> propTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PROPERTY_TEAM_API);
        propTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 'Leasing Executive', userList[0].Id, propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        propTeamList.add(TestDataFactory.createPropertyTeam(propertyList[0].Id, 'Retail Administrator', userList[1].Id, propTeamRecordTypeMapByName.get(Constants.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId()));
        database.insert(propTeamList);
        
        //Create Clause Library
        List<ClauseLibrary__c> clauseLibraryList = new List<ClauseLibrary__c>();
        clauseLibraryList = TestDataFactory.createClauseLibrary(1);
        clauseLibraryList[0].RiskClauseNotifyUsers__c = 'Leasing Executive; Retail Administrator';
        database.insert(clauseLibraryList);
        
        //Create Opportunity Clause
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        oppClauseList = TestDataFactory.createOpportunityClause(2, oppList[0], clauseLibraryList[0]);
        database.insert(oppClauseList);
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void pendingRiskApprovalTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.PENDING_RISK_APRV;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void riskApprovalGrantedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.RMRISK_APPRGRANTED;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void finalApprovalGrantedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.FINALAPPR_GRANT;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void rmApprovalGrantedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.RMAPPR_GRANTED;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void licenseGrantedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.STRAPPOVALGRANTED;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void riskApprovalRejectedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.RM_APPV_REJ;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void finalApprovalRejectedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.RISK_APPRV_REJ;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void rmApprovalRejectedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.FINALAPPR_REJ;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
    
    /**
     * @author:				Kyle Tan
     **/
    @isTest
    static void licenseRejectedTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, Property__c, OwnerId, Name, 
                                                                   ApprovalStatus__c, GMLARS__c, RMLARS__c, 
                                                                   GMRetailAdmin__c, DirectorLARSNZDevelopment__c, 
                                                                   CorporateLegal__c, COO__c 
                                                                   FROM Opportunity]);
        List<ChatterPostUtil.chatterNotificationWrapper> chatterWrapperList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        opportunityList[0].ApprovalStatus__c = Constants.STRAPPOVALREJ;
        system.runAs(testUser) {
            test.startTest();
            chatterWrapperList = OpportunityChatterNotificationHelper.preparedatafornotification(opportunityList);
            test.stopTest();
        }
    }
}