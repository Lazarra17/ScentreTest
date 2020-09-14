/*
* @author:              Kyle Tan
* @description:         Test class for AccountBL
*/
@isTest
private class AccountBLTest {
    
    @TestSetup private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Property__c> tempPropertyList = new List<Property__c>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accountList = new List<Account>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        Account accountRecord = new Account();
        Integer propertySize = 50;
        
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        propertyList.addAll(TestDataFactory.createProperty(propertySize - 25, pricebookList[0]));
        
        //PROPERTY WITHOUT SHORTNAME
        tempPropertyList.addAll(TestDataFactory.createProperty(propertySize - 25, pricebookList[0]));
        
        for(Property__c prop : tempPropertyList) {
            prop.PropertyShortName__c = null;
        }
        
        propertyList.addAll(tempPropertyList);
        
        insert propertyList;
        
        Map<Id, Property__c> propertMap = new Map<Id, Property__c>();
        propertyList = [SELECT Id, PropertyShortName__c FROM Property__c LIMIT :propertySize];

        propertMap.putAll(propertyList);
        
        List<Space__c> spaceList = new List<Space__c>();

        for(Property__c prop : propertyList){
            spaceList.addAll(TestDataFactory.createSpace(1, prop));
        }

        insert spaceList;

        List<Lead> leadList = new List<Lead>();
        for(Space__c space : spaceList){
            leadList.addAll(TestDataFactory.createLead(1, null, propertMap.get(space.Property__c), space));
        }
        insert leadList;


        //CREATE ACCOUNT
        propertySize = 0;
        for(Integer counter = 0; counter < 300; counter++) {
            if(propertySize == 50) {
                propertySize = 0;
            }
            if(counter < 100) {
                accountRecord = TestDataFactory.createAccount(counter, propertyList.get(propertySize).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId());
            	
            } else if(counter >= 100 && counter < 200) {
                accountRecord = TestDataFactory.createAccount(counter, propertyList.get(propertySize).Id, accountRecordTypeMapByName.get(CONSTANTS.GROUP_LEVEL).getRecordTypeId());
            } else {
                accountRecord = TestDataFactory.createAccount(counter, propertyList.get(propertySize).Id, accountRecordTypeMapByName.get(CONSTANTS.THIRD_PARTY).getRecordTypeId());
            }
            accountRecord.BillingCity = 'test city';
            accountRecord.BillingStreet = 'test street';
            accountRecord.BillingStateCode = 'TAS';
            accountRecord.BillingPostalCode = '090';
            accountRecord.BillingCountryCode = 'AU';
            accountList.add(accountRecord);
            propertySize++;
        }
        
