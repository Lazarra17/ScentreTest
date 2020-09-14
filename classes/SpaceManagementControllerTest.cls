@isTest
private class SpaceManagementControllerTest {
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

    public static testMethod void testGetSpaces(){
        SpaceManagementController.Response res;
        SpaceManagementController.SpaceWrapper spaceWrap;
        Property__c property = [SELECT Id, Name FROM Property__c];

        Test.startTest();
            res = SpaceManagementController.getSpaces(property.Id);
        Test.stopTest();

        system.assertEquals(res.status, 'SUCCESS');
        spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        system.assertEquals(5, spaceWrap.spaceList.size());
    }

    public static testMethod void testCreateSpacesMerge(){
        Property__c property = [SELECT Id,Property__c.JDEPropertyNumber__c,  Name FROM Property__c];
        String sourceSpaceListJSON;
        String newSpaceListJSON;

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceListJSON = JSON.serialize(spaceWrap.spaceList);

        Space__c space = new Space__c();
        List<Space__c> newSpaceList = new List<Space__c>();

        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.ReasonForChange__c = 'Lost Space';
        newSpaceList.add(space);

        newSpaceListJSON = JSON.serialize(newSpaceList);

        Test.startTest();
            SpaceManagementController.createSpaces(property, sourceSpaceListJSON, newSpaceListJSON, 'merge');
        Test.stopTest();
    }

    public static testMethod void testCreateSpacesSplit(){
        Property__c property = [SELECT Id, Name, Property__c.JDEPropertyNumber__c FROM Property__c];
        String sourceSpaceListJSON;
        String newSpaceListJSON;

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceListJSON = JSON.serialize(spaceWrap.spaceList);

        Space__c space = new Space__c();
        List<Space__c> newSpaceList = new List<Space__c>();

        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.ReasonForChange__c = 'Lost Space';
        newSpaceList.add(space);

        newSpaceListJSON = JSON.serialize(newSpaceList);

        Test.startTest();
            SpaceManagementController.createSpaces(property, sourceSpaceListJSON, newSpaceListJSON, 'split');
        Test.stopTest();
    }

    public static testMethod void testCreateSpacesError(){
        Property__c property = [SELECT Id, Name, Property__c.JDEPropertyNumber__c FROM Property__c];
        String sourceSpaceListJSON;
        String newSpaceListJSON;

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceListJSON = JSON.serialize(spaceWrap.spaceList);

        Space__c space = new Space__c();
        List<Space__c> newSpaceList = new List<Space__c>();

        space.Type__c = '2';
        space.Name = 'SP00016';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP000*';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        newSpaceListJSON = JSON.serialize(newSpaceList);

        Test.startTest();
            SpaceManagementController.createSpaces(property, sourceSpaceListJSON, newSpaceListJSON, 'split');
        Test.stopTest();
    }
    
