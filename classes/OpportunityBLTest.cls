/**
 * @author:              Kyle Tan
 * @description:         Test class for OpportunityBL
 **/
@isTest
private class OpportunityBLTest {
    
    @TestSetup 
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Account accountRecord;
        PrecedentClause__c precedentClauseRecord;
        Account account = new Account();
        List<Account> parentAccList = new List<Account>();
        List<Property__c> propertyList = new List<Property__c>();
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Product2> productList = new List<Product2>();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        Pricebook2 pricebookRecord;
        Product2 productRecord;
        
        //CREATE PRODUCT
        productRecord = TestDataFactory.createProduct(Constants.PRODUCT_RENT_REVIEW, Constants.RENT);
        insert productRecord;
        
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(1);
        propertyList[0].Pricebook__c = priceBookRec.Id;
        database.insert(propertyList);
        propertyList = [SELECT Id FROM Property__c LIMIT 1];
        
        //CREATE PARENT ACCOUNT
        parentAccList.addAll(TestDataFactory.createAccountBulk(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()));
        database.insert(parentAccList);
        parentAccList = [SELECT Id, Property__c FROM Account LIMIT 1];
        
        //CREATE ACCOUNT
        account = TestDataFactory.createAccountwithParent(1, propertyList.get(0).Id, accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId(), parentAccList.get(0).Id);
        database.insert(account);
        account = [SELECT Id, Property__c from Account LIMIT 1];
          
        //CREATE PRECEDENT CLAUSE
        
        for(Integer counter = 0; counter < 20; counter++) {
            precedentClauseRecord = TestDataFactory.createPrecedentClause(counter, account.Id);
            if(counter < 19) {
                precedentClauseRecord.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId();
            } else {
                precedentClauseRecord.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId();
            }
            precedentClauseRecord.StandardReviewTypes__c = 'CPI+1.5';
            precedentClauseList.add(precedentClauseRecord);
        }
        database.insert(precedentClauseList);
        
        // CREATE SPACE
        List<Space__c> spaceList = TestDataFactory.createSpace(2, propertyList[0]);
        database.insert(spaceList);
        
        //CREATE OPPORTUNITY
        opportunityList = TestDataFactory.createOpportunity(20, account);
        for (Opportunity opp : opportunityList) {
            opp.Space__c = spaceList[(Integer) Math.floor(Math.random()*spaceList.size())].Id;
        }
        database.insert(opportunityList);		
        
        //CREATE PRICEBOOK
        pricebookRecord = TestDataFactory.createPricebook();
        database.insert(pricebookRecord);
        pricebookRecord = [SELECT Id FROM Pricebook2 LIMIT 1];
        
        //CREATE PRODUCTS
        productList = TestDataFactory.createProduct(10);
        database.insert(productList);
        