        insert accountList;
        
        
        
    }
    
    /**
    *@author:           Kyle Tan
    *@description:      test class for renameAccount method in AccountBL
    **/
    public static testMethod void renameAccountTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Account accountRecord = new Account();
        List<Account> assertAccountList = new List<Account>();
        List<Account> assertNoShortNameAccountList = new List<Account>();
        List<Account> accountList = new List<Account>([SELECT Id, TradingName__c, Property__c FROM Account WHERE Property__r.PropertyShortName__c != null]);
        List<Account> noShortNameAccountList = new List<Account>([SELECT Id, TradingName__c FROM Account WHERE Property__r.PropertyShortName__c = null]);
        
        System.runAs(testUser) {
            Test.startTest();
            for(Account acc : accountList) {
                accountRecord = AccountBL.renameAccount(acc, CONSTANTS.TEST);
                assertAccountList.add(accountRecord);
            }
            for(Account acc : noShortNameAccountList) {
                accountRecord = AccountBL.renameAccount(acc, '');
                assertNoShortNameAccountList.add(accountRecord);
            }
            Test.stopTest();
        }
        
        for(Account acc : assertAccountList) {
            System.assertEquals(acc.TradingName__c + ' - ' + CONSTANTS.TEST, acc.Name);
        }
        for(Account acc : assertNoShortNameAccountList) {
            System.assertEquals(acc.TradingName__c, acc.Name);
        }
    }

    /**
     * @author:             Yana Navarro
     * @description:        test class for copyBillingToShippingAddress method
     **/
    public static testMethod void testCopyBillingToShippingAddress(){        
        Set<Id> accountIdSet = new Set<Id>();
        List<Account> accountList = [SELECT Id, BillingCity, BillingStreet, BillingStateCode, BillingPostalCode, BillingCountryCode FROM Account LIMIT 1];
        List<Property__c> propertyList = [SELECT Id FROM Property__c];
        

        Test.startTest();
        for(Account accountRecord : accountList){
			AccountBL.copyBillingToShippingAddress(accountRecord);
        }
        
        Test.stopTest();

        for(Account acc : accountList){
            accountIdSet.add(acc.Id);
        }

        accountList = [SELECT Id, TechConvertedLeadId__c, ShippingCity, ShippingStreet, ShippingStateCode, 
                        ShippingPostalCode, ShippingCountryCode 
                       FROM Account 
                       WHERE Id IN: accountIdSet];

        for(Account acc : accountList){
            if(acc.TechConvertedLeadId__c != null){
                system.assertEquals(acc.ShippingCity, 'test city');
                system.assertEquals(acc.ShippingStreet, 'test street');
                system.assertEquals(acc.ShippingStateCode, 'TAS');
                system.assertEquals(acc.ShippingPostalCode, '090');
                system.assertEquals(acc.ShippingCountryCode, 'AU');
            }
        }
    }
    
    /**
     * @author:         Kyle Tan
     * @description:    test method for generateAccountEvents method
     **/
    private static testMethod void testGenerateAccountEvents() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<String> payloads = new List<String>();
        List<AccountEvent__e> accountEventList = new List<AccountEvent__e>();
        payloads.add(Constants.ACC_CON_RELATION_BILLING);
        payloads.add(Constants.ACC_CON_RELATION_SALES);
        
        system.runAs(testUser) {
            test.startTest();
            accountEventList = AccountBL.generateAccountEvents(payloads);
            test.stopTest();
        }
        for(AccountEvent__e accountEventRec : accountEventList) {
            system.assert(payloads.contains(accountEventRec.JsonPayload__c));
            
        }
    }
    
    /**
     * @author:             Kyle Tan
     * @description:        test method for accountEventTriggerCriteriaCheck method
     **/
    private static testMethod void testAccountEventTriggerCriteriaCheck() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<Id, Account> accountAssertMap = new Map<Id, Account>();
        List<Pricebook2> pricebookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 where CurrencyIsoCode != null];
        List<Property__c> propRec = [SELECT Id, Name, PropertyShortname__c, CurrencyIsoCode FROM Property__c];
        Property__c propertyRecord = new Property__c();
        propertyRecord.Name = 'Test Property ' + 1;
        propertyRecord.PropertyShortName__c = 'ABC ' + 1;
        propRec[0].CurrencyIsoCode = pricebookRec[0].CurrencyIsoCode;
        propertyRecord.CurrencyIsoCode = pricebookRec[0].CurrencyIsoCode;
        propertyRecord.PriceBook__c =  pricebookRec[0].id;
        //system.debug('This is property currenty  '+propertyRecord.CurrencyIsoCode+ '  '+pricebookRec[0].CurrencyIsoCode);
        insert propertyRecord;
        
        list<account> accs = new list<account>();
        account acc1 = new account ();
        acc1.name = 'Test Account';
        acc1.property__c = propertyRecord.id;
        acc1.BillingCity = 'test city11';
        acc1.BillingStreet = 'test street1';
        acc1.BillingStateCode = 'TAS';
        acc1.BillingPostalCode = '09011';
        acc1.BillingCountryCode = 'AU';
        acc1.BillingEmailAddress__c = 'test11@sample.com';
        acc1.TradingName__c = 'ABCZ 11' +1;
        acc1.ShippingCountry = 'Australia';
        acc1.ShippingStreet = '1234 11 Test Street Drive';
        acc1.ShippingCity = 'Syndey';
        acc1.ShippingState = 'Queensland';
        acc1.ShippingPostalCode = '1234';
        acc1.Category__c = 'S420';
        acc1.SuperfineCategory__c = 'S421';
        accs.add(acc1);
        
        insert accs;
        
        
        List<Account> accountList = new List<Account>([SELECT Id, Property__c FROM Account]);
        // added by Melissa Carino
        for(account accRec: accountList){
            accRec.BillingCity = 'test city';
            accRec.BillingStreet = 'test street';
            accRec.BillingStateCode = 'TAS';
            accRec.BillingPostalCode = '090';
            accRec.BillingCountryCode = 'AU';
            accRec.BillingEmailAddress__c = 'test@sample.com';
            accRec.RecordTypeId =  accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId(); 
            
                   
        }
        
        
        update accountList;
        
        map<id,account> accmapfalse = new map<id,account>([select id from account where id in: accountList]);
        
   /*   Pricebook2 pb = TestDataFactory.createcustomPB();
        insert pb;
        Product2 prod = TestDataFactory.createRentReview(pb);
        insert prod;
        
        List<Property__c> lstProp = new List<Property__c>();
        lstProp = TestDataFactory.createProperty(1, pb);
        insert lstProp;
    */  
        // CREATE PB
        List<Pricebook2> pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);
        pricebookList = [SELECT Id, CurrencyIsoCode FROM Pricebook2];
        
        //CREATE PROPERTY
        List<Property__c> lstProp = new List<Property__c>();
        lstProp = TestDataFactory.createProperty(1, pricebookList[0]);
        database.insert(lstProp);
        
         Property__c pp = [select id from Property__c where id =: accs[0].Property__c];
        List<Space__c> lstSpace= new List<Space__c>();
        lstSpace = TestDataFactory.createSpace(1,pp);//(1, lstProp[0]);
        database.insert(lstSpace);
        
        Map<String, Schema.RecordTypeInfo> OppRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OPPORTUNITY);
        List<Opportunity> lstOpp = new List<Opportunity>();
       // lstOpp = TestDataFactory.createIssueLeaseOpportunity(acc1, pb, lstSpace[0], lstProp[0], OppRecordTypeMapByName.get(CONSTANTS.OPP_RETAIL_LEASING).getRecordTypeId());
       
        lstOpp = TestDataFactory.createIssueLeaseOpportunity(accs, pricebookList[0], lstSpace[0],pp, OppRecordTypeMapByName.get(CONSTANTS.OPP_RETAIL_LEASING).getRecordTypeId());
        
        //system.debug(lstopp[0].Account.RecordType.DeveloperName);
        //system.debug(lstopp[0].property__c);
        //system.debug(lstopp[0].account.property__c);
       // system.debug(lstopp[0].Space_c.property__c);
        
        for(opportunity op: lstOpp){
            op.JDESentStatus__c = 'Ready';
        }
        upsert lstOpp;
   
        
        List<OpportunityClause__c> lstOppclause = new List<OpportunityClause__c>();
        for (Opportunity OppRec: lstOpp ){
            OpportunityClause__c Oppclause = TestDataFactory.CreateOppClause(OppRec);
            lstOppclause.add(Oppclause);
        }
        insert lstOppclause;
                
        /*Id standardPB = Test.getStandardPricebookId(); 
        List<PricebookEntry> OppProds = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        OppProds.add(standardPrice);     

        PricebookEntry pbe =new PricebookEntry(unitprice=0.01,Product2Id=prod.Id,Pricebook2Id=pb.Id,
                                                isActive=true,UseStandardPrice = false);
        OppProds.add(pbe);
        insert OppProds;
        
        for (Opportunity OppRec: lstOpp ){
            OpportunityLineItem OppLineItem = TestDataFactory.createOpportunityLineItem(1, OppRec, prod, pbe);
        }
        **/
        
        for( integer counter = 0; counter < lstOpp.size(); counter++){
            lstOpp[counter].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
            lstOpp[counter].ApprovalStatus__c = 'Final Approval Granted';
            lstOpp[counter].BestBet__c = true;
        }
        
        
        
        Set<Id> accountIdSet = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        accountList[3].ParentId = accountList[2].Id;
        accountList[2].ParentId = accountList[0].Id;
        TriggerHandler.clearAllBypasses();
        database.update(accountList);
        update lstOpp[0];
       
       
        
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, ParentId FROM Account]);
         for(Id accountId : accountMap.keySet()) {
            accountIdSet.add(accountId);
             }
       AccountEvent__e inkEvent = new AccountEvent__e(JsonPayload__c='MN-123');
    set<id> parentidss = new set<id>();
        for(account acnt: accountMap.values()){            
            parentidss.add(acnt.parentid);
        }
    opportunity opli = [select id, name, accountid from opportunity where accountid not in :parentidss limit 1]; 
        account acstt = [select id, name, ParentId from account where id =: opli.accountid];
        accountMap.put(acstt.id,acstt);
       
        
        system.runAs(testUser) {
            test.startTest();
            Database.SaveResult sr = EventBus.publish(inkEvent);
            accountAssertMap = AccountBL.accountEventTriggerCriteriaCheck(accountMap);
            AccountBL.accountEventTriggerCriteriaCheck(accmapfalse);
            test.stopTest();
        }
    }
    
     /**
     * @author:             Kyle Tan
     * @description:        test method for updateAccountWhenAccountEventSentSuccess method
     **/
    private static testMethod void testUpdateAccountWhenAccountEventSentSuccess() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<AccountEvent__e> accountEventList = new List<AccountEvent__e>();
        List<String> payloads = new List<String>();
        List<Account> accountList = [SELECT Id FROM Account LIMIT 200];
        Account accountRec = new Account();
        
        DateTime dt = System.now();
        
        String st = '{\n' +
            ' "ID" : "'+ accountList[0].id +'",\n' +
            ' "TECHDISPATCHEDTIMESTAMP__C" : "'+ dt +'",\n' +
            ' "TECHDISPATCHEDVERSION__C" : "'+ CONSTANTS.NUMBER_ONE +'"\n' +
            '}';
        payloads.add(st);
        
        accountEventList = AccountBL.generateAccountEvents(payloads);
        //system.debug(' this is accoutn event  '+accountEventList.size());
        system.runAs(testUser) {
            test.startTest();
            AccountBL.updateAccountWhenAccountEventSentSuccess(accountEventList);
            test.stopTest();
        }
        
        accountRec = [SELECT Id, TechDispatchedTimeStamp__c, TechDispatchedVersion__c FROM Account WHERE Id = :accountList[0].Id LIMIT 1];
        System.assertEquals(accountList[0].Id, accountRec.Id);
        System.assertEquals(dt.addHours(8), accountRec.TechDispatchedTimeStamp__c);
        System.assertEquals(1, accountRec.TechDispatchedVersion__c);
    }
    
}