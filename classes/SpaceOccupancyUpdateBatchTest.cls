/*
*       author: Sidney Garcia
*       created date: Sept. 17, 2018
*       description: Test class for SpaceOccupancyUpdateBatch
*
*/
@isTest
public class SpaceOccupancyUpdateBatchTest {
	@TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(CONSTANTS.ACCOUNT);
        List<Account> accountList = new List<Account>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Contract__c> contractList = new List<Contract__c>();
        List<Property__c> propertyList = new List<Property__c>();
        
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
        
        //CREATE OPPORTUNITY
        accountList = [SELECT Id, Property__c FROM Account LIMIT 10];
        
        opportunityList = TestDataFactory.createOpportunity(10, accountList[0], propertyList, spaceList);
        database.insert(opportunityList);
        
        
    }
    
    @isTest
	private static void testSpaceOccupancyUpdateBatch() {
		Test.startTest();
			SpaceOccupancyUpdateBatch schedulableBatch = new SpaceOccupancyUpdateBatch();
			Id batchId = Database.executeBatch(schedulableBatch);
		Test.stopTest();
		
		System.assertNotEquals(batchId, null);
	}
    @isTest
    private static void testSpaceOccupancyUpdateBatchSchedulable(){
        SpaceOccupancyUpdateBatch schedulableBatch = new SpaceOccupancyUpdateBatch();
		Test.startTest();
		String sch = '0 0 23 * * ?'; 
        String jobId = system.schedule('Test Space Occupancy Update Schedulable', sch, schedulableBatch); 
        Test.stopTest();
		System.assertNotEquals(jobId, null);
    }
}