        //CREATE PRICEBOOK ENTRY
        for(Integer i = 0; i < 10; i++) {
            pricebookEntryList.addAll(TestDataFactory.createStandardPriceBookEntry(1, productList[i]));
        }
        database.insert(pricebookEntryList);
        
        
        
    }
    
   /**
    * @author:              Kyle Tan
    * @description:         this method tests if the opportunity clause is copied 
    *                       correctly from the precedent clause
    **/
    public static testMethod void createOpportunityClauseTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        OpportunityClause__c tempOpportunityClauseRecord;
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, PrecedentClause__c> precedentClauseMap = new Map<Id, PrecedentClause__c>([SELECT Id, Name, 
                                                                                          Type__c, Description__c, Comments__c, EffectiveToDate__c, ReferencedClause__c,
                                                                                          ReferencedClause__r.RiskApplies__c, ReferencedClause__r.ReasonRecommendation__c
                                                                                          FROM PrecedentClause__c LIMIT 10]);
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        Map<String, Schema.RecordTypeInfo> opportunityClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OPPORTUNITY_CLAUSE_API);
        
        System.runAs(testUser) {
            
            Test.startTest();
            
            for(PrecedentClause__c precedentClauseRecord : precedentClauseMap.values()) {
                tempOpportunityClauseRecord = OpportunityBL.createOpportunityClause(opportunityRecord, precedentClauseRecord, opportunityClauseRecordTypeMapByName.get(CONSTANTS.PRECEDENT_CLAUSE).getRecordTypeId());
                opportunityClauseList.add(tempOpportunityClauseRecord);
            }
            
            Test.stopTest();
        }
        
        for(OpportunityClause__c opportunityClauseRecord : opportunityClauseList) {
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Name, opportunityClauseRecord.Name);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Type__c, opportunityClauseRecord.Type__c);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Description__c, opportunityClauseRecord.ClauseDetails__c);
            //system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).Comments__c, opportunityClauseRecord.LeasingComment__c);
            system.assertEquals(precedentClauseMap.get(opportunityClauseRecord.TechPrecedentClauseId__c).EffectiveToDate__c, opportunityClauseRecord.EffectiveToDate__c);
        }
    }
    
   /**
    * @author:         Kyle Tan
    * @description:    Test class for CalculateProposedEndDate method
    **/
    public static testMethod void CalculateProposedEndDateTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id, ProposedStartDate__c, TermYr__c, TermMonths__c, TermDays__c FROM Opportunity LIMIT 200]);
        Date dateRecord;
        List<Date> dateList = new List<Date>();
        system.runAs(testUser) {
            
            Test.startTest();
            
            for(Opportunity opportunityRecord : opportunityList) {
                opportunityRecord.ProposedStartDate__c = date.today();
                opportunityRecord.TermYr__c = 0;
                opportunityRecord.TermMonths__c = 0;
                opportunityRecord.TermDays__c = 0;
                opportunityRecord.ProposedEndDate__c = date.today();
                dateRecord = OpportunityBL.CalculateProposedEndDate(opportunityRecord);
                dateList.add(dateRecord);
            }
            Test.stopTest();
        }
    }
    public static testMethod void testgetConcatenatedSpaces(){
        List<Opportunity> oppLst = [select id from Opportunity limit 1];
        List<Id> opportunityIdLst = new List<Id>{oppLst[0].id};
        OpportunityBl.getConcatenatedSpaces(opportunityIdLst);
    }
    public static testMethod void testupdateroleOPPBl() {
		Test.startTest();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> oppRecTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.OPPORTUNITY);
        //Map<String, Schema.RecordTypeInfo> oppRecTypeMapByDeveloperName = RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.OPPORTUNITY);
        Account account = new Account();
        List<Account> parentAccList = [Select id from Account where recordtypeid =: accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId()];

        List<Property__c> propertyList= new List<Property__c>();
         Map<String, Schema.RecordTypeInfo> propTeamRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.PROPERTYTEAM);
        Property__c propertyRec = new Property__c();
        List<User> userList = new List<User>();
        User userRec = new User();
        List<Opportunity> oppList= new List<Opportunity>();
        List<Opportunity> oppRec = new  List<Opportunity>();
        List<Pricebook2> priceBookRec = new List<Pricebook2>();
        List<Pricebook2> pricebookList = new List<Pricebook2>();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        List<ClauseLibrary__c> clauseLibRec = new List<ClauseLibrary__c>();
                //CREATE USER
        userList.add(TestDataFactory.createUniqueTestUser('Test', 'User', profileRec.Id));
        database.insert(userList);
        //CREATE PRICEBOOK
        pricebookList = TestDataFactory.createPricebook(10);
        database.insert(pricebookList);

        //CREATE PROPERTY
        propertyList = TestDataFactory.createProperty(10, pricebookList[0]);
        database.insert(propertyList);
        parentAccList[0].property__c = propertyList[0].Id;
        database.update(parentAccList);
        PropertyTeam__c propTeam = TestDataFactory.createPropertyTeam(propertyList[0].Id, 'Regional Manager - LARS', userList[0].id, propTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        PropertyTeam__c propTeam2 = TestDataFactory.createPropertyTeam(propertyList[0].Id, constants.TEAM_ROLE_RETAILMANAGER, userList[0].id, propTeamRecordTypeMapByName.get(CONSTANTS.PRT_INTERNAL_TEAM_MEMBER).getRecordTypeId());
        List<propertyTeam__c> propTeamLst = new List<PropertyTeam__c>();
        propTeamLst.add(propTeam);
        propTeamLst.add(propTeam2);
        database.insert(propTeamLst);
   
        space__C spac = new space__c();
        spac.name ='Test';
        spac.Property__c = propertyList[0].Id;
        spac.BackupRetailer__c = parentAccList[0].id;
        spac.type__c = '4';
        spac.MainFloor__c = '12';
        spac.RentableArea__c = 10;
        spac.UsableArea__c = 10;
        // spac.MainFloor__c 	// --- 4/29/19: required field
        insert spac;
        
        //CREATE OPPORTUNITY
        oppList = TestDataFactory.createOpportunity(10, parentAccList[0], propertyList[0], userList[0]);
            List<Id> oppIdList = new List<Id>();
        for(Opportunity opp: oppList){
            opp.ApprovalStatus__c = constants.FINALAPPR_GRANT;
            opp.recordtypeid = oppRecTypeMapByName.get(CONSTANTS.OPP_RETAIL_LEASING).getRecordTypeId();
            opp.property__c = propertyList[0].Id;
        }
        oppList[1].recordtypeid = oppRecTypeMapByName.get(CONSTANTS.OPP_STORE_ROOM_LEASING).getRecordTypeId();
        oppList[1].ApprovalStatus__c = Constants.STRAPPOVALGRANTED;
        oppList[1].Space__c = spac.id;
        
        /*oppList[2].recordTypeId = oppRecTypeMapByDeveloperName.get(CONSTANTS.OPP_STORE_ROOM_LEASING_API_NAME).getRecordTypeId();
        oppList[2].TermYr__c = 0;
        oppList[2].TermMonths__c = 1;
        oppList[2].TermDays__c = 19;
        
        oppList[3].recordTypeId = oppRecTypeMapByDeveloperName.get(CONSTANTS.OPP_STORE_ROOM_LEASING_API_NAME).getRecordTypeId();
        oppList[3].TermYr__c = 1;
        oppList[3].TermMonths__c = 0;
        oppList[3].TermDays__c = 0;*/
            
        database.insert(oppList);
        for(Opportunity opp: oppList){
            oppIdList.add(opp.Id);
        }
        
        
        //CREATE CLAUSE LIBRARY
        clauseLibList = TestDataFactory.createClauseLibrary(10);
        clauseLibList[0].RiskClauseApprovers__c = 'Corporate Legal';
        database.insert(clauseLibList);
 
        //CREATE OPPORTUNITY CLAUSE
        oppClauseList = TestDataFactory.createOpportunityClause(10, oppList[0], clauseLibList[0]);
        database.insert(oppClauseList);

         List<Opportunity> oppLst = [select Id,GroupGeneralManagerLARS__c,approvalStatus__c,CapitalVariance__c,RentVariance__c, 
                                    Property__c,RMRetailAdmin__c,RMLARS__c,GMLARS__c,GMRetailAdmin__c,CorporateLegal__c,DirectorLARSNZDevelopment__c, COO__c
                                    from Opportunity  where property__c in : propertyList limit 10];
       oppClauseList = [select Opportunity__c,Type__c,Approved__c,id,ReferencedClause__c,ReferencedClause__r.RiskClauseApprovers__c, RiskApplies__c, ReasonRecommendation__c FROM OpportunityClause__c];
       
        
            UpdateRoleFieldsBaseFromClause.updateRoleFields(oppIdList);
        Test.stopTest();
        
        system.assert(true, oppIdList <> null);
        
    }    
   /**
    * @author:         Kyle Tan
    * @description:    Test class for buildTopParentAccountMap method
    **/
    public static testMethod void buildTopParentAccountMapTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountWithParentList = new List<Account>([SELECT Id FROM Account WHERE ParentId != null]);
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> topParentAccountMap = new Map<Id, Id>();
        if(accountWithParentList != null && accountWithParentList.size() > 0) {
            for(Account accRec :accountWithParentList) {
                accountIdSet.add(accRec.Id);
            }
        }
        system.runAs(testUser) {
            test.startTest();
            topParentAccountMap = OpportunityBL.buildTopParentAccountMap(accountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
            test.stopTest();
        }
        system.assertEquals(accountIdSet.size(), topParentAccountMap.size());
    }
   /**
    * @author:         Kyle Tan
    * @description:    Test class for buildAccountPrecedentClauseMap method
    **/
    public static testMethod void buildAccountPrecedentClauseMapTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Map<Id, List<PrecedentClause__c>> accountPrecClauseMap = new Map<Id, List<PrecedentClause__c>>();
        List<Account> accountWithParentList = new List<Account>([SELECT Id FROM Account WHERE ParentId != null]);
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> topParentAccountMap = new Map<Id, Id>();
        if(accountWithParentList != null && accountWithParentList.size() > 0) {
            for(Account accRec :accountWithParentList) {
                accountIdSet.add(accRec.Id);
            }
        }
        topParentAccountMap = OpportunityBL.buildTopParentAccountMap(accountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        system.runAs(testUser) {
            test.startTest();
            if(topParentAccountMap != null && topParentAccountMap.size() > 0) {
                accountPrecClauseMap = OpportunityBL.buildAccountPrecedentClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId());
            }
            test.stopTest();
        }
        system.assertEquals(accountIdSet.size(), accountPrecClauseMap.size());
    }
    
   /**
    * @author:         Kyle Tan
    * @description:    Test class for createOpportunityProducts method
    **/
    public static testMethod void createOpportunityProductsTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        List<Product2> productList = new List<Product2>([SELECT Id, IsActive, Description, DefaultPrice__c, Name FROM Product2]);
        Map<Id,Map<Id,PriceBookEntry>> priceBookProductIdMap = OpportunityBL.mapPBEntryByProduct(productList);
        Opportunity opportunityRec = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        String opportunitySpaceType = '1';
        Decimal opportunitySpaceUsableArea = 5;
        
        for(Product2 productRec : productList) {
            productRec.Name = 'Air Con';
        }
        
        system.runAs(testUser) {
            
            test.startTest();
            
            opportunityLineItemList = OpportunityBL.createOpportunityProducts(opportunityRec, productList, opportunitySpaceType, opportunitySpaceUsableArea, priceBookProductIdMap);
            
            test.stopTest();
        }
        system.assertEquals(11, opportunityLineItemList.size());
    }
    public static testMethod void  testCreateOpportunityClause(){
        List<ClauseLibrary__c> clauseLibList = new List<ClauseLibrary__c>();
        Opportunity opp = [Select id from Opportunity limit 1];
        Map<String, Schema.RecordTypeInfo> opportunityClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
        clauseLibList = TestDataFactory.createClauseLibrary(10);
        database.insert(clauseLibList);
        test.startTest();
        List<OpportunityClause__c> createdOppClauses = OpportunityBL.CreateOpportunityClause(opportunityClauseRecordTypeMapByName.get('Leasing Clause').getRecordTypeId(), opp,clauseLibList);
        test.stopTest();
        system.assert(createdOppClauses.size() > 0);
    }  
    
   /**
    * @author:         Kyle Tan
    * @description:    Test class for mapProductByDealType method
    **/
        public static testMethod void mapProductByDealTypeTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, List<Product2>> productMap = new Map<String, List<Product2>>();
        Set<String> opportunityDealTypeSet = DatabaseSOQLBank.getOpportunityDealTypeSet();
        List<Product2> productList = new List<Product2>([SELECT Id, Name FROM Product2]);
        
        system.runAs(testUser) {
            test.startTest();
            
            productMap = OpportunityBL.mapProductByDealType(opportunityDealTypeSet, productList);
            
            test.stopTest();
        }
        
        system.assert(productMap.keySet().size() == 3); 
    }
    
   /**
    * @author:         Kyle Tan
    * @description:    Test class for mapPBEntryByProduct method
  **/
    public static testMethod void mapPBEntryByProductTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Product2> productList = new List<Product2>([SELECT Id FROM Product2]);
        Map<Id,Map<Id,PriceBookEntry>> productPBEntryIdMap = new Map<Id,Map<Id,PriceBookEntry>>();
        
        system.runAs(testUser) {
            
            test.startTest();
            
            productPBEntryIdMap = OpportunityBL.mapPBEntryByProduct(productList);
            
            test.stopTest();
        }
        
        system.assertEquals(10, productPBEntryIdMap.size());
    }
    
    public static testMethod void updateOppoWhenOppoEventSentSuccessTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Opportunity oppRecord = [SELECT Id FROM Opportunity LIMIT 1];
        DateTime dt = System.now();
        List<String> payloads = new List<String>();
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        String jsonInput = '{\n' +
            ' "ID" : "'+ oppRecord.Id +'",\n' +
            ' "TECHDISPATCHEDTIMESTAMP__C" : "'+ dt +'",\n' +
            ' "TECHDISPATCHEDVERSION__C" : "'+ CONSTANTS.NUMBER_ONE +'"\n' +
            '}';
        payloads.add(jsonInput);
        
        List<OpportunityEvent__e> successfullpublish = new List <OpportunityEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                OpportunityEvent__e oppEvent = new OpportunityEvent__e();
                oppEvent.OpportunityPayload__c = payload;
                successfullpublish.add(oppEvent);
            }
        }
        
           
        Test.startTest();
            results = EventBus.publish(successfullpublish);
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                    OpportunityBL.updateOppoWhenOppoEventSentSuccess(successfullpublish);
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
        
        Opportunity updatedOppRecord = [SELECT Id, TechDispatchedTimeStamp__c, TechDispatchedVersion__c FROM Opportunity WHERE Id = :oppRecord.Id LIMIT 1];
        //System.assertEquals(dt.addHours(6), updatedOppRecord.TechDispatchedTimeStamp__c);
        System.assertEquals(1, updatedOppRecord.TechDispatchedVersion__c);
         
    }
    
    public static testMethod void generateOppoEventsTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityEvent__e> oppoEvents = new List<OpportunityEvent__e>();
        List<String> payloads = new List<String>{'String', 'Testing'};
       
        Test.startTest();
          oppoEvents = OpportunityBL.generateOppoEvents(payloads);
        Test.stopTest();
    }
    
    public static testMethod void oppoEventTriggerCriteriaCheckTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id, Opportunity> dbOppoDataMapToPublish = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
        Map<Id, Opportunity> oppoNewMap = new Map<Id, Opportunity>([SELECT Id, StageName, JDESentStatus__c FROM Opportunity]);
        Test.startTest();
           dbOppoDataMapToPublish = OpportunityBL.oppoEventTriggerCriteriaCheck(oppoNewMap);
        Test.stopTest();   
    }
    
    public static testMethod void updateOpportunityClauseTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<OpportunityClause__c> clausetoupdateList = [SELECT Id FROM OpportunityClause__c];
        Map<Id,Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
        Test.startTest();
          clausetoupdateList = OpportunityBL.updateOpportunityClause(opportunityMap);
        Test.stopTest();   
    }
    
    public static testMethod void getUpdatedRoleOpportunityTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<Id,Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
        
        /* Opportunity opp = [SELECT Id, DealAchieved__c, AcceptedDisclosureStatement__c,
                           approvalStatus__c, Property__r.Tier__c, RentVariance__c,
                           CapitalVariance__c, NoofUnApprovedClause__c, Space__r.Status__c
                           FROM Opportunity
                           LIMIT 1]; */
        /*
        Set<String> finalApprStatusSet = new Set<String>{'Testing'};
        //List<Opportunity> opp = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<OpportunityApprovalMatrix__mdt> oppAppMatr = new List<OpportunityApprovalMatrix__mdt>();
        Map<String, Id> roleUserMap = new Map<String, Id>();
        Set<String> allowedRetTypes = new Set<String>{'Testing'};
        Set<String> roleSet = new Set<String>{'Testing'};
        String rectypeName;
        String rmtype;
        String finalApprovalType;		
		*/

        Database.insert(testUser);		// -- 5/15/2019
        Set<String> finalApprStatusSet = new Set<String>{'Testing'};
        Opportunity opp = [SELECT Id, DealAchieved__c, AcceptedDisclosureStatement__c, ApprovalStatus__c, Property__r.Tier__c,
                           RentVariance__c, CapitalVariance__c, NoofUnApprovedClause__c, Space__r.Status__c
                           FROM Opportunity LIMIT 1];
        opp.DealAchieved__c = false;
        opp.AcceptedDisclosureStatement__c = false;
        opp.ApprovalStatus__c = '';
        opp.Property__r.Tier__c = 'Tier 1';
        OpportunityApprovalMatrix__mdt oppAppMatrix = [SELECT Id, Type__c, Tier__c, Role__c, ProjectRole__c, RentRange__c, CapitalRange__c,
                                                       RentAmountRange__c, CapitalAmountRange__c, fieldAPIName__c
                                                       FROM OpportunityApprovalMatrix__mdt
                                                       WHERE Type__c = :Constants.COMMINITAPPROVAL
                                                       	AND Tier__c = 'Tier 1'
                                                      	AND Role__c = 'Commercial Leasing Regional Manager'];
        Map<String, Id> roleUserMap = new Map<String, Id>();
        roleUserMap.put('Commercial Leasing Regional Manager', testUser.Id);
        Set<String> allowedRetTypes = new Set<String>{'Testing'};
        Set<String> roleSet = new Set<String>{'Testing'};
        String recTypeName = '';
        Set<String> finalApprTypes = new Set<String>{Constants.RETAILINITAPPROVAL, Constants.COMMINITAPPROVAL};
        
        Test.startTest();
        Opportunity opp2 = OpportunityBL.getUpdatedRoleOpportunity(finalApprStatusSet, opp, oppAppMatrix, roleUserMap, allowedRetTypes, roleSet, recTypeName, finalApprTypes);
		System.assertEquals(testUser.Id, opp2.RMLARS__c);	// -- 5/15/2019
        Test.stopTest();       
    }
    
     public static testMethod void updateOppLineItemDateTest(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);

        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        List<Opportunity> OppLst = new List<Opportunity>([SELECT ProposedRentCommencementDate__c,Id FROM Opportunity limit 1]);
 
        List<Opportunity> newOpportunity = new List<Opportunity>();
        List<Opportunity> oldOpportunity = new List<Opportunity>();
        oldOpportunity.add(OppLst[0]);
        for(Opportunity opp : OppLst){
            opp.ProposedRentCommencementDate__c = system.today();
            newOpportunity.add(opp);
        }
        OpportunityLineItem oppl = new OpportunityLineItem();
        oppl.opportunityid = newOpportunity[0].id;
        Map<Id, List<OpportunityLineItem>> OpportunityLineItemMap = new Map <Id, List<OpportunityLineItem>>();
        OpportunityLineItemMap.put(newOpportunity[0].id,new List<OpportunityLineItem>{oppl});
        
        Test.startTest();
          oppLineItemList = OpportunityBL.updateOppLineItemDate(newOpportunity[0], oldOpportunity[0], OpportunityLineItemMap);
        Test.stopTest();   
    }
        
   /**
    * @author:         Kyle Tan
    * @description:    Test class for buildNationalAgreementClauseMap method
    **/
    public static testMethod void buildNationalAgreementClauseMapTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
        List<Account> accountWithParentList = new List<Account>([SELECT Id FROM Account WHERE ParentId != null]);
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> topParentAccountMap = new Map<Id, Id>();
        if(accountWithParentList != null && accountWithParentList.size() > 0) {
            for(Account accRec :accountWithParentList) {
                accountIdSet.add(accRec.Id);
            }
        }
        topParentAccountMap = OpportunityBL.buildTopParentAccountMap(accountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        system.runAs(testUser) {
            test.startTest();
            if(topParentAccountMap != null && topParentAccountMap.size() > 0) {
                nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
            }
            test.stopTest();
        }
        system.assertEquals(accountIdSet.size(), nationalAgreementClauseMap.size());
    }
    
    /**
     * @author:      Kyle Tan
     * @desc:      createReviewsforOpportunity test method
     **/
    @isTest
    private static void createReviewsforOpportunityTest() {
        test.startTest();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        String productName = Constants.PRODUCT_RENT_REVIEW;
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> oppRecordTypeByDeveloperName = RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.OPPORTUNITY);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        List<Opportunity> oppList = new List<Opportunity>([SELECT TermDays__c,TermMonths__c,Id, Property__c, 
                                                           Pricebook2Id, RecordTypeId, 
                                                           TermYr__c, ProposedStartDate__c, 
                                                           AnnualMinimumRent__c, AccountId
                                                           FROM Opportunity LIMIT 5]);
        Set<Id> propertyIdSet = new Set<Id>();
        Map<Id, Property__c> propertyMap = new Map<Id, Property__c>();
        //NATIONAL AGREEMENT CLAUSE MAP VARIABLES
        Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
        List<Account> accountWithParentList = new List<Account>([SELECT Id FROM Account WHERE ParentId != null]);
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> topParentAccountMap = new Map<Id, Id>();
        //
        Set<Id> priceBookIdSet = new Set<Id>();
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        Map<String, PriceBookEntry> productNameandPricebookEntryMap = new Map<String, PriceBookEntry>();
        
        for(Opportunity oppRec :oppList) {
            if(oppRec.Property__c != null) {
                propertyIdSet.add(oppRec.Property__c);
            }
            oppRec.TermYr__c = 1;
            oppRec.TermMonths__c = 2;
            oppRec.TermDays__c = 0;
            oppRec.BestBet__c = false;
            priceBookIdSet.add(oppRec.Pricebook2Id);
        }
        
        space__C spac = new space__c();
        spac.name ='Test';
        spac.Property__c = new List<Id>(propertyIdSet)[0];
        spac.type__c = '4';
        spac.MainFloor__c = '12';
        spac.RentableArea__c = 10;
        spac.UsableArea__c = 10;
        // spac.MainFloor__c 	// --- 4/29/19: required field
        insert spac;
        
        oppList[0].recordtypeid = oppRecordTypeByDeveloperName.get(CONSTANTS.OPP_STORE_ROOM_LEASING_API_NAME).getRecordTypeId();
        oppList[0].TermYr__c = 1;
        oppList[0].TermMonths__c = 0;
        oppList[0].TermDays__c = 0;
        oppList[0].Space__c = spac.id;
        oppList[0].AnnualMinimumRent__c = 1000;		// -- 5/15/2019
        database.update(oppList);
        
        //BUILD PROPERTY MAP
        propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet));
        
        //BUILD NATIONAL AGREEMENT CLAUSE MAP
        if(accountWithParentList != null && accountWithParentList.size() > 0) {
            for(Account accRec :accountWithParentList) {
                accountIdSet.add(accRec.Id);
            }
        }
        topParentAccountMap = OpportunityBL.buildTopParentAccountMap(accountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        if(topParentAccountMap != null && topParentAccountMap.size() > 0) {
            nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
        }
        
        //BUILD PRODUCTNAMEANDPRICEBOOKENTRYMAP
        pbEntryList = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet);
        
        if(pbEntryList != null && pbEntryList.size() > 0) {
            for(PriceBookEntry pbEntryRec :pbEntryList) {
                productNameandPricebookEntryMap.put(pbEntryRec.id, pbEntryRec);
            }
        }
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        oppLineItemWrapper.opportunityRecord = oppList[0];
        oppLineItemWrapper.opportunityRecordtypeName = RecordTypeUtil.getAllRecordTypesById(Constants.OPPORTUNITY).get(oppList[0].RecordTypeId).getName();
        oppLineItemWrapper.propertyMap = propertyMap;
        oppLineItemWrapper.nationalAgreementClauseMap = nationalAgreementClauseMap;
        oppLineItemWrapper.topParentAccountMap = topParentAccountMap;
        oppLineItemWrapper.productNameandPricebookEntryMap = productNameandPricebookEntryMap;
        
        // --- 5/15/2019
        List<PricebookEntry> pbeTestList = new List<PricebookEntry>([SELECT Id, Product2Id FROM PricebookEntry
                                                                     WHERE Pricebook2Id = :oppList[0].Pricebook2Id AND Name = :Constants.PRODUCT_PROMO_REVIEW]);
        // ---
        system.runAs(testUser) {
            
            //oppLineItemList = OpportunityBL.createReviewsforOpportunity(oppLineItemWrapper, productName);
            //oppLineItemList = OpportunityBL.createReviewsforOpportunity(oppLineItemWrapper, Constants.PRODUCT_RENT_REVIEW);
            //oppLineItemList = OpportunityBL.createReviewsforOpportunity(oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW);
            
            // -- 5/9/2019:
            // Pricebook2Id = Opp.Pricebook2Id
            Map<Id, Double> opptyWithRent = new Map<Id, Double>();
            for (PricebookEntry pbe: pbeTestList) {
                oppLineItemList = OpportunityBL.createReviewsforOpportunity(opptyWithRent, oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, productNameandPricebookEntryMap.get(pbe.Id));
            }
            //oppLineItemList = OpportunityBL.createReviewsforOpportunity(oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, productNameandPricebookEntryMap.get());
            test.stopTest();
        }
    }
    
    /**
     * @author:      Kyle Tan
     * @desc:      checkForecastFieldChanges test method
     **/
    @isTest
    private static void checkForecastFieldChangesTest() {
        Set<String> forecastFieldSet = new Set<String>();
         try{
            forecastFieldSet = DatabaseSOQLBank.getForecastFieldSet();
        } catch(Exception e) {
            forecastFieldSet = null;
        }
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, AnnualMinimumRent__c, 
                                                           ForecastCapitalCashIncentive__c, 
                                                           ForecastCapitalDesignConstruction__c, 
                                                           ForecastCapitalLessorWorks__c FROM Opportunity]);
        Boolean isChanged = false;
        system.runAs(testUser) {
            test.startTest();
            isChanged = OpportunityBL.checkForecastFieldChanges(oppList[0], oppList[1],forecastFieldSet );
            test.stopTest();
        }
        system.assertEquals(false, isChanged);
    }
    
    /**
     * @author:      Kyle Tan
     * @desc:      updateSecurityDeposit test method
     **/
    @isTest
    private static void updateSecurityDepositTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Double securityDeposit = 0;
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
        Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
        List<Account> accountWithParentList = new List<Account>([SELECT Id FROM Account WHERE ParentId != null]);
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> topParentAccountMap = new Map<Id, Id>();
        Set<Id> propertyIdSet = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>([SELECT Property__c,Id, TotalPromotionLevy__c, 
                                                           TotalOutgoings__c, AccountId, 
                                                           SecurityDepositMonths__c, 
                                                           SecurityDepositWeeks__c, 
                                                           SecurityDepositDays__c, 
                                                           AnnualMinimumRent__c
                                                           FROM Opportunity]);
        Integer counter = 0;
        for(Opportunity oppRec :oppList) {
            counter++;
            if(counter == 1) {
                oppRec.SecurityDepositMonths__c = 5;
                oppRec.SecurityDepositWeeks__c = 0;
                oppRec.SecurityDepositDays__c = 0;     
            } else if(counter == 2) {
                oppRec.SecurityDepositMonths__c = 0;
                oppRec.SecurityDepositWeeks__c = 5;
                oppRec.SecurityDepositDays__c = 0;  
            } else {
                oppRec.SecurityDepositMonths__c = 0;
                oppRec.SecurityDepositWeeks__c = 0;
                oppRec.SecurityDepositDays__c = 5;  
            }
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id FROM Account]);
        if(accountWithParentList != null && accountWithParentList.size() > 0) {
            for(Account accRec :accountWithParentList) {
                accountIdSet.add(accRec.Id);
            }
        }
        List<GST__mdt> GSTList = new List<GST__mdt>();
          try {
                GSTList = DatabaseSOQLBank.getGST();
            } catch(Exception e) {
                GSTList = null;
            }
        propertyIdSet.add(oppList[0].Property__c);
        topParentAccountMap = OpportunityBL.buildTopParentAccountMap(accountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        if(topParentAccountMap != null && topParentAccountMap.size() > 0) {
            nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId());
        }
        Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet));
        system.runAs(testUser) {
            test.startTest();
            securityDeposit = OpportunityBL.updateSecurityDeposit(oppList[0], topParentAccountMap, nationalAgreementClauseMap, accountMap, propertyMap,GSTList );
            securityDeposit = OpportunityBL.updateSecurityDeposit(oppList[1], topParentAccountMap, nationalAgreementClauseMap, accountMap, propertyMap,GSTList );
            securityDeposit = OpportunityBL.updateSecurityDeposit(oppList[2], topParentAccountMap, nationalAgreementClauseMap, accountMap, propertyMap,GSTList );
            test.stopTest();
        }
    }
    
        /**
     * @author:      Lean Flores
     * @desc:      virtualVacancyUpdates test method
     **/
    @isTest
    public static void virtualVacancyUpdatesTest() {
        Test.startTest();
        
		Account acc = [SELECT Id, Property__c from Account LIMIT 1];
        
        List<Opportunity> oppList = TestDataFactory.createOpportunity(2, acc);
		
        oppList[0].ForecastRent__c = 30000;
        oppList[0].ForecastedRentTerminationDate__c = Date.today().addYears(-1);
        oppList[0].ForecastRentCommencementDate__c = Date.today();
        oppList[0].BestBet__c = false;
        oppList[0].CurrentLeaseVirtualVacancy__c = Constants.NO;
        
        oppList[1].ForecastRent__c = 30000;
        oppList[1].ForecastedRentTerminationDate__c = Date.today().addYears(-1);
        oppList[1].ForecastRentCommencementDate__c = Date.today();
        oppList[1].BestBet__c = false;
        oppList[1].CurrentLeaseVirtualVacancy__c = 'V_H';
        
        OpportunityBL.virtualVacancyUpdates(oppList[0]);
        OpportunityBL.virtualVacancyUpdates(oppList[1]);
        
        system.assert(oppList[0].VirtualVacancyRent__c == null && oppList[0].VirtualVacancyStartDate__c == null && oppList[0].VirtualVacancyEndDate__c == null, 'VV fields should be null if VV is NO/Empty');
        system.assert(oppList[1].VirtualVacancyRent__c != null && oppList[1].VirtualVacancyStartDate__c != null && oppList[1].VirtualVacancyEndDate__c != null, 'VV fields should be NOT null if VV is NOT NO/Empty');
        
        Test.stopTest();
        
    }
    
}