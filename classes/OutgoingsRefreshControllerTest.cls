/**
 * @author          : Yana Navarro
 * @desc            : Test class for OutgoingsRefreshController
 **/
@isTest
private class OutgoingsRefreshControllerTest {
    @testSetup
    private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName
            = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        Map<String, Schema.RecordTypeInfo> opportuntiyRecordTypeMapByName
            = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
        
        //Create Product
        Product2 productTemp;
        Set<String> productNameSet;
        List<Product2> productList = new List<Product2>();
        
        productNameSet = new Set<String>{
            'Water Rates',
            'Cleaning',
            'Land Tax'
        };
        
        for(String prodName : productNameSet){
            productTemp = TestDataFactory.createProduct(prodName, 'Recoveries');
            productTemp.ProductCode = Constants.OTG;
            productTemp.SpaceType__c = '1;2';
            productTemp.EffectiveToDate__c = Date.newInstance(Date.today().year(), 12, 31);
            productTemp.EffectiveFromDate__c = Date.newInstance(Date.today().year(), 1, 1);
            productTemp.OutgoingsCategory__c = prodName;
			productTemp.DealType__c = 'Semi Gross';
			productTemp.SpaceBillingCategory__c = 'NR';
            productList.add(productTemp);
            
            productTemp = TestDataFactory.createProduct(prodName, 'Recoveries');
            productTemp.ProductCode = Constants.OTG;
            productTemp.SpaceType__c = '1;2';
            productTemp.EffectiveToDate__c = Date.newInstance(Date.today().year() + 1, 12, 31);
            productTemp.EffectiveFromDate__c = Date.newInstance(Date.today().year() + 1, 1, 1);
            productTemp.OutgoingsCategory__c = prodName;
			productTemp.DealType__c = 'Semi Gross';
			productTemp.SpaceBillingCategory__c = 'NR';
            productList.add(productTemp);
        }
        
        database.insert(productList);
        
        //Create Price Book
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        //Create PriceBookEntry
        Integer counter = 1;
        PriceBookEntry pbEntryTemp;
        List<PriceBookEntry> priceBookEntryList = new List<PriceBookEntry>();
        List<PriceBookEntry> standardPriceBookEntryList = new List<PriceBookEntry>();
        
        for(Product2 prod : productList){
            if(prod.EffectiveFromDate__c.year() == Date.today().year()){
                pbEntryTemp = TestDataFactory.createPriceBookEntry(1, priceBookList[0], prod)[0];
                pbEntryTemp.Pricebook2Id = priceBookList[0].Id;
                pbEntryTemp.UnitPrice = (1000 * counter++);
                pbEntryTemp.EffectiveToDate__c = prod.EffectiveToDate__c;
                pbEntryTemp.EffectiveFromDate__c = prod.EffectiveFromDate__c;
                pbEntryTemp.UseStandardPrice = false;
                
                priceBookEntryList.add(pbEntryTemp);
            }
            
            pbEntryTemp = TestDataFactory.createPriceBookEntryRecord(prod.Name, prod, null);
            standardPriceBookEntryList.add(pbEntryTemp);
        }
        
        Database.insert(standardPriceBookEntryList);
        Database.insert(priceBookEntryList);
        
        //Create Property
        List<Property__c> propertyList = new List<Property__c>();
        propertyList = TestDataFactory.createProperty(1, priceBookList[0]);
        propertyList[0].ApplicableOutgoings__c = 'Water Rates;Cleaning;Land Tax';
        database.insert(propertyList);
        
        //Create Account
        List<Account> propBasedAccount = new List<Account>();
        propBasedAccount = TestDataFactory.createAccountBulk(1, propertyList[0].Id, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId());
        database.insert(propBasedAccount);
        
        //Create Space
        List<Space__c> spaceList = new List<Space__c>();
        spaceList = TestDataFactory.createSpace(1, propertyList[0]);
        spaceList[0].Type__c = '1';
		spaceList[0].BillingCategory__c = 'NR';
        database.insert(spaceList);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList = TestDataFactory.createOpportunity(1, propBasedAccount[0], propertyList[0], spaceList[0]);
        opportunityList[0].RecordTypeId = opportuntiyRecordTypeMapByName.get(Constants.OPP_RETAIL_LEASING).getRecordTypeId();
		opportunityList[0].ProposedRentCommencementDate__c = Date.today();
		opportunityList[0].DealType__c = 'Semi Gross';
        database.insert(opportunityList);
    }
    
    @isTest
    private static void testGetOpportunities(){
        LightningResponse res = new LightningResponse();
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Property__c> propertyList = [SELECT Id, Name FROM Property__c];
        
        system.runAs(runningUser){
            Test.startTest();
                res = OutgoingsRefreshController.getOpportunities(propertyList[0].Id);
            Test.stopTest();
        }
		
		system.assertEquals(Constants.SUCCESS, res.status);
    }
	
	@isTest
    private static void testRefreshOpportunityLineItem(){
		Integer counter = 1;
		PriceBookEntry pbEntryTemp;
		Map<Id, List<OpportunityLineItem>> successOliUpdateByOppIdMap = new Map<Id, List<OpportunityLineItem>>();
		List<PriceBookEntry> pbEntryList = new List<PriceBookEntry>();
		List<Product2> productList = [SELECT Id, Name, EffectiveFromDate__c, EffectiveToDate__c FROM Product2];
		List<Pricebook2> priceBookList = [SELECT Id, Name FROM Pricebook2];
		List<Opportunity> opportunityList = [SELECT Id, Name, ProposedRentCommencementDate__c FROM Opportunity];
		
		Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
		
		for(Opportunity opp : opportunityList){
			opp.ProposedRentCommencementDate__c = Date.today().addYears(1);
		}
		
		//Database.update(opportunityList);
		
		for(Product2 prod : productList){
			if(prod.EffectiveFromDate__c.year() == Date.today().addYears(1).year()){
                pbEntryTemp = TestDataFactory.createPriceBookEntry(1, priceBookList[0], prod)[0];
                pbEntryTemp.Pricebook2Id = priceBookList[0].Id;
                pbEntryTemp.UnitPrice = (2500 * counter++);
                pbEntryTemp.EffectiveToDate__c = prod.EffectiveToDate__c;
                pbEntryTemp.EffectiveFromDate__c = prod.EffectiveFromDate__c;
                pbEntryTemp.UseStandardPrice = false;
                
                pbEntryList.add(pbEntryTemp);
            }
		}
		
		Database.insert(pbEntryList);
		
		system.runAs(runningUser){
            Test.startTest();
            successOliUpdateByOppIdMap = OutgoingsRefreshController.refreshOpportunityLineItem(opportunityList);
            Test.stopTest();
        }
		
		system.assert(successOliUpdateByOppIdMap.size() > 0);
	}
    
    @isTest
    private static void refreshOutgoingsTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        Id returnId;
        system.runAs(runningUser){
            test.startTest();
            returnId = OutgoingsRefreshController.refreshOutgoings(JSON.serialize(opportunityList));
            test.stopTest();
        }
        system.assert(returnId != null);
    }
    
    @isTest
    private static void isBatchCompleteTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMINISTRATOR LIMIT 1];
        User runningUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id FROM Opportunity]);
        Id returnId = OutgoingsRefreshController.refreshOutgoings(JSON.serialize(opportunityList));
		Boolean isComplete;
        system.runAs(runningUser){
            test.startTest();
            isComplete = OutgoingsRefreshController.isBatchComplete(returnId);
            test.stopTest();
        }
        system.assertEquals(false, isComplete);
    }
}