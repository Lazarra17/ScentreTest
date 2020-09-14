/**
 * @author:			Kyle Tan
 * @desc:			test class for RelatedOpportunityTriggerHandler
 **/
@isTest
private class RelatedOpportunityTriggerHandlerTest {
    
	@testSetup
    private static void testSetup() {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> oppClauseTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
        Map<String, Schema.RecordTypeInfo> spaceTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        List<Property__c> propertyList = new List<Property__c>();
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Space__c> spaceList = new List<Space__c>();
        List<Space__c> spaceList2 = new List<Space__c>();
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        SpaceGroup__c spaceGroupRec = new SpaceGroup__c();
        SpaceGroup__c spaceGroupRec2 = new SpaceGroup__c();
        
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create Property
        propertyList = TestDataFactory.createProperty(2, priceBookList[0]);
        database.insert(propertyList);
        
        //Create Account
        accList = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        accList.addAll(TestDataFactory.createAccountBulk(1, propertyList[1].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId()));
        database.insert(accList);
        
        //Create Space
        spaceList = TestDataFactory.createSpace(3, propertyList[0]);
        spaceList[0].RecordTypeId = spaceTypeMapByName.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        spaceList[1].Property__c = propertyList[1].Id;
        spaceList[1].RecordTypeId = spaceTypeMapByName.get('Leased Spaces').getRecordTypeId();
        database.insert(spaceList);
        
        spaceList2 = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList2[0].RecordTypeId = spaceTypeMapByName.get('Leased Spaces').getRecordTypeId();
		database.insert(spaceList2);
        
        
        //Create Space Group
        spaceGroupRec = TestDataFactory.createSpaceGroup(spaceList[2], spaceList[0]);
        spaceGroupRec2 = TestDataFactory.createSpaceGroup(spaceList[2], spaceList[0]);
        spaceGroupList.add(spaceGroupRec);
        spaceGroupList.add(spaceGroupRec2);
        database.insert(spaceGroupList);
        
        //Create Opportunity
        oppList = TestDataFactory.createOpportunity(2, accList[0]);
        oppList[0].Space__c = spaceList[0].Id;
        oppList[1].Property__c = propertyList[1].Id;
        oppList[1].Space__c = spaceList[1].Id;
        oppList[1].AccountId = accList[1].Id;
        database.insert(oppList);
    }
    
    /**
     * @author:			Kyle Tan
     **/
    @isTest
    private static void insertRelatedOpportunityTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<RelatedOpportunity__c> relatedOppList = new List<RelatedOpportunity__c>();
        relatedOppList = TestDataFactory.createRelatedOpportunity(1, oppList[0]);
        relatedOppList.addAll(TestDataFactory.createRelatedOpportunity(1, oppList[1]));
        system.runAs(testUser) {
            test.startTest();
            database.insert(relatedOppList);
            TriggerHandler.clearAllBypasses();
            database.update(relatedOppList);
            TriggerHandler.clearAllBypasses();
            database.delete(relatedOppList);
            test.stopTest();
        }
    }
}