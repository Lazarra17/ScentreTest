/**
 * @author:			Kyle Tan
 * @description:	Test Class for ContactBL
 **/
@isTest
private class ContactBLTest {
    
    @testSetup
    private static void testSetup(){
        List<Property__c> propertyList = new List<Property__c>();
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        List<AccountContactRelation> accConRecList = new List<AccountContactRelation>([Select Id, ContactId, AccountId From AccountContactRelation]);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> opportunityRecTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        Contact conRec = new Contact();
        Pricebook2 pricebookRec = new Pricebook2();
        
        //Create Pricebook
        pricebookRec = TestDataFactory.createPricebook();
        pricebookRec.CurrencyIsoCode = 'AUD';
        database.insert(pricebookRec);
        
        //Create Property
            propertyList = TestDataFactory.createProperty(10, pricebookRec);
            database.insert(propertyList);
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
        
        //Create Contact
        conRec = TestDataFactory.createContact('Test Contact', account);
        database.insert(conRec);
        
        
        
        accConRecList = [SELECT AccountId FROM AccountContactRelation];
    //    accountList = [SELECT Id FROM Account WHERE Id = :accConRecList[0].AccountId];
        
        //Create Opportunity
        oppList = TestDataFactory.createOpportunity(1, 'Test Opp', Constants.UNDERSTAND_NEGOTIATE, account, pricebookRec);
        oppList[0].TermYr__c = 1;
        oppList[0].PromoLevyIncluded__c = 'No';
        oppList[0].RecordTypeId = opportunityRecTypeMap.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
        oppList[0].JDESentStatus__c = 'Ready';
        database.insert(oppList);
        
        //Create Clause Library
        clauseLibList = TestDataFactory.createClauseLibrary(1);
        database.insert(clauseLibList);
        
        //Create Opportunity Clause
        oppClauseList = TestDataFactory.createOpportunityClause(1, oppList[0], clauseLibList[0]);
        oppClauseList[0].Type__c = 'Usage';
        database.insert(oppClauseList);
        
        oppList[0].StageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
        oppList[0].ApprovalStatus__c = ' Final Approval Granted';
        database.update(oppList);
        
    }

    /**
     * @author:			Kyle Tan
     * @description:	Test method for constructBaseStructureFromContact method
     **/
    private static testMethod void testConstructBaseStructureFromContact() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, Contact> oldConMap = new Map<Id, Contact>();
        Map<Id, Contact> newConMap = new Map<Id, Contact>();
        List<Id> activeContactIds = new List<Id>();
        List<Id> newActiveContactIds = new List<Id>();
        List<AccountContactRelation> accConRecList = new List<AccountContactRelation>([Select Id, ContactId, AccountId From AccountContactRelation]);
        for(Contact conRec : [SELECT Id, FirstName FROM Contact WHERE Id = :accConRecList[0].ContactId]) {
            oldConMap.put(conRec.Id, conRec);
            conRec.FirstName = 'Mary';
            conRec.LastName = 'Poppins';
            conRec.Comments__c = 'Test new comments';
            newConMap.put(conRec.Id, conRec);
        }
        activeContactIds = EventpublishHelper.contactFieldChangePublishHelper(oldConMap, newConMap);
        newActiveContactIds.add(accConRecList[0].ContactId);
        //system.runAs(testUser) {
            test.startTest();
            ContactBL.ContactWithFinalizedOppoWrapper contactWrapper = ContactBL.constructBaseStructureFromContact(newActiveContactIds);
            test.stopTest();
       // }
    }
    
    /**
     * @author:			Kyle Tan
     * @description:	Test method for constructPE method
     **/
    private static testMethod void testConstructPE() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_RETAIL_ADMIN LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<AccountContactRelation> accountContactRelationList = [SELECT Id FROM AccountContactRelation LIMIT 1];
        List<Id> acrRelation = new List<Id>();
        Map<Id, List<Id>> contactToACRMap = new Map<Id, List<Id>>();
        for(AccountContactRelation acr : accountContactRelationList){
            acrRelation.add(acr.Id);
        }
        
        List<Contact> contactList = [SELECT Id FROM Contact LIMIT 1];
        Set<Id> contactIdSet = new Set<Id>();
        List<AccountContactEvent__e> assertData = new List<AccountContactEvent__e>();
        
        for(Contact conRec : contactList){
            contactIdSet.add(conRec.Id);
        }
        
        contactToACRMap.put(contactList[0].Id, acrRelation);
        
        ContactBL.ContactWithFinalizedOppoWrapper contactWrapper = new ContactBL.ContactWithFinalizedOppoWrapper();
        contactWrapper.sendEvent = true;
        contactWrapper.contacts = contactIdSet;
        contactWrapper.accountContactRelations  = acrRelation;
        contactWrapper.contactToACRMap = contactToACRMap;
       
       
            
            
        //system.runAs(testUser) {
            test.startTest();
            assertData = ContactBL.constructPE(contactWrapper);
            test.stopTest();
        //}
    }
    
    public static testMethod void testEventSentSuccess(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<String> payloads = new List<String>();
        List<Contact> contactList = new List<Contact>();
        Contact contactRec = new Contact();
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        
        contactList = [SELECT Id FROM Contact LIMIT 1];
        String contactId = contactList[0].Id;
        DateTime dt = System.now();
        
        
        String jsonInput = '{\n' +
            ' "ID" : "'+ contactId +'",\n' +
            ' "TECHDISPATCHEDTIMESTAMP__C" : "'+ dt +'",\n' +
            ' "TECHDISPATCHEDVERSION__C" : "'+ CONSTANTS.NUMBER_ONE +'"\n' +
            '}';
        payloads.add(jsonInput);
        
        List<AccountContactEvent__e> accountContactEventsList = new List<AccountContactEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                AccountContactEvent__e acEvt = new AccountContactEvent__e();
                acEvt.ContactPayload__c = payload;
                accountContactEventsList.add(acEvt);
            }
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            results = EventBus.publish(accountContactEventsList);
            
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                    ContactBL.updateContactWhenAddressBookEventSentSuccess(accountContactEventsList);
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }       
            }
            
            Test.stopTest();
        }
        //Assertion
        //spaceRec = [SELECT Id, TechDispatchedTimeStamp__c, TechDispatchedVersion__c FROM Space__c WHERE Id = :spaceId LIMIT 1];
        //System.assertEquals(spaceId, spaceRec.Id);
        //System.assertEquals(dt.addHours(7), spaceRec.TechDispatchedTimeStamp__c);
        //System.assertEquals(1, spaceRec.TechDispatchedVersion__c);
    }
    
    
}