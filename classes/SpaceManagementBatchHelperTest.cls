@isTest
public without sharing class SpaceManagementBatchHelperTest {
    @TestSetup private static void testSetup(){
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE);
        List<Pricebook2> priceBookList = new List<Pricebook2>();
		
        //Create Price Book
        priceBookList = TestDataFactory.createPricebook(1);
        database.insert(priceBookList);
        
        Property__c property = TestDataFactory.createProperty(1, priceBookList[0])[0];
        Database.insert(property);

        List<Space__c> spaceList = TestDataFactory.createSpace(5, property);
        Map<Id, Space__c> spaceMap = new Map<Id, Space__c>();
        for(Space__c space : spaceList){
            space.RentableArea__c = 40;
            space.DevelopmentType__c = null;
            space.ReconfiguredCurrentRent__c = 100000;
            space.ReconfiguredCurrentRentSemiGross__c = 50000;
            space.RecordTypeId = spaceRecordTypeMap.get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
            space.CurrencyIsoCode = 'AUD';
        }
        spaceList[4].billingCategory__c = Constants.SPACEBILLINGCATEGORY_NON_RETAIL; // --- additional code coverage; else statement is unreachable due to validation rule
        Database.insert(spaceList);

        spaceMap.putAll(spaceList);

        SpaceBudgetAndForecast__c spaceBudgetTemp;
        List<SpaceBudgetAndForecast__c> spaceBudgetList = new List<SpaceBudgetAndForecast__c>();

        Set<String> modelTypeSet = new Set<String>{
            Constants.BUDGET,
            Constants.JV_BUDGET,
            Constants.FORECAST
        };

        for(Space__c space : spaceList){
            for(String modelType : modelTypeSet){
                spaceBudgetTemp = TestDataFactory.createSpaceBudget(1, space)[0];
                spaceBudgetTemp.ModelType__c = modelType;
                spaceBudgetTemp.AnnualisedRentDecSemiGross__c = 250000;
                spaceBudgetTemp.AnnualisedRentDecNet__c = 250000;
                spaceBudgetTemp.AnnualisedRentJanSemiGross__c = 350000;
                spaceBudgetTemp.AnnualisedRentJanNet__c = 350000;
                spaceBudgetTemp.AnnualisedPVRentSemiGross__c = 150000;
                spaceBudgetTemp.AnnualisedPVRentNet__c = 150000;
                spaceBudgetTemp.AnnualisedPVRentGross__c = 150000;
                spaceBudgetTemp.PromotionalAllowance__c = 250000;
                spaceBudgetTemp.CapitalSiteEstablishment__c = 250000;

                spaceBudgetList.add(spaceBudgetTemp);
            }
        }

        Database.insert(spaceBudgetList);

        Space__c spaceTemp;
        for(SpaceBudgetAndForecast__c sBudget : spaceBudgetList){
            if(spaceMap.containsKey(sBudget.Space__c)){
                spaceTemp = spaceMap.get(sBudget.Space__c);
                if(Constants.BUDGET.equalsIgnoreCase(sBudget.ModelType__c)){
                    spaceTemp.LatestBudget__c = sBudget.Id;
                } else if(Constants.JV_BUDGET.equalsIgnoreCase(sBudget.ModelType__c)){
                    spaceTemp.LatestJVBudget__c = sBudget.Id;
                } else if(Constants.FORECAST.equalsIgnoreCase(sBudget.ModelType__c)){
                    spaceTemp.LatestForecast__c = sBudget.Id;
                }
            }
        }
		Billcode__c abc = new Billcode__c();
        abc.Active__c = true;
        abc.BillCode__c = 'ABC';
        abc.BillCodeDescription__c = 'abc';
        Database.insert(abc);
        Database.update(spaceMap.values());
        Product2 prodRec = new Product2();
        prodRec = TestDataFactory.createProduct('Test Name', 'Fam');
        prodRec.Family = 'Recoveries';
        prodRec.Billcode__c = abc.Id;
        prodRec.OutgoingsCategory__c = 'Land Tax';			// --- code coverage: 'Cleaning' is not included in Label.SpaceReconfig_OutgoingCategory
        prodRec.EffectiveFromDate__c = Date.today();
        database.insert(prodRec);
        
        List<SpaceProduct__c> spaceProdList = new List<SpaceProduct__c>();
        spaceProdList = TestDataFactory.createSpaceProduct(1, spaceTemp, '', prodRec);
        spaceProdList[0].CalculationMethod__c = 'Fixed';
        spaceProdList[0].CurrencyIsoCode = 'AUD';
        database.insert(spaceProdList);
    }

    @isTest
    public static void runBatch(){
        Space__c space = new Space__c();
        List<Space__c> newSpaceList = new List<Space__c>();
		space = [SELECT Id, Property__c FROM Space__c WHERE LatestBudget__c != null LIMIT 1];
        Id propertyId = space.Property__c;
        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        space.UsableArea__c = 100;
        space.Relationship__c = 'Parent';
        space.MainFloor__c = '0';
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        space.UsableArea__c = 40;
        space.Relationship__c = 'Child';
        space.Property__c = propertyId;
        space.MainFloor__c = '0';
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.UsableArea__c = 60;
        space.Relationship__c = 'Child';
        space.Property__c = propertyId;
        space.MainFloor__c = '0';
        space.ReasonForChange__c = 'Lost Space';
        newSpaceList.add(space);
		
        upsert newSpaceList;
        
        List<SpaceGroup__c> spaceGroups = new List<SpaceGroup__c>();
        SpaceGroup__c spaceGroup = new SpaceGroup__c();
        spaceGroup.Active__c = true;
        spaceGroup.ChildSpace__c = newSpaceList[1].Id;
        spaceGroup.ParentSpace__c = newSpaceList[0].Id;
        spaceGroups.add(spaceGroup);
        
        spaceGroup = new SpaceGroup__c();
        spaceGroup.Active__c = true;
        spaceGroup.ChildSpace__c = newSpaceList[2].Id;
        spaceGroup.ParentSpace__c = newSpaceList[0].Id;
        spaceGroups.add(spaceGroup);
        
        insert spaceGroups;
        
        Test.startTest();
        
        SpaceManagementBatchHelper.runSpaceManagementBatch();
        Test.stopTest();
    }
}