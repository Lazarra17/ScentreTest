public class SpaceManagementController{
    public class Response {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String createdSpaces;
        @AuraEnabled
        public String createdSpaceGroups;
        
        public Response(){
            this.message = Constants.EMPTY;
            this.returnValue = Constants.EMPTY;
            this.status = Constants.SUCCESS;
            
            this.createdSpaces = Constants.EMPTY;
            this.createdSpaceGroups = Constants.EMPTY;
        }
    }
    
    public class SpaceWrapper {
        public List<Space__c> spaceList;
        public List<SpaceGroup__c> spaceGroupList;
        public List<PicklistValueWrapper> typePicklistValueList;
    }
    
    public class PicklistValueWrapper{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

    public class SpaceBudgetWrapper{
        public Property__c property = new Property__c();
        public Map<Id,Space__c> parentSpaces = new Map<Id,Space__c>();
        public Map<Id,Space__c> childSpaces = new Map<Id,Space__c>();
        public Map<Id, SpaceBudgetAndForecast__c> spaceBudgetMap = new Map<Id, SpaceBudgetAndForecast__c>();
    }
    
    @AuraEnabled
    public static Response getSpaces(Id propertyId){
        Response res = new Response();
        List<Space__c> spaceList;
        SpaceWrapper spaceWrap = new SpaceWrapper();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceManagementController.class.getName());
        
        try{
            spaceList = DatabaseSOQLBank.getActiveSpaces(propertyId);
            
            spaceWrap.spaceList = spaceList;
        } catch(Exception e){
            errorHandler.createError(e);
            res.status = Constants.FAILED;
            res.message = e.getMessage();
        }
        
        spaceWrap.typePicklistValueList = getPicklistValues(Constants.SPACE, Constants.API_TYPE);
        
        res.returnValue = JSON.serialize(spaceWrap);
        
        errorHandler.save();
        return res;
    }
    
    @AuraEnabled
    public static Response createSpaces(Property__c property, String sourceSpaceListJSON, String newSpaceListJSON, String mode){
        Decimal totalArea;
        String billingCategory;
        Id prospSpaceRecordTypeId;
        Response res = new Response();
        SpaceGroup__c spaceGroupTemp;
        Space__c spaceTemp = new Space__c();
        SpaceWrapper spaceWrapper = new SpaceWrapper();
        SpaceBudgetWrapper sbWrapper = new SpaceBudgetWrapper(); // RPP-10807
        Set<Id> sourceSpaceIdSet = new Set<Id>();
        List<Space__c> newSpaceList = new List<Space__c>();
        List<Space__c> sourceSpaceList = new List<Space__c>();
        //List<Space__c> spaceListForUpdate = new List<Space__c>();
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        List<SpaceProduct__c> spaceProductList = new List<SpaceProduct__c>();
        List<SpaceProduct__c> spaceProductList2 = new List<SpaceProduct__c>();
        List<SpaceBudgetAndForecast__c> spaceBudgetList = new List<SpaceBudgetAndForecast__c>();
        Map<Id, Space__c> newSpaceMap = new Map<Id, Space__c>();
        
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceManagementController.class.getName());
        
        prospSpaceRecordTypeId = RecordTypeUtil.getAllRecordTypesByName(Constants.SPACE).get(Constants.PROSPECTIVE_SPACE).getRecordTypeId();
        
        newSpaceList = (List<Space__c>) JSON.deserialize(newSpaceListJSON, List<Space__c>.class);
        sourceSpaceList = (List<Space__c>) JSON.deserialize(sourceSpaceListJSON, List<Space__c>.class);
        
        system.debug('before insert-newSpaceList'+newSpaceList);
        system.debug('before insert-sourceSpaceList'+sourceSpaceList);
        
        billingCategory = sourceSpaceList[0].BillingCategory__c;
        for(Space__c sourceSpace : sourceSpaceList){
            sourceSpaceIdSet.add(sourceSpace.Id);
            sourceSpace.Relationship__c = 'Parent';
            
            if(billingCategory != null){
                if(!billingCategory.equalsIgnoreCase(sourceSpace.BillingCategory__c)){
                    billingCategory = Constants.NA;
                    break;
                }
            } else {
                billingCategory = Constants.NA;
                break;
            }
        }
        
        database.update(sourceSpaceList);
        
        for(Space__c newSpace : newSpaceList){
            newSpace.RecordTypeId = prospSpaceRecordTypeId;
            newSpace.Property__c = sourceSpaceList[0].Property__c;
            newSpace.MainFloor__c = sourceSpaceList[0].MainFloor__c; // START-END : YN RPP-4045 7.10.2018
            //newSpace.SpaceUID__c = newSpace.Name;
            newSpace.DevelopmentType__c = null;
            newSpace.BillingCategory__c = billingCategory;
            newSpace.Relationship__c = 'Child';
            newSpace.CurrencyIsoCode = sourceSpaceList[0].CurrencyIsoCode;  //10759
            //System.debug('newSpace CURRENcY ISO CODE'+newSpace.CurrencyIsoCode);
        }
        
        sourceSpaceList = DatabaseSOQLBank.getSpaces(sourceSpaceIdSet);
        /*totalArea = 0;
        for(Space__c sourceSpace : sourceSpaceList){
            totalArea =+ totalArea + sourceSpace.RentableArea__c;
        }*/
        
        //System.debug('newSpaceList CURRENcY ISO CODE'+newSpaceList[0].CurrencyIsoCode);
        
        try{
            Database.insert(newSpaceList);
            CreateForecastOpportunity.checkSpaceCriteria(newSpaceList);
            newSpaceMap.putAll(newSpaceList);
            
            newSpaceList = DatabaseSOQLBank.getSpaces(newSpaceMap.keySet());
            
            system.debug('newSpaceList : ' + newSpaceList);
            //System.debug('newSpaceList :'+ newSpaceList[0].CurrencyIsoCode);
            spaceWrapper.spaceList = newSpaceList;
        } catch(Exception e){
            system.debug('Exception----'+e.getMessage()+'----'+e.getStackTraceString());
            res.status = Constants.FAILED;
            res.message = e.getMessage();
            errorHandler.createError(e);
        }
        
        /*if(res.status != Constants.FAILED){
            try{
                Database.update(spaceListForUpdate);

                sourceSpaceList = DatabaseSOQLBank.getSpaces(sourceSpaceIdSet);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }*/
        
        spaceGroupList = createSpaceGroup(property, mode, sourceSpaceList, newSpaceList);
        
        if(res.status != Constants.FAILED){
            try{
                Database.insert(spaceGroupList);
                
                spaceWrapper.spaceGroupList = spaceGroupList;
                res.returnValue = JSON.serialize(spaceWrapper);
            } catch(Exception e){
                res.status = Constants.FAILED;
                res.message = e.getMessage();
                errorHandler.createError(e);
            }
            
            List<Space__c> childSpaceList = newSpaceList;
            totalArea = 0;
            for(Space__c childSpace : childSpaceList){
                totalArea =+ totalArea + childSpace.RentableArea__c;
            }
            newSpaceList = calculateCurrenRent(sourceSpaceList, newSpaceList);
            // RPP-10807 START
            Set<Id> latestBudgetIds = new Set<Id>();
            latestBudgetIds = getLatestBudgetIds(sourceSpaceList);

            sbWrapper.childSpaces.putAll(newSpaceList);
            sbWrapper.parentSpaces.putAll(sourceSpaceList);
            sbWrapper.property = property;
            sbWrapper.spaceBudgetMap = DatabaseSOQLBank.getSpaceBudget(latestBudgetIds);
            spaceBudgetList = createSpaceBudget(sbWrapper);
            // RPP-10807 END
            System.debug('LISTTO MAP'+ newSpaceList);
            newSpaceMap = new Map<Id, Space__c>(newSpaceList);
            
            try{
                Database.insert(spaceBudgetList);
            } catch(Exception e){
                res.status = Constants.FAILED;
                res.message = e.getMessage();
                errorHandler.createError(e);
            }
            
            for(SpaceBudgetAndForecast__c sBudget : spaceBudgetList){
                if(newSpaceMap.containsKey(sBudget.Space__c)){
                    spaceTemp = newSpaceMap.get(sBudget.Space__c);
                    if(Constants.BUDGET.equalsIgnoreCase(sBudget.ModelType__c)){
                        spaceTemp.LatestBudget__c = sBudget.Id;
                    } else if(Constants.JV_BUDGET.equalsIgnoreCase(sBudget.ModelType__c)){
                        spaceTemp.LatestJVBudget__c = sBudget.Id;
                    } else if(Constants.FORECAST.equalsIgnoreCase(sBudget.ModelType__c)){
                        spaceTemp.LatestForecast__c = sBudget.Id;
                    }
                }
            }
            
            try{
                Database.update(newSpaceMap.values());
            } catch(Exception e){
                res.status = Constants.FAILED;
                res.message = e.getMessage();
                errorHandler.createError(e);
            }
            
            try{
                system.debug('--newSpaceList---'+newSpaceList);
                spaceProductList = createChildSpaceProduct(sourceSpaceIdSet, newSpaceList);
                //spaceProductList2 = createChildSpaceProductMethod(totalArea, sourceSpaceIdSet, childSpaceList);
                spaceProductList2 = generateChildSpaceProductsForOutgoings(totalArea, sourceSpaceIdSet, childSpaceList);

            } catch(Exception e){
                errorHandler.createError(e);
            }
            
            if(spaceProductList != null && spaceProductList.size() > 0){
                try{
                    Database.insert(spaceProductList);
                } catch(Exception e){
                    res.status = Constants.FAILED;
                    res.message = e.getMessage();
                    errorHandler.createError(e);
                }
            }
            if(spaceProductList2 != null && spaceProductList2.size() > 0){
                try{
                    Database.insert(spaceProductList2);
                } catch(Exception e){
                    res.status = Constants.FAILED;
                    res.message = e.getMessage();
                    errorHandler.createError(e);
                }
            }
        }
        
        errorHandler.save();
        
        return res;
    }
    
    public static List<SpaceProduct__c> createChildSpaceProduct(Set<Id> sourceSpaceIdSet, List<Space__c> childSpaceList){
        Space__c parentSpaceTemp;
        Set<String> outgoingCategorySet = new Set<String>();
        Set<String> createdSProductCategorySet = new Set<String>();
        List<SpaceProduct__c> spaceProductList = new List<SpaceProduct__c>();
        
        for(String outgoingCategory : Label.SpaceReconfig_OutgoingCategory.split(Constants.SEMICOLON)){
            outgoingCategorySet.add(outgoingCategory);
        }
        
        for(SpaceProduct__c sProduct : DatabaseSOQLBank.getSpaceProduct(outgoingCategorySet, sourceSpaceIdSet)){
            if(!createdSProductCategorySet.contains(sProduct.Product__r.Name)){
                for(Space__c cSpace : childSpaceList){
                    spaceProductList.add(createSpaceProduct(sProduct, cSpace));
                }
                
                createdSProductCategorySet.add(sProduct.Product__r.Name);
            }
        }
        
        return spaceProductList;
    }
    
    public static List<SpaceProduct__c> generateChildSpaceProductsForOutgoings(Decimal totalArea, Set<Id> sourceSpaceIdSet, List<Space__c> childSpaceList){
        List<SpaceProduct__c> spaceProductList = new List<SpaceProduct__c>();
        Set<String> outgoingCategorySet = new Set<String>();

        for(String outgoingCategory : Label.SpaceReconfig_OutgoingCategory.split(Constants.SEMICOLON)){
            outgoingCategorySet.add(outgoingCategory);
        }

        List<SpaceProduct__c> sProductList = DatabaseSOQLBank.getFixedSpaceProduct(outgoingCategorySet, sourceSpaceIdSet);
		System.debug('sProductList: '+sProductList);
        Set<Id> spcProductCreated = new Set<Id>();
        Map<Id, Decimal> outgoingParentSpcProductsVsTotalSalesPrice = new Map<Id, Decimal>();

        for(SpaceProduct__c parentSpcProduct : sProductList){
            if(outgoingParentSpcProductsVsTotalSalesPrice.containsKey(parentSpcProduct.Product__c)){
                Decimal cuSalesPrice = outgoingParentSpcProductsVsTotalSalesPrice.get(parentSpcProduct.Product__c) + parentSpcProduct.SalesPrice__c;
                outgoingParentSpcProductsVsTotalSalesPrice.put(parentSpcProduct.Product__c, cuSalesPrice);
                cuSalesPrice = 0;
            }else{
                outgoingParentSpcProductsVsTotalSalesPrice.put(parentSpcProduct.Product__c, parentSpcProduct.SalesPrice__c);
            }
        }

        System.debug('outgoingParentSpcProductsVsTotalSalesPrice: '+outgoingParentSpcProductsVsTotalSalesPrice);

        for(SpaceProduct__c parentSpcProduct : sProductList){
            if(!outgoingCategorySet.contains(parentSpcProduct.Product__r.OutgoingsCategory__c))
                continue;
            if(spcProductCreated.contains(parentSpcProduct.Product__c))
                continue;

            for(Space__c childSpc : childSpaceList){
                Decimal totalSalesPrice = outgoingParentSpcProductsVsTotalSalesPrice.get(parentSpcProduct.Product__c);
                System.debug('totalSalesPrice: '+totalSalesPrice);
                SpaceProduct__c spaceProduct = new SpaceProduct__c();
                spaceProduct.Description__c = parentSpcProduct.Description__c;
                spaceProduct.CalculationMethod__c = parentSpcProduct.CalculationMethod__c;
                spaceProduct.EffectiveFromDate__c = parentSpcProduct.EffectiveFromDate__c;
                spaceProduct.EffectiveToDate__c = parentSpcProduct.EffectiveToDate__c;
                spaceProduct.Percentage__c = parentSpcProduct.Percentage__c;
                spaceProduct.Product__c = parentSpcProduct.Product__c;
                spaceProduct.ProductFamily__c = parentSpcProduct.ProductFamily__c;
                spaceProduct.CurrencyIsoCode = parentSpcProduct.CurrencyIsoCode; //10759

                Decimal percentage = (childSpc.RentableArea__c / totalArea)*100;
                Decimal cuSalesPrice = (percentage / 100) * totalSalesPrice;

                System.debug('percentage: '+percentage);
                System.debug('cuSalesPrice: '+cuSalesPrice);

                spaceProduct.SalesPrice__c = cuSalesPrice;
                spaceProduct.Space__c = childSpc.Id;
                
                System.debug('spaceProduct.SalesPrice__c: '+spaceProduct.SalesPrice__c);

                spaceProductList.add(spaceProduct);
            }
            spcProductCreated.add(parentSpcProduct.Product__c);
        }

        return spaceProductList;
    }

    /*public static List<SpaceProduct__c> createChildSpaceProductMethod(Decimal totalArea, Set<Id> sourceSpaceIdSet, List<Space__c> childSpaceList){
        List<SpaceProduct__c> spaceProductList = new List<SpaceProduct__c>();
        Set<String> outgoingCategorySet = new Set<String>();
        for(String outgoingCategory : Label.SpaceReconfig_OutgoingCategory.split(Constants.SEMICOLON)){
            outgoingCategorySet.add(outgoingCategory);
        }
        
        Map<String, List<SpaceProduct__c>> proCategoryVSspaceProd = new Map<String, List<SpaceProduct__c>>();
        
        List<SpaceProduct__c> sProductList = DatabaseSOQLBank.getFixedSpaceProduct(outgoingCategorySet, sourceSpaceIdSet);
        system.debug('--sProductList--'+sProductList);
        for(SpaceProduct__c sp: sProductList){
            if(proCategoryVSspaceProd.containsKey(sp.Product__r.OutgoingsCategory__c)){
                proCategoryVSspaceProd.get(sp.Product__r.OutgoingsCategory__c).add(sp);
            }
            else{
                proCategoryVSspaceProd.put(sp.Product__r.OutgoingsCategory__c, new List<SpaceProduct__c>{sp});
            }
        }
        
        for(Space__c space : childSpaceList){
            for(string proCategory : outgoingCategorySet){
                if(proCategoryVSspaceProd.containsKey(proCategory)){
                    Decimal TotalSalesPrice = 0;
                    for(SpaceProduct__c sp: proCategoryVSspaceProd.get(proCategory)){
                        TotalSalesPrice =+ TotalSalesPrice + sp.SalesPrice__c;
                    }
                    
                    SpaceProduct__c spaceProduct = new SpaceProduct__c();
                    
                    spaceProduct.Description__c = sp.Description__c;
                    spaceProduct.CalculationMethod__c = sp.CalculationMethod__c;
                    spaceProduct.EffectiveFromDate__c = sp.EffectiveFromDate__c;
                    spaceProduct.EffectiveToDate__c = sp.EffectiveToDate__c;
                    spaceProduct.Percentage__c = sp.Percentage__c;
                    spaceProduct.Product__c = sp.Product__c;
                    spaceProduct.ProductFamily__c = sp.ProductFamily__c;
                    Decimal salesprice = (space.RentableArea__c/totalArea)*TotalSalesPrice;
                    spaceProduct.SalesPrice__c = salesprice;
                    spaceProduct.Space__c = space.Id;
                    spaceProductList.add(spaceProduct);
                }
            }
        }

        Decimal salesprice = (space.RentableArea__c / totalArea) * 100;

        system.debug('----spaceProductList----'+spaceProductList);
        return spaceProductList;
    }*/
    
    public static SpaceProduct__c createSpaceProduct(SpaceProduct__c sourceSProduct, Space__c childSpace){
        SpaceProduct__c spaceProduct = new SpaceProduct__c();
        
        spaceProduct.Description__c = sourceSProduct.Description__c;
        spaceProduct.CalculationMethod__c = sourceSProduct.CalculationMethod__c;
        spaceProduct.EffectiveFromDate__c = sourceSProduct.EffectiveFromDate__c;
        spaceProduct.EffectiveToDate__c = sourceSProduct.EffectiveToDate__c;
        spaceProduct.Percentage__c = sourceSProduct.Percentage__c;
        spaceProduct.Product__c = sourceSProduct.Product__c;
        spaceProduct.ProductFamily__c = sourceSProduct.ProductFamily__c;
        spaceProduct.SalesPrice__c = sourceSProduct.SalesPrice__c;
        spaceProduct.Space__c = childSpace.Id;
        spaceProduct.CurrencyIsoCode = sourceSProduct.CurrencyIsoCode; //10759
        
        return spaceProduct;
    }
    
    public static List<SpaceGroup__c> createSpaceGroup(
        Property__c property, String mode, List<Space__c> sourceSpaceList, List<Space__c> childSpaceList){
            
            Integer latestSpaceGroupNumber;
            SpaceGroup__c spaceGroupTemp;
            List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
            
            ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceManagementController.class.getName());
            
            try{
                AggregateResult result = DatabaseSOQLBank.getMaxSpaceGroupNumber();
                
                latestSpaceGroupNumber = Integer.valueOf(result.get(Constants.ALIAS_MAXSPACEGROUPNUMBER));
                latestSpaceGroupNumber = latestSpaceGroupNumber != null ? latestSpaceGroupNumber : 0;
            } catch(Exception e) {
                errorHandler.createError(e);
                latestSpaceGroupNumber = 0;
            }
            
            for(Space__c parentSpace: sourceSpaceList){
                for(Space__c childSpace: childSpaceList){
                    spaceGroupTemp = new SpaceGroup__c();
                    spaceGroupTemp.Active__c = true;
                    spaceGroupTemp.Name = property.JDEPropertyNumber__c + Constants.UNDERSCORE_NO_SPACE 
                        + parentSpace.Name + Constants.UNDERSCORE_NO_SPACE 
                        + childSpace.Name + Constants.UNDERSCORE_NO_SPACE 
                        + System.DateTime.now().format(Constants.DATE_FORMAT_DDMMYYYY);
                    spaceGroupTemp.ParentSpace__c = parentSpace.id;
                    spaceGroupTemp.ChildSpace__c = childSpace.id;
                    //spaceGroupTemp.CurrencyIsoCode = parentSpace.CurrencyIsoCode; //10759
                    spaceGroupTemp.SpaceGroupNumber__c = latestSpaceGroupNumber + 1;
                    
                    if(Constants.SPACE_SPLIT.equalsIgnoreCase(mode)){
                        spaceGroupTemp.Type__c = Constants.RECONFIGURATION_SPLIT;
                    } else if(Constants.SPACE_MERGE.equalsIgnoreCase(mode)){
                        spaceGroupTemp.Type__c = Constants.RECONFIGURATION_MERGE;
                    }
                    
                    spaceGroupList.add(spaceGroupTemp);
                }
            }
            
            return spaceGroupList;
        }
    
    public static List<Space__c> calculateCurrenRent(List<Space__c> spaceList, List<Space__c> childSpaceList){
        Decimal totalArea = 0;
        Decimal rentPerArea = 0;
        Decimal rentPerAreaSemiGross = 0;
        Decimal totalCurrentRent = 0;
        Decimal totalCurrentRentSemiGross = 0; //NG
        Decimal reconfiguredCurrentRent = 0;
        Decimal reconfiguredCurrentRentSemiGross = 0;//NG
        Set<String> excludedTypeForRentSplitSet = new Set<String>();
        List<Space__c> spaceListTemp = new List<Space__c>();
        
        for(String str : Label.SpaceReconfig_BudgetSplitExcludedSpaceType.split(Constants.SEMICOLON)){
            excludedTypeForRentSplitSet.add(str);
        }
        
        //system.debug('spaceList : ' + spaceList);
        //system.debug('childSpaceList : ' + childSpaceList);
        
        for(Space__c space : spaceList){
            if(!excludedTypeForRentSplitSet.contains(space.Type__c)){
                //totalArea += space.RentableArea__c;
                
                if(space.CurrentLease__c != null && space.CurrentRent__c != null){
                    totalCurrentRent += space.CurrentRent__c;
                    totalCurrentRentSemiGross += space.CurrentSemiGrossRent__c;//NG
                } else if (space.PreviousLease__c != null && space.PreviousRent__c != null){
                    totalCurrentRent += space.PreviousRent__c;
                    totalCurrentRentSemiGross += space.PreviousSemiGrossRent__c;//NG            
                }
                else if(space.ReconfiguredCurrentRent__c != null && space.ReconfiguredCurrentRentSemiGross__c != null){
                    totalCurrentRent += space.ReconfiguredCurrentRent__c;
                    totalCurrentRentSemiGross += space.ReconfiguredCurrentRentSemiGross__c;
                }
            }
        }
        
        for(Space__c space : childSpaceList){
            if(space != null && !excludedTypeForRentSplitSet.contains(space.Type__c)){
                if(space.RentableArea__c != null){
                    totalArea += space.RentableArea__c;
                }
            }
        }
        
        //system.debug('childSpaceList : totalCurrentRent: ' + totalCurrentRent);
        //system.debug('childSpaceList : totalCurrentRentSemiGross: ' + totalCurrentRentSemiGross);
        //system.debug('childSpaceList : totalArea: ' + totalArea);
        
        if(totalCurrentRent != null && totalCurrentRent != null && totalArea > 0){
            rentPerArea = totalCurrentRent / totalArea;
        }
        
        if(totalCurrentRentSemiGross != null && totalArea > 0){
            rentPerAreaSemiGross = totalCurrentRentSemiGross / totalArea;
        }
        
        //system.debug('childSpaceList : rentPerAreaSemiGross: ' + rentPerAreaSemiGross);
        
        
        for(Space__c space : childSpaceList){
            if(!excludedTypeForRentSplitSet.contains(space.Type__c)){
                reconfiguredCurrentRent = rentPerArea * space.RentableArea__c;
                reconfiguredCurrentRentSemiGross = rentPerAreaSemiGross * space.RentableArea__c;
                
                if(((space.ReconfiguredCurrentRent__c == null && reconfiguredCurrentRent != 0) || space.ReconfiguredCurrentRent__c != reconfiguredCurrentRent) || 
                    ((space.ReconfiguredCurrentRentSemiGross__c == null && reconfiguredCurrentRentSemiGross != 0) || space.ReconfiguredCurrentRentSemiGross__c != reconfiguredCurrentRentSemiGross)){
                    space.ReconfiguredCurrentRent__c = reconfiguredCurrentRent;
                    space.ReconfiguredCurrentRentSemiGross__c = reconfiguredCurrentRentSemiGross;
                    spaceListTemp.add(space);
                }
            }
        }
        
        return spaceListTemp;
    }

    public static Set<Id> getLatestBudgetIds(List<Space__c> spaceList){
        Set<Id> spaceBudgetIdSet = new Set<Id>();
        List<String> budgetFields = Label.SpaceReconfig_BudgetToSplit.split(Constants.SEMICOLON);
        Map<String,Schema.SObjectField> spaceObjectSchema = Schema.SObjectType.Space__c.fields.getMap();

        for(Space__c space : spaceList){
            for(String budgetField : budgetFields){
                if(spaceObjectSchema.containsKey(budgetField)
                    && space.get(budgetField) != null){
                    spaceBudgetIdSet.add((Id)space.get(budgetField));
                }
            }
        }
        return spaceBudgetIdSet;
    }
    
    public static List<SpaceBudgetAndForecast__c> createSpaceBudget(SpaceBudgetWrapper sbWrapper){ // RPP-10807 - Changed Signature
            Decimal amountTemp;
            Decimal totalArea = 0;
            Boolean areAllStoreRoom = true;
            Date effectiveDate;
            SpaceBudgetAndForecast__c spaceBugetTemp;        
            SpaceBudgetAndForecast__c newSpaceBugetTemp;
            SpaceBudgetAndForecast__c existingSBugetTemp;
            List<SpaceBudgetAndForecast__c> existingSpaceBudgetList;
            List<SpaceBudgetAndForecast__c> newSpaceBudgetList = new List<SpaceBudgetAndForecast__c>();
            Map<Id, SpaceBudgetAndForecast__c> spaceBudgetMap = new Map<Id, SpaceBudgetAndForecast__c>();
            Map<String, SpaceBudgetAndForecast__c> modelTypeSpaceBudgetMap = new Map<String, SpaceBudgetAndForecast__c>();
            Map<Id, Map<String, SpaceBudgetAndForecast__c>> spaceIdModelTypeBudgetMapMap = new Map<Id, Map<String, SpaceBudgetAndForecast__c>>();

            //RPP-10807 START
            Property__c property = sbWrapper.property;
            List<Space__c> spaceList = sbWrapper.parentSpaces.values();
            List<Space__c> newSpaceList = sbWrapper.childSpaces.values();
            spaceBudgetMap = sbWrapper.spaceBudgetMap;
            //RPP-10807 END

            Set<String> fieldsToCalculateSet = new Set<String>();
            Set<String> budgetFieldToCalculateSet = new Set<String>();
            Set<String> excludedTypeForBudgetSplitSet = new Set<String>();
            
            for(String str : Label.SpaceReconfig_BudgetToSplit.split(Constants.SEMICOLON)){
                budgetFieldToCalculateSet.add(str);
            }
            
            for(String str : Label.SpaceReconfig_BudgetSplitFields.split(Constants.SEMICOLON)){
                fieldsToCalculateSet.add(str);
            }
            
            for(String str : Label.SpaceReconfig_BudgetSplitExcludedSpaceType.split(Constants.SEMICOLON)){
                excludedTypeForBudgetSplitSet.add(str);
            }
            
            for(Space__c space : spaceList){
                if(!Constants.STOREROOM.equalsIgnoreCase(space.Type__c)){
                    areAllStoreRoom = false;
                }
            }
            
            for(Space__c space : newSpaceList){
                //if(!excludedTypeForBudgetSplitSet.contains((String) space.get(Constants.ALIAS_TYPELABEL))){
                if(!excludedTypeForBudgetSplitSet.contains(space.Type__c)){
                    totalArea += space.RentableArea__c;
                }
            }
            
            for(Space__c space : spaceList){
                //if(areAllStoreRoom || !Constants.STOREROOM.equalsIgnoreCase((String) space.get(Constants.ALIAS_TYPELABEL))){
                if(areAllStoreRoom || !Constants.STOREROOM.equalsIgnoreCase(space.Type__c)){    
                    for(String budgetField : budgetFieldToCalculateSet){
                        if(spaceBudgetMap.containsKey((Id) space.get(budgetField))){
                            existingSBugetTemp = spaceBudgetMap.get((Id) space.get(budgetField));
                            effectiveDate = existingSBugetTemp.EffectiveDate__c;
                            if(existingSBugetTemp.ModelType__c != null){
                                if(modelTypeSpaceBudgetMap.containsKey(existingSBugetTemp.ModelType__c)){
                                    spaceBugetTemp = modelTypeSpaceBudgetMap.get(existingSBugetTemp.ModelType__c);
                                    
                                    for(String fieldName : fieldsToCalculateSet){
                                        amountTemp = (Decimal) spaceBugetTemp.get(fieldName);
                                        amountTemp += (Decimal) (existingSBugetTemp.get(fieldName) != null ? existingSBugetTemp.get(fieldName) : 0);
                                        spaceBugetTemp.put(fieldName, amountTemp);
                                    }
                                } else {
                                    spaceBugetTemp = new SpaceBudgetAndForecast__c();
                                    spaceBugetTemp.BudgetedDealType__c = existingSBugetTemp.BudgetedDealType__c;
                                    
                                    for(String fieldName : fieldsToCalculateSet){
                                        amountTemp = (Decimal)(existingSBugetTemp.get(fieldName) != null ? existingSBugetTemp.get(fieldName) : 0);
                                        spaceBugetTemp.put(fieldName, amountTemp);
                                    }
                                    
                                    modelTypeSpaceBudgetMap.put(existingSBugetTemp.ModelType__c, spaceBugetTemp);
                                }
                            }
                        }
                    }
                }
            }
            
            for(Space__c space : newSpaceList){
                for(String modelType : modelTypeSpaceBudgetMap.keySet()){
                    newSpaceBugetTemp = new SpaceBudgetAndForecast__c();
                    spaceBugetTemp = modelTypeSpaceBudgetMap.get(modelType);
                    
                    newSpaceBugetTemp.Name = property.JDEPropertyNumber__c + Constants.UNDERSCORE_NO_SPACE 
                        + modelType + Constants.UNDERSCORE_NO_SPACE 
                        + spaceBugetTemp.BudgetedDealType__c + Constants.UNDERSCORE_NO_SPACE
                        + space.Name + Constants.UNDERSCORE_NO_SPACE 
                        + System.DateTime.now().format('ddMMyyyy');
                    newSpaceBugetTemp.ModelType__c = modelType;
                    newSpaceBugetTemp.Space__c = space.Id;
                    newSpaceBugetTemp.BudgetedDealType__c = spaceBugetTemp.BudgetedDealType__c;
                    newSpaceBugetTemp.CurrencyIsoCode = space.CurrencyIsoCode; //added for 10759
                    newSpaceBugetTemp.Batch_Process_Status__c = null; //added for 10807
                    newSpaceBugetTemp.EffectiveDate__c = effectiveDate; // RPP - 10807
                    
                    //if(!excludedTypeForBudgetSplitSet.contains((String) space.get(Constants.ALIAS_TYPELABEL))){
                    if(!excludedTypeForBudgetSplitSet.contains(space.Type__c)){
                        for(String fieldName : fieldsToCalculateSet){
                            amountTemp = (((Decimal) spaceBugetTemp.get(fieldName)) / totalArea) * space.RentableArea__c;
                            newSpaceBugetTemp.put(fieldName, amountTemp);
                        }
                    } else {
                        for(String fieldName : fieldsToCalculateSet){
                            newSpaceBugetTemp.put(fieldName, 0);
                        }
                    }
                    
                    newSpaceBudgetList.add(newSpaceBugetTemp);
                }
            }
            
            return newSpaceBudgetList;
        }
    
    public static List<PicklistValueWrapper> getPicklistValues(String objectName, String fieldName) {
        PicklistValueWrapper picklistValueTemp;
        List<PicklistValueWrapper> picklistValueList = new List<PicklistValueWrapper>();
        List<String> objectList = new List<String>{objectName};
            
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(objectList);
        
        for(Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    picklistValueTemp = new PicklistValueWrapper();
                    picklistValueTemp.label = entry.getLabel();
                    picklistValueTemp.value = entry.getValue();
                    
                    picklistValueList.add(picklistValueTemp);
                }
            }
        }
        
        return picklistValueList;
    }
    
    @AuraEnabled
    public static Boolean hasUserAccess(){
        Boolean hasUserAccess = true;
        Profile pro = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        
        if(!Label.SpaceManagementAllowedProfiles.contains(pro.Name)){
            hasUserAccess = false;
        }
        
        return hasUserAccess;
    }
}