    private static testMethod void createSpaceProductTest() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        SpaceProduct__c spaceProdRec = new SpaceProduct__c();
        List<SpaceProduct__c> spaceProdList = new List<SpaceProduct__c>([SELECT Id, Description__c, CalculationMethod__c, 
                                                                         EffectiveFromDate__c, EffectiveToDate__c,CurrencyIsoCode, 
                                                                         Percentage__c, Product__c, ProductFamily__c, 
                                                                         SalesPrice__c 
                                                                         FROM SpaceProduct__c]);
        List<Space__c> spaceList = new List<Space__c>([SELECT Id FROM Space__c]);
        system.runAs(testUser) {
            test.startTest();
            spaceProdRec = SpaceManagementController.createSpaceProduct(spaceProdList[0], spaceList[0]);
            test.stopTest();
        }
    }
    
    private static testMethod void testHasUserAccess() {
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = :CONSTANTS.SCG_SYS_ADM LIMIT 1];
        User testUser = TestDataFactory.createUniqueTestUser('John', 'Doe', profileRec.Id);
        Boolean hasUserAccess;
        system.runAs(testUser) {
            test.startTest();
            hasUserAccess = SpaceManagementController.hasUserAccess();
            test.stopTest();
        }
        System.assert(hasUserAccess);
    }
    
    private static testMethod void testCreateChildSpaceProduct() {
        Property__c property = [SELECT Id,Property__c.JDEPropertyNumber__c,  Name FROM Property__c];

        List<Space__c> sourceSpaceList = new List<Space__c>();
        List<Space__c> newSpaceList = new List<Space__c>();
        Set<Id> sourceSpaceIdSet = new Set<Id>();

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceList = spaceWrap.spaceList;

        
        for(Space__c sourceSpace : sourceSpaceList){
            sourceSpaceIdSet.add(sourceSpace.Id);
        }
        
        Space__c space = new Space__c();
        
        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.ReasonForChange__c = 'Lost Space';
        newSpaceList.add(space);

        Test.startTest();
            SpaceManagementController.createChildSpaceProduct(sourceSpaceIdSet, newSpaceList);
        Test.stopTest();
    }
    
    private static testMethod void testGenerateChildSpaceProductsForOutgoings(){
        Property__c property = [SELECT Id,Property__c.JDEPropertyNumber__c,  Name FROM Property__c];

        List<Space__c> sourceSpaceList = new List<Space__c>();
        List<Space__c> newSpaceList = new List<Space__c>();
        Set<Id> sourceSpaceIdSet = new Set<Id>();

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceList = spaceWrap.spaceList;

        
        for(Space__c sourceSpace : sourceSpaceList){
            sourceSpaceIdSet.add(sourceSpace.Id);
        }
        
        Space__c space = new Space__c();
        
        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        space.CurrencyIsoCode = 'AUD';
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        space.CurrencyIsoCode = 'AUD';
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.ReasonForChange__c = 'Lost Space';
        space.CurrencyIsoCode = 'AUD';
        newSpaceList.add(space);

        Test.startTest();
            SpaceManagementController.generateChildSpaceProductsForOutgoings(9999,sourceSpaceIdSet, newSpaceList);
        Test.stopTest();
    }
    
    private static testMethod void testCalculateCurrenRent() {
        Property__c property = [SELECT Id,Property__c.JDEPropertyNumber__c,  Name FROM Property__c];

        List<Space__c> sourceSpaceList = new List<Space__c>();
        List<Space__c> newSpaceList = new List<Space__c>();

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceList = spaceWrap.spaceList;

        Space__c space = new Space__c();
        

        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.ReasonForChange__c = 'Lost Space';
        newSpaceList.add(space);

        Test.startTest();
            SpaceManagementController.calculateCurrenRent(sourceSpaceList, newSpaceList);
        Test.stopTest();
    } 
    
    private static testMethod void testcreateSpaceBudget() {
        Property__c property = [SELECT Id,Property__c.JDEPropertyNumber__c,  Name FROM Property__c];

        List<Space__c> sourceSpaceList = new List<Space__c>();
        List<Space__c> newSpaceList = new List<Space__c>();

        SpaceManagementController.Response res;
        res = SpaceManagementController.getSpaces(property.Id);
        SpaceManagementController.SpaceWrapper spaceWrap = (SpaceManagementController.SpaceWrapper) JSON.deserialize(res.returnValue, SpaceManagementController.SpaceWrapper.class);
        sourceSpaceList = spaceWrap.spaceList;

        Space__c space = new Space__c();
        

        space.Type__c = '2';
        space.Name = 'SP0001';
        space.RentableArea__c = 100;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '2';
        space.Name = 'SP0002';
        space.RentableArea__c = 40;
        newSpaceList.add(space);

        space = new Space__c();
        space.Type__c = '20';
        space.Name = 'SP0003';
        space.RentableArea__c = 60;
        space.ReasonForChange__c = 'Lost Space';
        newSpaceList.add(space);
		
        SpaceManagementController.SpaceBudgetWrapper sbWrapper = new SpaceManagementController.SpaceBudgetWrapper();
        sbWrapper.childSpaces.putAll(newSpaceList);
        sbWrapper.parentSpaces.putAll(sourceSpaceList);
        sbWrapper.property = property;
        sbWrapper.spaceBudgetMap = DatabaseSOQLBank.getSpaceBudget(SpaceManagementController.getLatestBudgetIds(sourceSpaceList));
        
        Test.startTest();
            SpaceManagementController.createSpaceBudget(sbWrapper);
        Test.stopTest();
    }
    
}