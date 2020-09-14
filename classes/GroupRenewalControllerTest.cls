/**
 * @author:				Lean Flores
 * @desc:				test class for GroupRenewalController
 **/
@isTest
public class GroupRenewalControllerTest {
	  
    private static Map<String, Schema.RecordTypeInfo> accRecordTypeMapByDevName  = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.ACCOUNT);
    private static Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByDevName  = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.OPPORTUNITY);
    
    @testSetup
    public static void testSetup(){
        
        Id propBasedRecordTypeId = accRecordTypeMapByDevName.get(Constants.PROPERTY_BASED_APINAME).getRecordTypeId();
       
        //CREATE PRODUCT
		List<Product2> productList = new List<Product2>();
        Product2 promoProd 					= TestDataFactory.createProduct('Promotional Fund', 'Promo & Marketing');
        promoProd.SpaceBillingCategory__c	= 'ATM';
        promoProd.SpaceType__c				= '1';
        productList.add(promoProd);
        
        Product2 rentProd 					= TestDataFactory.createProduct('Base Rent', 'Rent');
        rentProd.SpaceBillingCategory__c 	= 'ATM';
        rentProd.SpaceType__c 				= '1';
        productList.add(rentProd);
        
        productList.add(TestDataFactory.createProduct('Promo Review', 'Promo Review'));
        productList.add(TestDataFactory.createProduct('Rent Review', 'Rent Review'));
        database.insert(productList);
       	productList = [SELECT ID, DefaultPrice__c FROM Product2];
        
        //CREATE PRICEBOOK
        List<Pricebook2> priceBookList = TestDataFactory.createPricebook(1);
        Database.insert(priceBookList);
        Pricebook2 priceBookRec = [SELECT Id, CurrencyIsoCode FROM Pricebook2 LIMIT 1];
        
        Property__c prop = TestDataFactory.createProperty(1)[0];
        prop.PriceBook__c = Test.getStandardPricebookId();
        insert prop;
		
        //CREATE PRICEBOOK Entry
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        for (Product2 prod : productList) {
            PricebookEntry pbEntry = new PricebookEntry();
            pbEntry.IsActive = true;
            pbEntry.Pricebook2Id = Test.getStandardPricebookId();
            pbEntry.Product2Id = prod.Id;
            pbEntry.UnitPrice = 10500.00;
            pbEntry.CurrencyIsoCode = 'AUD';
            pbEntry.UseStandardPrice = false; 
            pricebookEntryList.add(pbEntry);
            
        }
        database.insert(pricebookEntryList);       
        
        system.debug('Product List: ' + productList);
        system.debug('Pricebook List : ' + priceBookList);
        system.debug('Pricebook Entry List: ' + pricebookEntryList);
        system.debug('Property List : ' + prop);
        
        Space__c spa = TestDataFactory.createSpace(1, prop)[0];
        spa.BillingCategory__c = 'ATM';
        spa.Type__c = '1';
        insert spa;
        Account parentAccount = TestDataFactory.createAccount(1);
        insert parentAccount;
        
        
        
        List<Account> childAccounts = new List<Account>();
        for (Integer i=0; i < 1; i++) {
            childAccounts.add(TestDataFactory.createAccountwithParent(i, prop.Id, propBasedRecordTypeId, parentAccount.Id));
        }
        
        
        insert childAccounts;
        
        Opportunity parentOpp = TestDataFactory.createOpportunity(childAccounts)[0];
        insert parentOpp;
        
        OpportunityClause__c opc = TestDataFactory.createOpportunityClause(1, parentOpp)[0];
        
        insert opc;
        
        List<Contract__c> childContracts = new List<Contract__c>();
        for (Account childAcc : childAccounts) {
            List<Contract__c> con = TestDataFactory.createContract(1, childAcc, prop, parentOpp);
            con[0].Space__c = spa.Id;
            childContracts.add(con[0]);
        }
        insert childContracts;
  
    }
    
	@isTest
    public static void testGetData() {
        Account parentAccount = [SELECT Id FROM Account WHERE ParentId=null LIMIT 1];
        LightningResponse response = GroupRenewalController.getData(parentAccount.Id);
        
        GroupRenewalController.initializationDataWrapper wrapper = (GroupRenewalController.initializationDataWrapper) JSON.deserializeStrict(response.returnValue, GroupRenewalController.initializationDataWrapper.class);
        
        System.assert(wrapper.contracts.size() > 0, 'No Contracts returned from child Accounts');
    }
    
	@isTest
    public static void testSaveOpportunities() {
        Test.startTest();
        Account parentAccount = [SELECT Id FROM Account WHERE ParentId=null LIMIT 1];
        Property__c prop = [SELECT Id, Name, PropertyShortName__c, PriceBook__c FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        LightningResponse response = GroupRenewalController.getData(parentAccount.Id);
        System.debug('Property Query : ' + prop);
        
        GroupRenewalController.initializationDataWrapper wrapper = (GroupRenewalController.initializationDataWrapper) JSON.deserializeStrict(response.returnValue, GroupRenewalController.initializationDataWrapper.class);
        List<Contract__c> childContractsList = wrapper.contracts;
        Contract__c cont = childContractsList[0];
        
       	Opportunity opp = new Opportunity();
        opp.AccountId = cont.Account__r.Id;
        opp.AnnualMinimumRent__c = 10000;
        opp.ExistingContract__c = cont.Id;
        opp.Name = 'Test';
        opp.ParentOpportunity__c = cont.Opportunity__c;
        opp.Property__c = cont.Property__r.Id;
        opp.ProposedStartDate__c = Date.today().addDays(200);
        opp.RecordTypeId = oppRecordTypeMapByDevName.get(Constants.OPP_RETAIL_LEASING_API_NAME).getRecordTypeId();
        opp.RentInAdvance__c = 0;
        opp.Space__c = cont.Space__r.Id;
        opp.StageName = 'Understand & Negotiate';
        opp.TermYr__c = 2;
        opp.DealType__c = 'Semi Gross';
        opp.Type = 'New Lease';
        opp.Tech_IsCreatedFromGroupRenew__c = true;
        opp.CloseDate = Date.today().addDays(10);
        
        LightningResponse response2 = GroupRenewalController.saveOpportunities(new List<Opportunity>{opp});
        GroupRenewalController.SavedOppsWrapper wrapper2 = (GroupRenewalController.SavedOppsWrapper) JSON.deserializeStrict(response2.returnValue, GroupRenewalController.SavedOppsWrapper.class);
        system.debug('OpportunitySample : ' + opp);
        system.debug('ZZZ response message : ' + response2.message);
        System.assert(wrapper2.savedOpps != null && wrapper2.savedOpps.size() > 0, 'Opportunities are not saved');
        Test.stopTest();
    }

	@isTest
    public static void testSaveOpportunitiesFailure() {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        LightningResponse response = GroupRenewalController.saveOpportunities(new List<Opportunity>{opp});
        
        System.assert(response.message.containsIgnoreCase('error'), 'Error message not generated');
    }
    
    @isTest
    public static void testSaveOpportunitiesNewZealand() {
        test.startTest();
        	Account parentAcc = [SELECT Id FROM Account WHERE ParentId = null LIMIT 1];
        	Property__c propertyRec = [SELECT Id, Name, PropertyShortName__c, PriceBook__c FROM Property__c WHERE Name = 'Test Property 1' LIMIT 1];
        	LightningResponse res = GroupRenewalController.getData(parentAcc.Id);
        	GroupRenewalController.initializationDataWrapper wrapper = (GroupRenewalController.initializationDataWrapper) JSON.deserializeStrict(res.returnValue, GroupRenewalController.initializationDataWrapper.class);
        	List<Contract__c> contractList = wrapper.contracts;
        	Contract__c contract = contractList[0];
        
        	List<Opportunity> oppList = new List<Opportunity>();
        	Pricebook2 priceBook = new PriceBook2(
                Id = propertyRec.PriceBook__c
            );
        	priceBook.CurrencyIsoCode = 'NZD';
        	database.update(priceBook);
        
        	propertyRec.Country__c = 'New Zealand';
        	propertyRec.CurrencyIsoCode = 'NZD';
        	propertyRec.PropertyCity__c = 'Newmarket';
        	propertyRec.PriceBook__c = priceBook.Id;
        	database.update(propertyRec);
        
        	Opportunity opp = TestDataFactory.createOpportunity(1, contract.Account__c)[0];
        	opp.AnnualMinimumRent__c = 10000;
        	opp.ExistingContract__c = contract.Id;
        	opp.Name = 'test';
        	opp.ParentOpportunity__c = contract.Opportunity__c;
        	opp.Property__c = contract.Property__c;
        	opp.ProposedStartDate__c = date.today().addDays(200);
        	opp.RecordTypeId = oppRecordTypeMapByDevName.get(Constants.OPP_RETAIL_LEASING_API_NAME).getRecordTypeId();
        	opp.RentInAdvance__c = 0;
        	opp.Space__c = contract.Space__c;
        	opp.StageName = Constants.UNDERSTAND_NEGOTIATE;
        	opp.TermYr__c  = 1;
        	opp.Type = 'New Lease';
        	opp.Tech_IsCreatedFromGroupRenew__c = true;
        	opp.CloseDate = date.today().addDays(10);
        	oppList.add(opp);
        
        	LightningResponse res2 = GroupRenewalController.saveOpportunities(oppList);
        	GroupRenewalController.SavedOppsWrapper wrapper2 = (GroupRenewalController.SavedOppsWrapper) JSON.deserialize(res2.returnValue, GroupRenewalController.SavedOppsWrapper.class);
        test.stopTest();
    }
}