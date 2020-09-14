/*
* @author:              Sidney Garcia
* @description:         Test class for ChatterPostUtil
*/
@isTest
public class ChatterPostUtilTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> caseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OBJECT_CASE);
        Product2 productRecord;
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Account> tempAccountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<contact> contactList = new list<contact>();
        List<case> caseList = new list<case>();
        List<User> userList = new List<User>();
        List<Contract__c> contrList = new List<Contract__c>();
        List<Space__c> spaceLst = new List<Space__c>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        //System.debug('Pricebook rec ' + priceBookRec);
        
        propertyList = TestDataFactory.createProperty(1);
        for(Property__c property : propertyList){
            property.PriceBook__c = priceBookRec.Id;
        }
        Database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 5];
        //CREATE ACCOUNT
        accountList.addAll(TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        
        database.insert(accountList);
        //System.debug('Account List ' + accountList);
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c, Name FROM Account LIMIT 1];
        
        //CREATE SPACE
        spaceLst = TestDataFactory.createSpace(1, propertyList[0]);
        spaceLst[0].type__c = '1';
        spaceLst[0].BillingCategory__c = 'NA';
        database.insert(spaceLst);
        
        //CREATE CONTRACT
        spaceLst = [SELECT Id, Type__c FROM Space__c];
        contrList = TestDataFactory.createContract(1, accountList[0]);
        contrList[0].space__c = spaceLst[0].id;
        database.insert(contrList);
        
        opportunityList = TestDataFactory.createOpportunity(1, accountList[0], propertyList, spaceLst);
        //System.debug('Opportunity List' + opportunityList);
        database.insert(opportunityList);
        
        
        
        //CREATE CASE
        Set<string> CaseRecordtypeNames = new set<string>();
        CaseRecordtypeNames.add(CONSTANTS.RETAIL_DESIGN_INSTRUCTION);
        CaseRecordtypeNames.add(CONSTANTS.UPDATE_PROMOTIONAL_ALLOWANCE);
        CaseRecordtypeNames.add(CONSTANTS.MISCELLANEOUS_SERVICE);
        CaseRecordtypeNames.add(CONSTANTS.VARIANCE_TO_RENT_COMMENCEMENT);
        CaseRecordtypeNames.add(CONSTANTS.REQUEST_FOR_REFUND);
        CaseRecordtypeNames.add(CONSTANTS.CONDUCT_MARKET_REVIEW);
        CaseRecordtypeNames.add(CONSTANTS.LEASE_AREA_VARIATION);
        CaseRecordtypeNames.add(CONSTANTS.MANAGE_BANK_GUARANTEE);
        CaseRecordtypeNames.add(CONSTANTS.SURRENDER_A_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.TERMINATE_A_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.ASSIGN_OF_A_LEASE);
        CaseRecordtypeNames.add(CONSTANTS.TRADING_NAME_CHANGE);
        CaseRecordtypeNames.add(CONSTANTS.CREDIT_NOTE);
        CaseRecordtypeNames.add(CONSTANTS.CENTRE_TEAM);
        CaseRecordtypeNames.add(CONSTANTS.LEASING_FINANCE);
        CaseRecordtypeNames.add(CONSTANTS.MISCELLANEOUS_LEASE);
        
        
        List<Case> lstCase = new List<Case>();
        for(string CaseRecTypeName : CaseRecordtypeNames){
            case caseRec = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CaseRecTypeName).getRecordTypeId(), contrList[0].Id);
            
            if(CaseRecTypeName == CONSTANTS.CENTRE_TEAM){
                caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_BAD_DEBIT_WRITE_OFF;
            }else if(CaseRecTypeName == CONSTANTS.LEASING_FINANCE){
                caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_BILLING_OF_PERCENT_RENT;
            } else if(CaseRecTypeName == Constants.MISCELLANEOUS_LEASE){
                //caseRec.SubType__c = Constants.CASE_SUBTYPE_LEASING_FINANCE;
            }
            lstCase.add(caseRec);
        }
        for(Integer i = 0; i<3; i++){
            Case caseRec;
            if(i==0){
                caseRec = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CONSTANTS.CENTRE_TEAM).getRecordTypeId(), contrList[0].Id);
                caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_BAD_DEBIT_WRITE_OFF;
            }else if (i==1){
                caseRec = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CONSTANTS.CENTRE_TEAM).getRecordTypeId(), contrList[0].Id);
                caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_BAD_DEBIT_WRITE_OFF;
            }else if(i==2){
                caseRec = TestDataFactory.CreateCase(accountList[0], caseRecordTypeMapByName.get(CONSTANTS.LEASING_FINANCE).getRecordTypeId(), contrList[0].Id);
                caseRec.SubType__c = CONSTANTS.CASE_SUBTYPE_CAPPED_OCCUPANCY_COST;
            }
            lstCase.add(caseRec);
            
        }
        
        database.insert(lstCase);
        
        for(Integer i = 0; i < 10; i++){
            User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME + ' ' + i, CONSTANTS.TEST_LNAME + ' ' + i, profileRec.Id);
            userList.add(testUser);
        }
        Database.insert(userList); 
    }
    
    public static testMethod void testChatterPostNotificationHelper(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        Opportunity oppRecord = [SELECT ID,name,GMLARS__c, RMLARS__c, GMRetailAdmin__c,DirectorLARSNZDevelopment__c,CorporateLegal__c, COO__c from Opportunity LIMIT 1];
        oppRecord.GMLARS__c = userinfo.getUserId();
        oppRecord.RMLARS__c = userinfo.getUserId();
        oppRecord.GMRetailAdmin__c = userinfo.getUserId();
        oppRecord.DirectorLARSNZDevelopment__c = userinfo.getUserId();
        oppRecord.CorporateLegal__c = userinfo.getUserId();
        oppRecord.COO__c = userinfo.getUserId();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update oppRecord;
        List<Id> userLstToChatter = new List<Id>();
        userLstToChatter.add(userinfo.getuserid());
        Id recordId = oppRecord.Id;
        Set<Id> userIdList = new Set<Id>();
        List<ConnectApi.BatchInput> batchInputListTest = new List<ConnectApi.BatchInput>();
        List<User> userList = [SELECT Id FROM User LIMIT 10];
        for(User userId : userList){
            userIdList.add(userId.Id);
        }
        List<ChatterPostUtil.chatterNotificationWrapper> chatterList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        ChatterPostUtil.chatterNotificationWrapper notifWrapper = new ChatterPostUtil.chatterNotificationWrapper();
        
        notifWrapper.subjectId = recordId;
        notifWrapper.mentionedUsers = userIdList;
        notifWrapper.body = CONSTANTS.TEST;        
        chatterList.add(notifWrapper);
                    /*account ac = [select id from account limit 1];
            Map<Id,List<Id>> caseIDUsersToNotifLstMap = new map<id,list<id>>();
            list<id> lID = new list<id>();
            lID.add(userinfo.getuserid());
            caseIDUsersToNotifLstMap.put(userinfo.getuserid(),lId);
            
            property__C prop = new property__c();
            prop.name='Test';
            insert prop;
            
            space__C spac = new space__c();
            spac.name ='Test';
            spac.Property__c = prop.id;
            spac.BackupRetailer__c = ac.id;
            insert spac;
            
            Contract__c cont = new Contract__c();
            cont.name='Test';
            cont.JDELeaseNumber__c = '123456';
            cont.Account__c = ac.id;
            Cont.Space__c = spac.id;
            insert cont;
            id caseRecordtypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Retail Design Instruction').getRecordTypeId();        
            case createCase = TestDataFactory.createCase(cont,spac,caseRecordtypeid);*/
        
        System.runAs(testUser) {
            Test.startTest();
            batchInputListTest = ChatterPostUtil.chatterPostNotificationHelper(chatterList);
            ChatterPostUtil.ChatterPostToApprovedOpp(oppRecord);
            ChatterPostUtil.ChatterPostToOppRisk(userLstToChatter,oppRecord);
            //ChatterPostUtil.ChatterPostToCaseRecord(createCase,caseIDUsersToNotifLstMap);
            Test.stopTest();
        }
        
        
        System.assertEquals(true, batchInputListTest <> null);
    }
    
    public static testMethod void testChatterPostBulk(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        Opportunity oppRecord = [SELECT ID from Opportunity LIMIT 1];
        Id recordId = oppRecord.Id;
        Set<Id> userIdList = new Set<Id>();
        List<ConnectApi.BatchInput> batchInputListTest = new List<ConnectApi.BatchInput>();
        for(User userId : [SELECT Id from User LIMIT 10]){
            userIdList.add(userId.Id);
        }
        List<ChatterPostUtil.chatterNotificationWrapper> chatterList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        ChatterPostUtil.chatterNotificationWrapper notifWrapper = new ChatterPostUtil.chatterNotificationWrapper();
        
        notifWrapper.subjectId = recordId;
        notifWrapper.mentionedUsers = userIdList;
        notifWrapper.body = CONSTANTS.TEST;
        
        chatterList.add(notifWrapper);
        
        System.runAs(testUser) {
            Test.startTest();
            ChatterPostUtil.chatterpostBulk(chatterList);
            Test.stopTest();
        }
        
        List<ConnectApi.BatchInput> batchInputs = ChatterPostUtil.chatterPostNotificationHelper(chatterList);
        System.assertEquals(true, batchInputs.size() > 0);        
    }
    
    //Melissa
    public static testMethod void testChatterPostToCaseRecord(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<case> lstCase = new List<Case>();
        String objectName = CONSTANTS.OBJECT_CASE;  // modify as needed
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        
        // Grab the fields from the describe method and append them to the queryString one by one.
        for(String s : objectFields.keySet()) {
            query += ' ' + s + ', ';
        }
        // Manually add related object's fields that are needed.
        query += 'RecordType.Name, CreatedBy.Name, Account.TradingName__c, Account.LesseeName__c, Account.Phone, Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Account.BillingState, Account.BillingCountry, Account.Name, Contract__r.Name FROM ' + objectName; 
        
        
        // Add on a WHERE/ORDER/LIMIT statement as needed
        query += ' LIMIT 100'; // modify as needed
        lstCase = database.query(query);
        //System.debug('Case List Count' + lstCase.size());
        //System.debug('Query ' + query);
        
        
        List<User> lstUser = [Select Id FROM User Limit 10];
        List<Id> UserIds = new List<Id>();
        Map<Id,List<Id>> caseIDUsersToNotifLstMap = new Map<Id,List<Id>>();
        ChatterPostUtil.chatterNotificationWrapper chatterNotifWrapper = new ChatterPostUtil.chatterNotificationWrapper();
        
        for (User userRec: lstUser){
            UserIds.add(userRec.Id);
        }
        
        for (case caserec: lstCase){
            caseIDUsersToNotifLstMap.put(caserec.id, UserIds);
        }
        
        System.runAs(testUser) {
            Test.startTest();
            for (case caserec: lstCase){
                chatterNotifWrapper = ChatterPostUtil.ChatterPostToCaseRecord(caserec, caseIDUsersToNotifLstMap);
            }
            Test.stopTest();
        }
        
        System.assertEquals(true, chatterNotifWrapper <> null);

    }
    
    // --- 4/4/19: Prince
    public static testMethod void testChatterPostToRetailAdmin(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Id> opptyIds = new List<Id>();
        List<ChatterPostUtil.chatterNotificationWrapper> chatterNotif = new List<ChatterPostUtil.chatterNotificationWrapper>();
        List<Opportunity> opportunityList = [SELECT Id, Name FROM Opportunity LIMIT 1];
        for (Opportunity opp : opportunityList) {
            opptyIds.add(opp.Id);
        }
        
        System.runAs(testUser) {
            Test.startTest();
            chatterNotif = ChatterPostUtil.ChatterPostRiskApprovedOpp(opptyIds);
            Test.stopTest();
        }
        
        // Assertions
        System.assertNotEquals(0, chatterNotif.size());
        
        List<Id> subjIds = new List<Id>();
        for (ChatterPostUtil.chatterNotificationWrapper cn : chatterNotif) {
        	subjIds.add(cn.subjectId);
        }
        
        List<FeedItem> chatterFeedList = [SELECT Id, ParentId, CreatedById FROM FeedItem WHERE ParentId IN :subjIds];
        for (FeedItem ci : chatterFeedList) {
            System.assertNotEquals(null, ci.Body);
            System.assertEquals(testUser.Id, ci.CreatedById);
        }
        
    }
    public static testMethod void chatterPostToRevenueAssuranceTest() {
        List<ChatterPostUtil.chatterNotificationWrapper> chatterList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        
        Opportunity opp = [SELECT Id, Property__c, Name, AccountId, Account.TradingName__c, Property__r.Name, Space__r.Name, StageName, (SELECT Id, Name FROM Contracts__r) FROM Opportunity LIMIT 1];
        Set<Id> revAdmins = (new Map<Id,User>([SELECT Id FROM User LIMIT 5])).keySet();
        Test.startTest();
        chatterList.add(ChatterPostUtil.ChatterPostToRevenueAssurance(opp, revAdmins));
        ChatterPostUtil.chatterpostBulk(chatterList);
        Test.stopTest();
        
        List<FeedItem> chatterFeedList = [SELECT Id, ParentId, CreatedById FROM FeedItem WHERE ParentId = :chatterList[0].subjectId];
        for (FeedItem ci : chatterFeedList) {
            System.assertNotEquals(null, ci.Body);
        }
    }    
    
}