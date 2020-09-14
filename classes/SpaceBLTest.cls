/*
* @author:              Sidney Garcia
* @description:         Test class for SpaceBL
*/
@isTest
public class SpaceBLTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
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
                
        List<Space__c> spaceList = TestDataFactory.createSpace(10, property);
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        }
        Database.insert(spaceList);
        List<Space__c> newSpaceList = [SELECT Id, RentableArea__c, DevelopmentType__c, RecordTypeId, Type__c, Property__c FROM Space__c LIMIT 10];
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
        opportunityList = TestDataFactory.createOpportunity(accountList);
        for(Integer i = 0; i < opportunityList.size(); i++){
            opportunityList[i].Space__c = spaceList[i].Id;
            
            // --- 4/2/19: Validation rule: TradeFlag cannot be changed if ASOD is null
            opportunityList[i].ActualShopOpenedDate__c = Date.today() - 7;		// --- validation rule: ASOD > AVD
            // ---
        }
        database.insert(opportunityList);
        
        Account accountRecord = [SELECT Id, Name FROM Account WHERE ParentId = null AND RecordTypeId = :accountRecordTypeMapByName.get(CONSTANTS.PROPERTY_BASED).getRecordTypeId() LIMIT 1];
        
        contractList = TestDataFactory.createContract(10, accountRecord);
        for(Integer i = 0; i<contractList.size();i++){
            contractList[i].space__c = newSpaceList[i].id;
            contractList[i].ActualVacateDate__c = null;
            contractList[i].Property__c = propRec.Id;
            contractList[i].LeaseStartDate__c = date.today() - 5;
            
            // ---
            contractList[i].Opportunity__c = opportunityList[i].Id;
        }
        database.insert(contractList);
        contractList = [SELECT Id, LeaseStartDate__c, ActualVacateDate__c FROM Contract__c];
        
        for(Integer i = 0; i<newSpaceList.size();i++){
            
            newSpaceList[i].CurrentRetailer__c = accountList[i].Id;
            
        }
        database.update(newSpaceList);
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        
        spaceGroupList.add(TestDataFactory.createSpaceGroup(newSpaceList[0], newSpaceList[1]));
        Database.insert(spaceGroupList);
        
        
    }
    
    public static testMethod void testUpdateDispatchDetails(){
        List<Space__c> spaceList = new List<Space__c>();
        
        
        Test.startTest();
        spaceList = SpaceBL.updatedispatchdetailsonSpace();
        Test.stopTest();
        
        System.assertEquals(true, spaceList <> null);
    }
    
    public static testMethod void testGenerateSpaceEvents(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<String> payloads = new List<String>();
        List<SpaceEvent__e> spaceEvent = new List<SpaceEvent__e>();
        List<Space__c> spaceList = new List<Space__c>();
        
        spaceList = [SELECT Id FROM Space__c LIMIT 1];
        String spaceId = spaceList[0].Id;
        
        String jsonInput = '{\n' +
            ' "ID" : "'+ spaceId +'",\n' +
            ' "TECHDISPATCHEDTIMESTAMP__C" : "'+ date.today() +'",\n' +
            ' "TECHDISPATCHEDVERSION__C" : "123"\n' +
            '}';
        
        payloads.add(jsonInput);
        
        System.runAs(testUser) {
            
            Test.startTest();
            spaceEvent = SpaceBL.generateSpaceEvents(payloads);
            Test.stopTest();
        }
        
        System.assertEquals(1, spaceEvent.size());
    }
    
    public static testMethod void testEventSentSuccess(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        
        List<String> payloads = new List<String>();
        List<Space__c> spaceList = new List<Space__c>();
        Space__c spaceRec = new Space__c();
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        
        spaceList = [SELECT Id FROM Space__c LIMIT 1];
        String spaceId = spaceList[0].Id;
        DateTime dt = System.now();
        
        
        String jsonInput = '{\n' +
            ' "ID" : "'+ spaceId +'",\n' +
            ' "TECHDISPATCHEDTIMESTAMP__C" : "'+ dt +'",\n' +
            ' "TECHDISPATCHEDVERSION__C" : "'+ CONSTANTS.NUMBER_ONE +'"\n' +
            '}';
        payloads.add(jsonInput);
        
        List<SpaceEvent__e> spaceEvents = new List<SpaceEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                SpaceEvent__e spaceEvt = new SpaceEvent__e();
                spaceEvt.JSONPayload__c = payload;
                spaceEvents.add(spaceEvt);
            }
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            results = EventBus.publish(spaceEvents);
            
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                    SpaceBL.updateSpaceWhenSpaceEventSentSuccess(spaceEvents);
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
        spaceRec = [SELECT Id, TechDispatchedTimeStamp__c, TechDispatchedVersion__c FROM Space__c WHERE Id = :spaceId LIMIT 1];
        System.assertEquals(spaceId, spaceRec.Id);
        System.assertEquals(dt.addHours(7), spaceRec.TechDispatchedTimeStamp__c);		// --- 4/1/19: Assertion - changed from 8hrs to 7hrs
        System.assertEquals(1, spaceRec.TechDispatchedVersion__c);
    }
    
    public static testMethod void testUpdateSpaceRecords(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Space__c> spaceList = new List<Space__c>();
        
        String query = 'SELECT ';
        Schema.DescribeSObjectResult r = Opportunity.sObjectType.getDescribe();
        List<String>apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            if(apiName.equalsIgnoreCase('name')){
                continue;
            }
            else{
                query += apiName + ', ';
            }
        }
        
        query += ' Name FROM Opportunity LIMIT 1';
        
        List<Opportunity> opportunityList = Database.query(query);
        Map<Id, Opportunity> opportunityForSpaceUpdateMap = new Map<Id, Opportunity>();
        List<SpaceGroup__c> spaceGroupList = [SELECT Id, ParentSpace__r.Id, ChildSpace__r.Id, SpaceGroupNumber__c, Type__c, ParentSpace__r.Type__c, ChildSpace__r.Type__c,
                                              ParentSpace__r.CurrentLease__c, ParentSpace__r.CurrentRent__c,
                                              ParentSpace__r.CurrentSemiGrossRent__c, ParentSpace__r.PreviousLease__c,
                                              ParentSpace__r.PreviousRent__c, ParentSpace__r.ReconfiguredCurrentRent__c,
                                              ParentSpace__r.ReconfiguredCurrentRentSemiGross__c, ParentSpace__r.RentableArea__c, ChildSpace__r.RentableArea__c,
                                              ChildSpace__r.CurrentLease__c, ChildSpace__r.CurrentRent__c,
                                              ChildSpace__r.CurrentSemiGrossRent__c, ChildSpace__r.PreviousLease__c,
                                              ChildSpace__r.PreviousRent__c, ChildSpace__r.ReconfiguredCurrentRent__c,
                                              ChildSpace__r.ReconfiguredCurrentRentSemiGross__c, 
                                              Active__c FROM SpaceGroup__c LIMIT 1];
        
        
        for(Opportunity oppRecord : opportunityList){
            opportunityForSpaceUpdateMap.put(oppRecord.Id, oppRecord);
        }
        
        System.runAs(testUser){
            Test.startTest();
            spaceList = SpaceBL.updateSpaceRecords(opportunityForSpaceUpdateMap, spaceGroupList);
            Test.stopTest();
        }
        System.assertEquals(true, spaceList <> null);
    }
    
   
    public static testMethod void testgetAllSpaceGroupByGroupNumber(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Space__c> spaceList = [SELECT ID FROM Space__c LIMIT 10];
        Set<Id> childSpaceId = new Set<Id>();
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        for(Space__c spaceRec : spaceList){
            childSpaceId.add(spaceRec.Id);
        }
        
        System.runAs(testUser){
            Test.startTest();
            spaceGroupList = SpaceBL.getAllSpaceGroupByGroupNumber(childSpaceId);
            Test.stopTest();
        }
        System.assert(spaceGroupList <> null);
    }
    
    public static testMethod void testCheckActiveConfigurations(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<SpaceGroup__c> spaceGroupList = [SELECT Id, ParentSpace__r.Id, ChildSpace__r.Id, SpaceGroupNumber__c, Type__c, ParentSpace__r.Type__c, ChildSpace__r.Type__c,
                                              ParentSpace__r.CurrentLease__c, ParentSpace__r.CurrentRent__c,
                                              ParentSpace__r.CurrentSemiGrossRent__c, ParentSpace__r.PreviousLease__c,
                                              ParentSpace__r.PreviousRent__c, ParentSpace__r.ReconfiguredCurrentRent__c,
                                              ParentSpace__r.ReconfiguredCurrentRentSemiGross__c, ParentSpace__r.RentableArea__c, ChildSpace__r.RentableArea__c,
                                              ChildSpace__r.CurrentLease__c, ChildSpace__r.CurrentRent__c,
                                              ChildSpace__r.CurrentSemiGrossRent__c, ChildSpace__r.PreviousLease__c,
                                              ChildSpace__r.PreviousRent__c, ChildSpace__r.ReconfiguredCurrentRent__c,
                                              ChildSpace__r.ReconfiguredCurrentRentSemiGross__c,
                                              Active__c, EffectiveDate__c FROM SpaceGroup__c LIMIT 1];
        Boolean isConfigured;
        Space__c spaceRec = [SELECT Id from Space__c Limit 1];
        System.runAs(testUser){
            Test.startTest();
            isConfigured = SpaceBL.checkActiveConfigurations(spaceGroupList, spaceRec.Id);
            Test.stopTest();
        }
        
        System.assertEquals(true, isConfigured);
        
    }
    
    // --- 4/1/19: Modified two classes below to accommodate changes in base class
    // Assumption: CurrentLease (Contract) is null
    public static testMethod void testUpdateCurrentAndPreviousTenant(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Contract__c> contractList = [SELECT Id, Space__c, Account__c, Account__r.Name, LeaseStartDate__c, ActualVacateDate__c,
                                          Opportunity__r.TradeFlag__c, Opportunity__r.TechTradeFlagChangedDate__c FROM Contract__c LIMIT 10];
        List<Space__c> spaceList = new List<Space__c>();
        Map<Id, Contract__c> spaceIdContractMap = new Map<Id, Contract__c>();
        
        for(Contract__c contractRecord :contractList) {
            if(contractRecord.Space__c != null) {
                spaceIdContractMap.put(contractRecord.Space__c, contractRecord);
            }
        }
        System.runAs(testUser){
            Test.startTest();
            spaceList = SpaceBL.updateCurrentAndPreviousTenant(contractList);
            Test.stopTest();
        }
        // --- 4/3/19
        //spaceList = [SELECT Id, CurrentLease__c, CurrentRetailer__c, CurrentRetailerName__c FROM Space__c LIMIT 10];
        
        // Assertions: CurrentLease and CurrentRetailer
        for(Space__c spaceRecord : spaceList){
            System.assertNotEquals(null, spaceRecord.CurrentLease__c);
            System.assertEquals(spaceRecord.CurrentLease__c, spaceIdContractMap.get(spaceRecord.Id).Id);
            System.assertEquals(spaceRecord.CurrentRetailer__c, spaceIdContractMap.get(spaceRecord.Id).Account__c);
        }
         
    }
    
    // Assumption: CurrentLease (Contract) is not null
    public static testMethod void testUpdateCurrentAndPreviousTenantWithCurrentLease(){
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SYSTEM_ADMINISTRATOR LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser(CONSTANTS.TEST_FNAME, CONSTANTS.TEST_LNAME, profileRec.Id);
        List<Contract__c> contractList = [SELECT Id, Space__c, Account__c, Account__r.Name, LeaseStartDate__c, ActualVacateDate__c,
                                          Opportunity__r.TradeFlag__c, Opportunity__r.TechTradeFlagChangedDate__c, Space__r.CurrentLease__c FROM Contract__c LIMIT 10];
        
        List<Account> accList = [SELECT Id FROM Account WHERE Id!=:contractList[1].Account__c LIMIT 1];
        List<Space__c> spaceList = new List<Space__c>();
        Map<Id, Contract__c> spaceIdContractMap = new Map<Id, Contract__c>();
        
        for(Contract__c contractRecord :contractList) {
            if(contractRecord.Space__c != null) {
                spaceIdContractMap.put(contractRecord.Space__c, contractRecord);
                
                // --- 4/2/19
                contractRecord.Opportunity__r.TradeFlag__c = true;
                // ---
            }
        }

        
        System.runAs(testUser){
            Test.startTest();
            
            // --- 4/3/19: Assign CurrentLease
            
            List<Space__c> oldSpaceList = [SELECT Id, CurrentLease__c FROM Space__c LIMIT 10];
            
            
            contractList[0].ActualVacateDate__c = Date.today().addDays(-10);		// Expire one Contract record
            contractList[1].Space__c = oldSpaceList[0].Id;		// Assign two Contract records (the New Contract) to one Space
            contractList[1].ActualVacateDate__c = null;
            Database.update(contractList);
            
      		
            system.debug('YYY ' + contractList[0].ActualVacateDate__c);
            system.debug('YYY ' + contractList[1].ActualVacateDate__c);
            
            
            
            oldSpaceList[0].CurrentLease__c = contractList[0].Id;		// Assign the expired Contract record to a Space as its CurrentLease
            oldSpaceList[0].CurrentRetailer__c = accList[0].Id;
            Database.update(oldSpaceList);
            
            system.debug('YYY ' + oldSpaceList[0].CurrentLease__c);
            
            Space__c space0 = [SELECT Id, CurrentLease__r.ActualVacateDate__c FROM Space__c WHERE Id=:oldSpaceList[0].Id];
            
            system.debug('YYY ' + space0.CurrentLease__r.ActualVacateDate__c);
            system.debug('YYY ' + contractList[1].ActualVacateDate__c);
            system.debug('YYY ' + contractList[1].Space__c + ' == ' + oldSpaceList[0].Id);
            for(Contract__c contractRecord :contractList) {
                if(contractRecord.Space__c != null) {
                    
                    //if(contractRecord.LeaseStartDate__c == date.today()) {
                    //if(contractRecord.LeaseStartDate__c <= date.today() && contractRecord.ActualVacateDate__c == null) {
                    //if(contractRecord.ActualVacateDate__c == null) {
                    
                    system.debug('VVV ' + contractRecord.Space__c + ' == ' + contractRecord);
                    system.debug('VVV ' + contractRecord.ActualVacateDate__c);
                    //}
                }
            }
            // ---    
            Contract__c newContract = contractList[1];        
            Contract__c oldContract = contractList.remove(0);
            spaceList = SpaceBL.updateCurrentAndPreviousTenant(contractList);
            Test.stopTest();
            
            // --- 4/3/19
            //spaceList = [SELECT Id, CurrentLease__c, CurrentRetailer__c, CurrentRetailerName__c, PreviousLease__c FROM Space__c LIMIT 10];
            
            // Assertions:
            // Expired CurrentLeases: copy CL to PL and overwrite CL with New CL
            System.assertNotEquals(null, spaceList[0].PreviousLease__c);
            System.assertEquals(spaceList[0].PreviousLease__c, oldContract.Id);
            System.assertEquals(spaceList[0].CurrentLease__c, newContract.Id);		// magic! CL should now be the New Contract
            
            
            
        }

        
        for(Space__c spaceRecord : spaceList){
            System.debug('CURRENT LEASE ' + spaceRecord.CurrentLease__c + '====' + spaceIdContractMap.get(spaceRecord.Id).Id);
            //System.assert(spaceRecord.CurrentLease__c == spaceIdContractMap.get(spaceRecord.Id).Id); 
            
            //System.assert(spaceRecord.CurrentRetailer__c == spaceIdContractMap.get(spaceRecord.Id).Account__c);
            System.debug('CURRENT RETAILER Name' + spaceRecord.CurrentRetailerName__c + '====' + spaceIdContractMap.get(spaceRecord.Id).Account__r.Name);
            //System.assert(spaceRecord.CurrentRetailerName__c  == spaceIdContractMap.get(spaceRecord.Id).Account__r.Name);
            
        }
        
    }
    
    @isTest
    public static void updateStatusBasedOnVirtualVacancyTest() {
        Space__c spc = new Space__c();
        Opportunity opp = new Opportunity();
        
        spc.Status__c = Constants.SPACE_STATUS_TRADING;
        opp.CurrentLeaseVirtualVacancy__c = 'V_H';
        
        SpaceBL.updateStatusBasedOnVirtualVacancy(spc, opp);
        system.assertEquals(Constants.SPACE_STATUS_ATRISK, spc.Status__c, 'If VV is populated and if status is Trading, then change status to At Risk');
        
        spc.Status__c = Constants.SPACE_STATUS_ATRISK;
        spc.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_VACANCY;
        spc.Relationship__c = 'Parent';
        opp.CurrentLeaseVirtualVacancy__c = null;
        SpaceBL.updateStatusBasedOnVirtualVacancy(spc, opp);
        system.assertNotEquals(Constants.SPACE_STATUS_TRADING, spc.Status__c, 'Space-Relationship field should be blank');
        
        spc.Relationship__c = null;
        SpaceBL.updateStatusBasedOnVirtualVacancy(spc, opp);
        system.assertEquals(Constants.SPACE_STATUS_TRADING, spc.Status__c, 'If VV is removed and if status = At Risk and Occupancy Status != 3 - LBNT (Leased but not trading) then change status to Trading');
        
        Space__c spc2;
        system.assertEquals(spc2, SpaceBL.updateStatusBasedOnVirtualVacancy(null, opp), 'Return null if Space parameter is null');
    }
}