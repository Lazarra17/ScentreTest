public class DatabaseSOQLBank {
    
    public static List<Property__c> getProperty (Set<Id> propertyIdSet) {
        List<Property__c> propertyList = new List<Property__c>();
        
        if(propertyIdSet != null && propertyIdSet.size() > 0) {
            propertyList = [SELECT Id, PropertyShortName__c, DexusProperty__c,
                            Tech_ConcatenatedHoldingCompanyName__c,HoldingCompaniesName__c, Tech_ConcatenatedAccountACN__c,
                            RentReviewType__c, StandardPromoReviewType__c, Country__c, PropertyState__c, PriceBook__c,CurrencyIsoCode //SOQL FIX - 7
                            FROM Property__c 
                            WHERE Id IN: propertyIdSet];
        }
        
        return propertyList;
    }
    
    public static List<ClauseLibrary__c> getLevyClause(){
        List<ClauseLibrary__c> clauseLibList = [SELECT Id, Name 
                         FROM ClauseLibrary__c 
                         WHERE Name =: Constants.PROMOTION_LEVY_CLAUSE_LIBRARY
                         AND RecordType.DeveloperName =: Constants.CLAUSE_RECORD_TYPE_RETAIL_CLAUSE 
                         LIMIT 1];
        return clauseLibList;
    }
    
    public static List<Account> getAccount (Set<Id> propertyIdSet) {
        List<Account> accountList = new List<Account>();
        
        if(propertyIdSet != null && propertyIdSet.size() > 0) {
            accountList = [SELECT Id, Name, Property__c, TradingName__c 
                           FROM Account 
                           WHERE Property__c IN: propertyIdSet];
        }
        
        return accountList;
        
    }
    
    public static List<PrecedentClause__c> getPrecedentClauseOfAccount (List<Id> parentAccountIdList, Id recordTypeId) {
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        
        if(parentAccountIdList != null && parentAccountIdList.size() > 0) {
            precedentClauseList = [SELECT Id, Name, Account__c, Comments__c, 
                                   Description__c, EffectiveToDate__c, Type__c,
                                   StandardReviewTypes__c, PercentageRentPercent__c,FitoutPeriod__c,
                                   StandardPromoReviewType__c, PromoReviewType__c, RentReviewType__c,
                                   SecurityDepositType__c, RequiredSecurityDepositMonths__c, RequiredSecurityDepositWeeks__c,
                                   RequiredSecurityDepositDays__c, SecurityDepositRequired__c, GuaranteesType__c, 
                                   RentReviewDescription__c, RentReviewCappedPercent__c, PromoReviewDescription__c, 
                                   PromoReviewCappedPercent__c, ReferencedClause__c, ReferencedClause__r.RiskApplies__c, 
                                   ReferencedClause__r.ReasonRecommendation__c, Nil_Holdover_Increase__c
                                   FROM PrecedentClause__c 
                                   WHERE Account__c IN: parentAccountIdList
                                   AND Status__c =: Constants.ACTIVE 
                                   AND RecordTypeId = :recordTypeId];
        }
        return precedentClauseList;
    }
    
    //RPP-10989 - START
    public static List<PrecedentClause__c> getNationalAgreementsOfAccount(String accId){
        List<PrecedentClause__c> precedentClauseList = new List<PrecedentClause__c>();
        List<Account> accList = [SELECT Id, ParentId FROM Account WHERE Id =: accid];
        precedentClauseList = [SELECT Id, Nil_Holdover_Increase__c 
                               FROM PrecedentClause__c 
                               WHERE Account__c =: accList[0].ParentId
                               AND Status__c =: Constants.ACTIVE 
                               AND RecordType.Name =: Constants.NATIONAL_AGREEMENTS];
        return precedentClauseList;
    }
    //RPP-10989 - END
    
    public static List<Product2> getProductsToPopulate (List<String> outgoingsNameList) {
        List<Product2> productList = new List<Product2>();
        
        productList = [SELECT Id, Name, IsActive, Description, DefaultPrice__c 
                       FROM Product2 
                       WHERE isActive = TRUE 
                       AND Name LIKE :outgoingsNameList AND ProductCode = :CONSTANTS.OTG];
        
        return productList;
    }
    public static List<PriceBookEntry> getPriceBookEntry (List<Product2> productList) {
        List<PriceBookEntry> pbEntrytList = new List<PriceBookEntry>();
        if(productList.size()>0){
            pbEntrytList = [SELECT UnitPrice,pricebook2id,Id,product2id from PriceBookEntry where product2id in : productList];   
        }
        return pbEntrytList;
    }    
    public static Id getStandardPricebookId() {
        Pricebook2 standardPricebook = new Pricebook2();
        
        try{
            standardPricebook = [SELECT Id 
                                 FROM Pricebook2 
                                 WHERE IsActive = TRUE 
                                 AND IsStandard = TRUE];
        } catch (Exception e) {
            standardPricebook = new Pricebook2();
        }
        
        return standardPricebook.Id;
    }
    
    public static Map<Id, Property__c> getPropertyPricebookMap() {
        Map<Id, Property__c> propertyPricebookMap = new Map<Id, Property__c>([SELECT Id, PriceBook__c,CurrencyIsoCode FROM Property__c]);
        
        if (propertyPricebookMap.size() > 0) {
            return propertyPricebookMap;
        }
        return NULL;
    }
    
    public static Map<Id, Space__c> getOpportunitySpaceMap(List<Id> oppSpaceIdList) {
        Map<Id, Space__c> opportunitySpaceMap = new Map<Id, Space__c>(
            [SELECT Id, Type__c, UsableArea__c 
             FROM Space__c 
             WHERE Id IN: oppSpaceIdList]
        );
        
        if (opportunitySpaceMap.size() > 0) {
            return opportunitySpaceMap;
        }
        
        return NULL;
    }
    
    public static List<Space__c> getSpaces(Set<Id> spaceIdSet){
        List<Space__c> spaceList;
        
        if(spaceIdSet != null && spaceIdSet.size() > 0){
            spaceList = [SELECT Id, Name, RentableArea__c, toLabel(Type__c) TypeLabel, Type__c, ReasonForChange__c, 
                         CurrentRent__c, PreviousRent__c, CurrentSemiGrossRent__c, PreviousSemiGrossRent__c, ReconfiguredCurrentRent__c,  ReconfiguredCurrentRentSemiGross__c, Status__c, Property__c, RecordTypeId,
                         LatestBudget__c, LatestJVBudget__c, LatestForecast__c, OccupancyStatus__c, MainFloor__c,CurrencyIsoCode, //NEEL 10.07.2018 + CurrencyIsocode fetched for 10759
                         CurrentLease__c, CurrentRetailer__c, PreviousTenant__c, PreviousLease__c, CurrentRetailerName__c, CurrentLease__r.ActualVacateDate__c, UsableArea__c, // Arxxus 12.06.2019
                         LatestAchievedOpportunity__c, LatestAchievedOpportunity__r.ActualShopOpenedDate__c, LatestAchievedOpportunity__r.ProposedShopOpeningDate__c
                         FROM Space__c
                         WHERE Id IN: spaceIdSet];
        }
        
        return spaceList;
    }
    
    public static AggregateResult getMaxSpaceGroupNumber(){
        AggregateResult result = 
            [SELECT MAX(SpaceGroupNumber__c) MaxSpaceGroupNumber
             FROM SpaceGroup__c];
        
        return result;
    }
    
    public static List<Space__c> getActiveSpaces(Id propertyId){
        List<Space__c> spaceList;
        
        if(propertyId != null){
            spaceList = [SELECT Id, Name, RentableArea__c, toLabel(Type__c) TypeLabel, Type__c, Status__c, Property__c, MainFloor__c, CurrencyIsoCode, //NEEL 10.07.2018
                         LatestBudget__c, LatestJVBudget__c, LatestForecast__c, OccupancyStatus__c, RecordTypeId, BillingCategory__c,
                         CurrentRent__c, PreviousRent__c, CurrentSemiGrossRent__c, PreviousSemiGrossRent__c, ReconfiguredCurrentRent__c, CurrentLease__c,ReconfiguredCurrentRentSemiGross__c
                         FROM Space__c 
                         WHERE Property__c =: propertyId
                         AND Status__c !=: Constants.SPACE_STATUS_INACTIVE
                         ORDER BY Name];
        }
        
        return spaceList;
    }
    
    public static Set<String> getOpportunityDealTypeSet() {
        Set<String> opportunityDealTypeSet  = New Set<String>();
        
        Schema.DescribeFieldResult opportunityTypeDescription = Opportunity.DealType__c.getDescribe();
        for (Schema.Picklistentry picklistEntry : opportunityTypeDescription.getPicklistValues()){
            opportunityDealTypeSet.add(pickListEntry.getLabel());
        }
        
        return opportunityDealTypeSet;
    }
    
    public static List<AggregateResult> getOpportunityLineItemAggregate (List<Opportunity> opportunityToAggregateList) {
        List<AggregateResult> opportunityLineItemAggregateList = new List<AggregateResult>();
        
        if(opportunityToAggregateList != null && opportunityToAggregateList.size() > 0) {
            opportunityLineItemAggregateList = [SELECT OpportunityId, SUM(TotalPrice) TotalPrice
                                                FROM OpportunityLineItem 
                                                WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Id IN :opportunityToAggregateList )
                                                AND Product2.Family in (:CONSTANTS.RENT,
                                                                        :CONSTANTS.RECOVERIES_GROSS ,
                                                                        :CONSTANTS.RECOVERIES_NET ,
                                                                        :CONSTANTS.RECOVERIES_SEMI_GROSS ,
                                                                        :CONSTANTS.PROMO_MARKETING)  
                                                GROUP BY OpportunityId];
        }
        
        return opportunityLineItemAggregateList;
    }
    
    public static Map<Id, Opportunity> getOpportunityMap(Set<Id> opportunityIdSet){
        Map<Id, Opportunity> opportunityMap;
        
        opportunityMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, Property__c, RecordTypeId, Space__c, TotalDCCost__c, TotalLessorWorksCost__c, Account_Type__c,
             RecordType.Name, OwnerId, StageName, Pricebook2Id, TotalFitoutContribution__c, SpecialityLeaseType__c,
             AccountId, Type, Account.ParentId, Account.Parent.ParentId, NumberofGuarantors__c, CurrencyIsoCode, Tech_PropertyState__c, 
             TECH_UpdateCostEstimateRequired__c, TECHJVRequired__c, Property__r.DexusProperty__c, Property__r.Id, 
             Space__r.Id, Space__r.Status__c, ApprovalSubmitter__c, Property__r.Tech_ConcatenatedHoldingCompanyName__c, Property__r.HoldingCompaniesName__c,
             NationalAgreement__c, NationalAgreement__r.RentReviewCappedPercent__c, NationalAgreement__r.StandardReviewTypes__c, 
             AnnualMinimumRent__c, Account.PartnershipSegmentation__c, NationalAgreement__r.Account__c, TechByPassOnClone__c,
             NationalAgreement__r.Account__r.PartnershipSegmentation__c, RecordType.DeveloperName, Guarantors__c, Tech_IsCreatedFromGroupRenew__c,RentableArea__c,Group_Renewal_Retail_Admin__c,
             (SELECT Id, LeaseStatus__c FROM Contracts__r)
             FROM Opportunity
             WHERE Id IN: opportunityIdSet]
        );
        
        return opportunityMap;
    }
    
    public static List<Opportunity> getOpportunity (Set<Id> childAccountIdSet) {
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        if(childAccountIdSet != null && childAccountIdSet.size() > 0) {
            opportunityList = [SELECT Id, Account.ParentId
                               FROM Opportunity 
                               WHERE AccountId IN :childAccountIdSet
                               AND (StageName = :CONSTANTS.UNDERSTAND_NEGOTIATE
                                    OR StageName = :CONSTANTS.APPROVE 
                                    OR StageName = :CONSTANTS.PROPOSE_ACCEPT)];
        }
        
        return opportunityList;
    }
    
    //RPP-10989 - START
    public static List<Opportunity> getOpportunities (Set<Id> childAccountIdSet) {
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        if(childAccountIdSet != null && childAccountIdSet.size() > 0) {
            opportunityList = [SELECT Id, Account.ParentId
                               FROM Opportunity 
                               WHERE AccountId IN :childAccountIdSet
                               AND IsClosed = FALSE
                               AND (RecordType.DeveloperName =: Constants.OPP_RETAIL_LEASING_API_NAME
                               OR RecordType.DeveloperName =: Constants.OPP_COMMERCIAL_LEASING_API_NAME)];
        }
        
        return opportunityList;
    }
    //RPP-10989 - END
    
    public static List<Account> getAccountByPrecedentClause (Set<Id> precedentClauseAccountIdSet) {
        List<Account> accountList = new List<Account>();
        
        if(precedentClauseAccountIdSet != null && precedentClauseAccountIdSet.size() > 0) {
            accountList = [SELECT Id, (SELECT Id FROM ChildAccounts) 
                           FROM Account 
                           WHERE Id IN :precedentClauseAccountIdSet];
        }
        
        return accountList;
    }
    
    public static List<Account> getAccount (Set<Id> AccountIdSet, Id recordTypeId) {
        List<Account> accountList = new List<Account>();
        
        if(AccountIdSet != null && AccountIdSet.size() > 0) {
            accountList = [SELECT Id, ParentId, ShippingState
                           FROM Account 
                           WHERE Id IN :AccountIdSet 
                           AND RecordTypeId = :recordTypeId];
        }
        
        return accountList;
    }
    
    public static Set<Id> getOpportunityByAccountIdAndStageName(Set<Id> accountIds) {
        //List<Opportunity> oppos = [Select Id, accountId From Opportunity Where accountId in :accountIds And JDESentStatus__c != ''];
        List<Account> tenantAccounts = [Select Id from Account where Id in :accountIds and TenantNo__c != ''];
        Set<Id> accountIdsDedup = new Set<Id>();
        for (Account acc : tenantAccounts) {
            accountIdsDedup.add(acc.Id);
        }
        return accountIdsDedup;
    }
    
    public static List<OpportunityClause__c> getOpportunityClause (Set<Id> precedentClauseIdSet) {
        List<OpportunityClause__c> opportunityClauseList = new List<OpportunityClause__c>();
        
        if(precedentClauseIdSet != null && precedentClauseIdSet.size() > 0) {
            opportunityClauseList = [SELECT Id, TechPrecedentClauseId__c, 
                                     Name, Type__c, ClauseDetails__c, 
                                     LeasingComment__c, EffectiveToDate__c
                                     FROM OpportunityClause__c 
                                     WHERE TechPrecedentClauseId__c IN :precedentClauseIdSet
                                     AND (Opportunity__r.StageName = :CONSTANTS.UNDERSTAND_NEGOTIATE
                                          OR Opportunity__r.StageName = :CONSTANTS.APPROVE 
                                          OR Opportunity__r.StageName = :CONSTANTS.PROPOSE_ACCEPT)];
        }
        return opportunityClauseList;
    }
    
    public static List<PropertyOwnership__c> getPropertyOwnership (Set<Id> propertyIdSet) {
        List<PropertyOwnership__c> propertyOwnershipList = new List<PropertyOwnership__c>();
        
        if(propertyIdSet != null && propertyIdSet.size() > 0) {
            propertyOwnershipList = [SELECT Id, HoldingCompanyName__c, 
                                     Account__r.ACN__c, Property__c, 
                                     Account__r.Name, Type__c
                                     FROM PropertyOwnership__c 
                                     WHERE Property__c IN :propertyIdSet 
                                     AND Active__c = true];
        }
        
        return propertyOwnershipList;
    }
    
    public static Map<Id, SpaceBudgetAndForecast__c> getSpaceBudget(Set<Id> spaceBudgetIdSet){
        Map<Id, SpaceBudgetAndForecast__c> spaceBudgetMap = new Map<Id, SpaceBudgetAndForecast__c>();
        
        if(spaceBudgetIdSet != null && spaceBudgetIdSet.size() > 0){
            spaceBudgetMap.putAll([SELECT Id, Name, ModelType__c, BudgetedDealType__c,CurrencyIsoCode,   //CurrencyIsoCode added for 10759 
                                        AnnualisedRentDecSemiGross__c, AnnualisedRentDecNet__c,
                                        AnnualisedRentJanSemiGross__c, AnnualisedRentJanNet__c, EffectiveDate__c,
                                        AnnualisedPVRentSemiGross__c, AnnualisedPVRentNet__c, AnnualisedPVRentGross__c,
                                        PromotionalAllowance__c, CapitalSiteEstablishment__c, AnnualisedRentJanGross__c, AnnualisedRentDecGross__c
                                    FROM SpaceBudgetAndForecast__c
                                    WHERE Id IN: spaceBudgetIdSet]
            );
        }
        
        return spaceBudgetMap;
    }
    
    public static Map<Id,Space__c> getSpaceRecords(Set<Id> spacerecordIds){
        Map<Id,Space__c> spaceRecordmap = new Map<Id,Space__c>(
            [SELECT Id, HeldVacantSpace__c, CurrentLeaseExpiryDate__c, Status__c, RentableArea__c, OccupancyStatus__c, 
                LatestAchievedOpportunity__c, LatestAchievedOpportunity__r.Type, LatestForecast__c, 
                LatestAchievedOpportunity__r.CurrentLeaseVirtualVacancy__c, 
                LatestAchievedOpportunity__r.ForecastCapitalCashIncentive__c, 
                LatestAchievedOpportunity__r.ForecastCapitalLessorWorks__c, 
                LatestAchievedOpportunity__r.ForecastCapitalDesignConstruction__c, 
                Property__r.CurrencyISOCode,Property__r.Country__c,
                CurrentForecastedOpportunity__r.CurrentLeaseVirtualVacancy__c, LatestBudget__r.PromotionalAllowance__c, 
                LatestForecast__r.CapitalSiteEstablishment__c, CurrentLease__r.LeaseStartDate__c, CurrentLease__r.Opportunity__c,
             	Relationship__c
             FROM Space__c 
             WHERE Id IN: spacerecordIds 
             ORDER BY Property__c]
        );
        
        return spaceRecordmap;
    }
    
    public static Id getProduct(String productName) {
        Product2 productRecord = new Product2();
        
        if(String.isNotBlank(productName)) {
            productRecord = [SELECT Id 
                             FROM Product2 
                             WHERE Name = :productName
                             AND IsActive = true
                             AND Product2.DealType__c !=null
                             AND Product2.SpaceBillingCategory__c !=null
                             AND Product2.SpaceType__c !=null
                             LIMIT 1];
        }
        
        return productRecord.Id;
    }
    
    public static Map<Id, PriceBookEntry> getPriceBookEntry(Set<Id> priceBookIdSet, String entryName) {
        Map<Id, PriceBookEntry> priceBookEntryMap = new Map<Id, PriceBookEntry>();
        
        if(priceBookIdSet != null && priceBookIdSet.size() > 0 && String.isNotBlank(entryName)) {
            for(PriceBookEntry priceBookEntryRec : [SELECT Id, Pricebook2Id, Name, Product2Id 
                                                    FROM PriceBookEntry 
                                                    WHERE Pricebook2Id IN :priceBookIdSet 
                                                    AND Name = :entryName]) {
                                                        priceBookEntryMap.put(priceBookEntryRec.Pricebook2Id, priceBookEntryRec);
                                                    }
        }
        
        return priceBookEntryMap;
    }

    public static Map<Id, TaskTemplateAndCondition__c> getTaskTemplate(String objectType,  
        Set<String> businessUnitSet, Set<String> leaseTypeSet, Set<String> specialityLeaseTypeSet){
        String leaseType = '';
        Map<Id, TaskTemplateAndCondition__c> taskTemplateMap;

        for(String lease : leaseTypeSet){
            leaseType += lease + Constants.COMMA_NO_SPACE;
        }

        leaseType = leaseType.removeEnd(Constants.COMMA_NO_SPACE);
        
        system.debug('GET TASK TEMPLATE - OPPORTUNITY');
        
        if(String.isNotBlank(objectType)){
            system.debug('QUERYPARAM'+objectType+' '+businessUnitSet+' '+specialityLeaseTypeSet+' '+leaseType);
            taskTemplateMap = new Map<Id, TaskTemplateAndCondition__c>(
                [SELECT Id, AssignTo__c, DueDate__c, Object__c, OpportunityStage__c, TaskDescription__c, TaskName__c, 
                    CaseRecordType__c, TaskType__c, AssigneesTeam__c, BusinessUnit__c, LeaseType__c,SpecialtyLeaseType__c, 
                    JVApproval__c, AccountTeamRole__c, ApplicableCountry__c, Applicable_States__c, IsStageChange__c, ProjectTeamRole__c, SkipWeekends__c, GroupRenewalRole__c
                 FROM TaskTemplateAndCondition__c 
                 WHERE Object__c =: objectType
                    AND IsActive__c = TRUE
                    AND BusinessUnit__c IN: businessUnitSet
                    AND SpecialtyLeaseType__c IN : specialityLeaseTypeSet
                    AND LeaseType__c INCLUDES (:leaseType)]
            );
        }

        return taskTemplateMap;
    }
    
    public static Map<Id, TaskTemplateAndCondition__c> getChildTaskTemplate(String objectType, Set<Id> parentTemplateIdSet){
    //public static Map<Id, TaskTemplateAndCondition__c> getChildTaskTemplate(String objectType, Set<String> parentTaskTypeSet){        
        Map<Id, TaskTemplateAndCondition__c> taskTemplateMap;
        
        if(String.isNotBlank(objectType) && parentTemplateIdSet != null && parentTemplateIdSet.size() > 0){
            taskTemplateMap = new Map<Id, TaskTemplateAndCondition__c>(
                [SELECT Id, AssignTo__c, DueDate__c, Object__c, OpportunityStage__c, TaskDescription__c, TaskName__c,
                 DependentTask__c, TaskType__c, AssigneesTeam__c, DependentTask__r.TaskName__c, AccountTeamRole__c,
                 DependentTask__r.TaskType__c, BusinessUnit__c, LeaseType__c, JVApproval__c, ApplicableCountry__c,
                 IsStageChange__c, SpecialtyLeaseType__c, ProjectTeamRole__c, Applicable_States__c, SkipWeekends__c, GroupRenewalRole__c
                 FROM TaskTemplateAndCondition__c 
                 WHERE Object__c =: objectType
                 AND DependentTask__c IN: parentTemplateIdSet
                 AND IsActive__c = TRUE]
            );
        }
        
        return taskTemplateMap;
    }
    
    public static List<PropertyTeam__c> getPropertyTeam(Set<Id> propertyIdSet){
        List<PropertyTeam__c> propertyTeamList;
        
        propertyTeamList = [SELECT TeamMember__c, Role__c, Property__c, TeamMember__r.Name
                            FROM PropertyTeam__c 
                            WHERE Property__c IN: propertyIdSet
                            AND TeamMember__r.IsActive = TRUE
                            AND Active__c = TRUE];
        
        return propertyTeamList;
    }
    
    public static List<OpportunityLineItem> getOpportunityLineItem(Id opportunityId, Id productId) {
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        
        if(opportunityId != null && productId != null) {
            opportunityLineItemList = [SELECT Id, CPIType__c, StandardReviewType__c, ReviewType__c,//here
                                       EffectiveFromDate__c , EffectiveToDate__c,
                                       PricebookEntryId, Product2Id, RentReviewAmount__c
                                       FROM OpportunityLineItem 
                                       WHERE OpportunityId = :opportunityId 
                                       AND Product2Id = :productId
                                       ORDER BY EffectiveFromDate__c];
        }
        
        return opportunityLineItemList;
    }
    
    public static List<OpportunityLineItem> getFlexiOppLineItems(Set<Id> opportunityIdSet, Set<Id> productIdSet) {
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        if((opportunityIdSet != null && opportunityIdSet.size() > 0) && (productIdSet != null && productIdSet.size() > 0)){
            opportunityLineItemList = [SELECT Id, OpportunityId, Product2Id, ProductFamily__c, CPIType__c
                                       FROM OpportunityLineItem 
                                       WHERE OpportunityId IN :opportunityIdSet
                                       AND Product2Id IN :productIdSet
                                       AND Flexi_Rent__c = false
                                       ORDER BY EffectiveFromDate__c];
        }
        return opportunityLineItemList;
    }
    
    public static List<OpportunityTeamMember> getOpportunityTeamMember(Set<Id> opportunityIdSet){
        List<OpportunityTeamMember> opportunityTeamMemberList;
        
        if(opportunityIdSet != null){
            opportunityTeamMemberList = [SELECT Id, Name, OpportunityId, TeamMemberRole, UserId
                                         FROM OpportunityTeamMember
                                         WHERE OpportunityId IN: opportunityIdSet
                                         AND User.IsActive = TRUE];
        }
        
        return opportunityTeamMemberList;
    }
    
    public static Map<Id, List<OpportunityLineItem>> getOpportunityLineItem(Set<Id> opportunityIdSet){
        Map<Id, List<OpportunityLineItem>> oppoIdOpportunityLineItemMap = new Map<Id, List<OpportunityLineItem>>();
        
        if(opportunityIdSet != null && opportunityIdSet.size() > 0){
            for(OpportunityLineItem oppLineItem : [SELECT Id, Name, OpportunityId, ProductCode, EffectiveFromDate__c,
                                                   Product2.Name, CappedPercent__c, StandardReviewType__c,
                                                   Product2.OutgoingsCategory__c,
                                                   Product2.Family
                                                   FROM OpportunityLineItem 
                                                   WHERE OpportunityId IN: opportunityIdSet
                                                   ORDER BY EffectiveFromDate__c]){
                                                       if(oppoIdOpportunityLineItemMap.containsKey(oppLineItem.OpportunityId)){
                                                           oppoIdOpportunityLineItemMap.get(oppLineItem.OpportunityId).add(oppLineItem);
                                                       } else {
                                                           oppoIdOpportunityLineItemMap.put(oppLineItem.OpportunityId, new List<OpportunityLineItem>{oppLineItem});
                                                       }
                                                   }
        }
        
        return oppoIdOpportunityLineItemMap;
    }
    
    public static Map<Id, List<Opportunity>> getActiveOpportunityPerSpace(Set<Id> spaceIdSet){
        Map<Id, List<Opportunity>> spaceIdOpportunityListMap = new Map<Id, List<Opportunity>>();
        
        if(spaceIdSet != null && spaceIdSet.size() > 0){
            for(Opportunity opp : [SELECT Id, Name, BestBet__c, Space__c 
                                   FROM Opportunity 
                                   WHERE Space__c IN: spaceIdSet
                                   AND IsClosed = FALSE AND BestBet__c = True
                                   ORDER BY BestBet__c DESC]){
                if(spaceIdOpportunityListMap.containsKey(opp.Space__c)){
                    spaceIdOpportunityListMap.get(opp.Space__c).add(opp);
                } else {
                    spaceIdOpportunityListMap.put(opp.Space__c, new List<Opportunity>{opp});
                }
            }
        }
        
        return spaceIdOpportunityListMap;
    }
    
    public static List<OpportunityLineItem> getOpportunityLineItem(String productFamily, Id pricebookId, Id opportunityId){
        List<OpportunityLineItem> oppLineItemList;
        
        oppLineItemList = [SELECT Id, Name, Product2.Name, ListPrice, UnitPrice, TotalPrice, PriceBookEntryId,
                           Opportunity.DealType__c,Opportunity.Space__r.BillingCategory__c,Opportunity.Space__r.Type__c,
                           Opportunity.CurrencyIsoCode
                           FROM OpportunityLineItem 
                           WHERE OpportunityId =: opportunityId
                           //AND IsActive__c = TRUE
                           //AND Product2.IsActive = TRUE 
                           AND Product2.Family =: productFamily
                           AND PriceBookEntry.Pricebook2Id =: pricebookId];
        
        return oppLineItemList;
    }
    
    public static List<PricebookEntry> getPricebookEntry(String productFamily, Id pricebookId){
        List<PricebookEntry> pricebookEntryList;
        
        pricebookEntryList = [SELECT Id, Product2.DefaultPrice__c, Product2Id, Product2.Name, UnitPrice,
                              Product2.CapitalCategory__c,CurrencyIsoCode,Product2.DealType__c,
                              Product2.SpaceBillingCategory__c,Product2.SpaceType__c
                              FROM PricebookEntry 
                              WHERE Product2.IsActive = TRUE
                              AND Product2.DealType__c !=null
                              AND Product2.SpaceBillingCategory__c !=null
                              AND Product2.SpaceType__c !=null
                              AND Product2.Family =: productFamily
                              AND Pricebook2Id =: pricebookId];
        System.debug(' Return PB List: '+ pricebookEntryList);                  
        return pricebookEntryList;
    }
    public static List<Opportunity> getOpportunity(id oppId){
        List<Opportunity> templateList;
        
        templateList = [SELECT ID, Name, Tech_GenerateOfferLetter__c,
                        Tech_GenerateAcceptanceWithModification__c,
                        Tech_GenerateTenancyInstruction__c, AccountId, 
                        NumberofGuarantors__c, TotalOutgoings__c, 
                        TotalPromotionLevy__c, Pricebook2Id
                        FROM Opportunity 
                        WHERE Id= :oppId];
        
        return templateList;
    }
    
    public static Profile getProfile(Id profileId){
        return [SELECT Id, Name FROM Profile WHERE Id =: profileId];
    }
    
    public static List<ContentDocumentLink> getContentDocumentLink(Set<Id> linkedEntityIdSet){
        return [SELECT Id, ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN: linkedEntityIdSet];
    }
    
    public static List<ContentDocumentLink> getContentDocumentLink(Set<Id> cdIdSet,Set<Id> linkedEntityIdSet){
        return [SELECT Id, ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN: linkedEntityIdSet AND ContentDocumentId IN: cdIdSet];
    }
    
    public static List<ContentVersion> getContentVersion(Set<Id> documentIdSet){
        return [Select Id, Title, DocumentCategory__c, DocumentType__c, LastModifiedDate, ContentModifiedDate, VersionNumber, 
                IsLatest, Owner.Name, ContentDocumentId, FileExtension, FinalVersion__c 
                FROM ContentVersion 
                WHERE ContentDocumentId IN: documentIdSet AND IsLatest=true ORDER BY FinalVersion__c DESC, LastModifiedDate DESC];
    }
    
    public static Task getTask(Id taskId) {
        Task taskRec = new Task();
        
        if(taskId != null) {
            taskRec = [SELECT Id, Status
                       FROM Task 
                       WHERE Id = :taskId];
        }
        return taskRec;
    }
    
    public static List<Task> getTasks(Set<Id> oppIdSet) {
        List<Task> taskList = new List<Task>();
        
        if(oppIdSet != null && oppIdSet.size() > 0) {
            taskList = [SELECT Id, WhoId, WhoCount, Subject, 
                        ActivityDate, CreatedById, CreatedBy.Name, 
                        Who.Name, Status,OwnerId,Owner.Name, TaskType__c, WhatId
                        FROM Task 
                        WHERE WhatId IN :oppIdSet
                        AND (Status = :Constants.OPEN OR Status = :Constants.COMPLETED)];
        }
        return taskList;
    }
    
    public static Map<Id, TaskTemplateAndCondition__c> getTaskTemplateByStage(String businessUnit){
        Map<Id, TaskTemplateAndCondition__c> taskTemplateMap;
        
        if(String.isNotEmpty(businessUnit)){
            taskTemplateMap = new Map<Id, TaskTemplateAndCondition__c>(
                [SELECT Id, AssignTo__c, DueDate__c, Object__c, OpportunityStage__c, TaskDescription__c, TaskName__c,
                 TaskType__c, AssigneesTeam__c, BusinessUnit__c, LeaseType__c, JVApproval__c,CaseRecordType__c,AccountTeamRole__c, SkipWeekends__c, GroupRenewalRole__c
                 FROM TaskTemplateAndCondition__c 
                 WHERE IsActive__c = TRUE
                 AND BusinessUnit__c = :businessUnit]
            );
        }
        
        return taskTemplateMap;
    }
    
    public static Map<Id, TaskTemplateAndCondition__c> getTaskTemplateByBusUnit(String businessUnit){
        Map<Id, TaskTemplateAndCondition__c> taskTemplateMap;
        
        if(String.isNotBlank(businessUnit)){
            taskTemplateMap = new Map<Id, TaskTemplateAndCondition__c>(
                [SELECT Id, AssignTo__c, DueDate__c, Object__c, OpportunityStage__c, TaskDescription__c, TaskName__c,
                 TaskType__c, AssigneesTeam__c, BusinessUnit__c,CaseRecordType__c,AccountTeamRole__c, SkipWeekends__c,
                 GroupRenewalRole__c
                 FROM TaskTemplateAndCondition__c 
                 WHERE IsActive__c = TRUE
                 AND BusinessUnit__c = :businessUnit]
            );
        }
        
        return taskTemplateMap;
    }
    
    public static List<TaskTemplateAndCondition__c> getTaskTemplate(String objectType){
        return [SELECT Id, AssignTo__c, DueDate__c, Object__c,TaskDescription__c, TaskName__c,CaseRecordType__c,
                TaskType__c, AssigneesTeam__c,AccountTeamRole__c, BusinessUnit__c,ApplicableCountry__c, SkipWeekends__c, GroupRenewalRole__c
                FROM TaskTemplateAndCondition__c
                WHERE Object__c =: objectType];
    }
    
    public static List<SpaceGroup__c> getSpaceGroupOfChildSpace(Set<Id> childSpaceIdSet){
        return [SELECT Id, ChildSpace__c, ChildSpace__r.ReadyToForecast__c, SpaceGroupNumber__c , EffectiveDate__c
                FROM SpaceGroup__c 
                WHERE ChildSpace__c IN: childSpaceIdSet];
    }
    
    public static List<SpaceGroup__c> getSpaceGroupBySpaceGroupNumber(Set<Decimal> spaceGroupNumberSet){
        return [SELECT Id, SpaceGroupNumber__c, EffectiveDate__c, ChildSpace__c , ChildSpace__r.ReadyToForecast__c, ChildSpace__r.Type__c,
                ChildSpace__r.RentableArea__c, ChildSpace__r.ReconfiguredCurrentRent__c, ChildSpace__r.ReconfiguredCurrentRentSemiGross__c, ParentSpace__c, ParentSpace__r.Type__c, 
                ParentSpace__r.CurrentLease__c, ParentSpace__r.CurrentRent__c, ParentSpace__r.CurrentSemiGrossRent__c, ParentSpace__r.ReconfiguredCurrentRent__c, ParentSpace__r.ReconfiguredCurrentRentSemiGross__c,
                ParentSpace__r.RentableArea__c, ParentSpace__r.PreviousRent__c, ParentSpace__r.PreviousSemiGrossRent__c, ParentSpace__r.PreviousLease__c,
                ChildSpace__r.PreviousLease__c
                FROM SpaceGroup__c 
                WHERE SpaceGroupNumber__c IN :spaceGroupNumberSet];
    }
    
    public static Map<String, Map<String, String>> getApprovalMatrixMetadata(){
        Map<String, Map<String, String>> approvalMatrixMap = new Map<String, Map<String, String>>();
        
        for(CaseApprovalMatrix__mdt appMatrix : [SELECT ApproverRole__c, FieldAPIName__c, Type__c
                                                 FROM CaseApprovalMatrix__mdt]){
                                                     if(approvalMatrixMap.containsKey(appMatrix.Type__c)){
                                                         approvalMatrixMap.get(appMatrix.Type__c).put(appMatrix.ApproverRole__c, appMatrix.FieldAPIName__c);
                                                     } else {
                                                         approvalMatrixMap.put(appMatrix.Type__c, new Map<String, String>{
                                                             appMatrix.ApproverRole__c => appMatrix.FieldAPIName__c
                                                                 });
                                                     }
                                                 }
        
        return approvalMatrixMap;
    }
    
    public static Map<Id, Map<String, PropertyTeam__c>> getPropertyTeamByProperty(Set<Id> propertyIdSet){
        Map<Id, Map<String, PropertyTeam__c>> propertyTeamByPropertyMap = new Map<Id, Map<String, PropertyTeam__c>>(); 
        
        for(PropertyTeam__c propTeam : DatabaseSOQLBank.getPropertyTeam(propertyIdSet)){
            if(propertyTeamByPropertyMap.containsKey(propTeam.Property__c)){
                propertyTeamByPropertyMap.get(propTeam.Property__c).put(propTeam.Role__c, propTeam);
            } else {
                propertyTeamByPropertyMap.put(propTeam.Property__c, new Map<String, PropertyTeam__c>{
                    propTeam.Role__c => propTeam
                        });
            }
        }
        
        return propertyTeamByPropertyMap;
    }
    
    public static List<PriceBookEntry> getPriceBookEntry(Set<Id> priceBookIdSet) {
        List<PriceBookEntry> priceBookEntryList = new List<PriceBookEntry>();
        
        if(priceBookIdSet != null && priceBookIdSet.size() > 0) {
            priceBookEntryList = [SELECT Id, Pricebook2Id, Name, Product2Id 
                                  FROM PriceBookEntry 
                                  WHERE Pricebook2Id IN :priceBookIdSet];
        }
        return priceBookEntryList;
    }
    
    public static List<OpportunityLineItem> getReviewRecord(Set<Id> opportunityIdSet) {
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        
        if(opportunityIdSet != null && opportunityIdSet.size() > 0) {
            opportunityLineItemList = [SELECT Id, CPIType__c, StandardReviewType__c, ReviewType__c,//here
                                       EffectiveFromDate__c , EffectiveToDate__c, Description, 
                                       PricebookEntryId, Product2Id, RentReviewAmount__c
                                       FROM OpportunityLineItem 
                                       WHERE OpportunityId IN :opportunityIdSet
                                       ORDER BY EffectiveFromDate__c];
        }
        return opportunityLineItemList;
    }
    
    public static Map<Id, Map<String, AccountTeamMember>> getAccountTeamPerAccount(Set<Id> accountIdSet){
        Map<Id, Map<String, AccountTeamMember>> accIdAccountTeamMap = new Map<Id, Map<String, AccountTeamMember>>();
        
        for(AccountTeamMember accMember : [SELECT Id, TeamMemberRole, UserId, AccountId
                                           FROM AccountTeamMember 
                                           WHERE AccountId IN: accountIdSet 
                                           AND TeamMemberRole =: Constants.TEAM_ROLE_RDAM 
                                           AND Account.RecordType.Name =: Constants.GROUP_LEVEL]){
                                               
                                               if(accIdAccountTeamMap.containsKey(accMember.AccountId)){
                                                   accIdAccountTeamMap.get(accMember.AccountId).put(accMember.TeamMemberRole, accMember);
                                               } else {
                                                   accIdAccountTeamMap.put(accMember.AccountId, new Map<String, AccountTeamMember>{
                                                       accMember.TeamMemberRole => accMember
                                                           });
                                               }
                                           } 
        
        return accIdAccountTeamMap;
    }
    
    public static List<SpaceProduct__c> getSpaceProduct(Set<String> outgoingCategorySet, Set<Id> sourceSpaceIdSet){
        return [SELECT Id, Name, Product__r.OutgoingsCategory__c, Product__r.Name, Description__c, CalculationMethod__c,
                EffectiveFromDate__c, EffectiveToDate__c, Percentage__c, Product__c, ProductFamily__c, Active__c,CurrencyIsoCode,   //CurrencyIsoCode added for 10759
                SalesPrice__c
                FROM SpaceProduct__c 
                WHERE Product__r.OutgoingsCategory__c IN: outgoingCategorySet
                AND Space__c IN: sourceSpaceIdSet AND CalculationMethod__c != 'Fixed'
                ORDER BY Percentage__c DESC, SalesPrice__c DESC];
    }
    
    public static List<SpaceProduct__c> getFixedSpaceProduct(Set<String> outgoingCategorySet, Set<Id> sourceSpaceIdSet){
        return [SELECT Id, Name, Product__r.OutgoingsCategory__c, Product__r.Name, Description__c, CalculationMethod__c,CurrencyIsoCode,   //CurrencyIsoCode added for 10759
                EffectiveFromDate__c, EffectiveToDate__c, Percentage__c, Product__c, ProductFamily__c, Active__c,
                SalesPrice__c
                FROM SpaceProduct__c 
                WHERE Product__r.OutgoingsCategory__c IN: outgoingCategorySet
                AND Space__c IN: sourceSpaceIdSet AND CalculationMethod__c = 'Fixed' AND Active__c = True
                ORDER BY Percentage__c DESC, SalesPrice__c DESC];
    }
    
    public static Map<Id, Account> getAccountById(Set<Id> accountIdSet){
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, ParentId, Parent.ParentId, RentApprovalTolerance__c, CapitalApprovalTolerance__c,
             CapitalApprovalToleranceCurrency__c,Category__c,SuperfineCategory__c,
             ShippingCountry,ShippingState,BillingCountry,BillingState,RecordTypeId,RecordType.DeveloperName
             FROM Account 
             WHERE Id IN: accountIdSet]
        );
        
        return accountMap;
    }
    
    public static Map<Id, List <Affiliation__c>> getAffiliationMap(Set<Id> accountIdSet) {
        Map<Id, List <Affiliation__c>> affiliationMap = new Map<Id, List <Affiliation__c>>();
        
        if(accountIdSet != null && accountIdSet.size() > 0) {
            for(Affiliation__c affRec :[SELECT Id, Type__c, Contact__r.Name, Account__c, 
                                        Contact__r.MailingAddress, PrimaryAffiliationAccount__r.ShippingAddress, Status__c,
                                        Contact__c, PrimaryAffiliationAccount__c, PrimaryAffiliationAccount__r.TradingName__c
                                        FROM Affiliation__c 
                                        WHERE Account__c IN :accountIdSet]) {
                                            if(affiliationMap.containsKey(affRec.Account__c)) {
                                                affiliationMap.get(affRec.Account__c).add(affRec);
                                            } else {
                                                affiliationMap.put(affRec.Account__c, new List<Affiliation__c> {affRec});
                                            }
                                        }
        }
        
        return affiliationMap;
    }
    
    public static Map<Id, List<OpportunityContactRole>> getOppConRolesMap(Set<Id> oppIdSet) {
        Map<Id, List<OpportunityContactRole>> oppConRoleMap= new Map<Id, List<OpportunityContactRole>>();
        if(oppIdSet != null && oppIdSet.size() > 0) {
            for(OpportunityContactRole oppConRoleRec : [SELECT Id, OpportunityId, ContactId
                                                        FROM OpportunityContactRole 
                                                        WHERE OpportunityId IN :oppIdSet]) {
                                                            if(oppConRoleMap.containsKey(oppConRoleRec.OpportunityId)) {
                                                                oppConRoleMap.get(oppConRoleRec.OpportunityId).add(oppConRoleRec);
                                                            } else {
                                                                oppConRoleMap.put(oppConRoleRec.OpportunityId, new List<OpportunityContactRole>{oppConRoleRec});
                                                            }
                                                        }
        }
        return oppConRoleMap;
    }
    public static Map<Id, List<OpportunityContactRole>> getOppConRolesMap(Set<Id> oppIdSet, Set<String> rolesSet) {
        Map<Id, List<OpportunityContactRole>> oppConRoleMap= new Map<Id, List<OpportunityContactRole>>();
        if(oppIdSet != null && oppIdSet.size() > 0) {
            for(OpportunityContactRole oppConRoleRec : [SELECT Id, OpportunityId, ContactId, Contact.Name, Role
                                                        FROM OpportunityContactRole 
                                                        WHERE OpportunityId IN :oppIdSet AND Role IN :rolesSet]) {
                                                            if(oppConRoleMap.containsKey(oppConRoleRec.OpportunityId)) {
                                                                oppConRoleMap.get(oppConRoleRec.OpportunityId).add(oppConRoleRec);
                                                            } else {
                                                                oppConRoleMap.put(oppConRoleRec.OpportunityId, new List<OpportunityContactRole>{oppConRoleRec});
                                                            }
                                                        }
        }
        return oppConRoleMap;
    }    
    public static List<ContentVersion> getLeasePlanFile(Set<Id> contentDocumentIdSet){
        return [SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE DocumentType__c =: Constants.LEASE_PLAN 
                AND ContentDocumentId IN: contentDocumentIdSet];
    }
    
    public static Map<Id, List<PropertyOwnership__c>> getJVPropertyOwnerShipByProperty(Set<Id> propertyIdSet){
        Map<Id, List<PropertyOwnership__c>> propIdPropOwnershipListMap = new Map<Id, List<PropertyOwnership__c>>();
        
        for(PropertyOwnership__c propOwner : [SELECT Id, Name, Account__c, Property__c, RentApprovalTolerance__c, CapitalApprovalTolerance__c,
                                              CapitalApprovalToleranceCurrency__c
                                              FROM PropertyOwnership__c
                                              WHERE Type__c =: Constants.JV
                                              AND Property__c IN: propertyIdSet]){
            if(propIdPropOwnershipListMap.containsKey(propOwner.Property__c)){
                propIdPropOwnershipListMap.get(propOwner.Property__c).add(propOwner);
            } else {
                propIdPropOwnershipListMap.put(propOwner.Property__c, new List<PropertyOwnership__c>{propOwner});
            }
        }
        
        return propIdPropOwnershipListMap;
    }
    
    public static Map<Id, Case> getCase(Set<Id> caseIdSet){
        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, Space__c, TechPropertyId__c, Opportunity__c, RecordType.Name, TECHPropertyCountry__c, OwnerId, SubType__c, TECH_RetailAdministratorReviewCompleted__c, Is_Lease_Variation_Required__c
             FROM Case 
             WHERE Id IN: caseIdSet]
        );
        
        return caseMap;
    }
    
    public static Map<Id, List<Opportunity>> getOpportunitiesOfAccount(Set<Id> accountIdSet){
        Map<Id, List<Opportunity>> opportunityMap = new Map<Id, List<Opportunity>>();
        
        for(Opportunity oppRec :[SELECT Id, AccountId, NumberofGuarantors__c
                                 FROM Opportunity
                                 WHERE AccountId IN: accountIdSet 
                                 AND Property__c != null 
                                 AND Space__c != null 
                                 AND StageName != :Constants.OPPTY_STAGENAME_CLOSED]) {
                                    if(opportunityMap.containsKey(oppRec.AccountId)) {
                                        opportunityMap.get(oppRec.AccountId).add(oppRec);
                                    } else {
                                        opportunityMap.put(oppRec.AccountId, new List<Opportunity>{oppRec});
                                    }
        }
        
        return opportunityMap;
    }
    
    public static List<Task> getPrepareCounterOfferTasks(Set<Id> whatIdSet){
        return [SELECT Id, Status, TaskType__c
                FROM Task
                WHERE WhatId IN: whatIdSet
                    AND TaskType__c =: Constants.PREPARE_COUNTER_OFFER_API];
    }
    
    public static Map<Id, List<Space__c>> getSpacesOfProperty(Set<Id> propertyIdSet) {
        Map<Id, List<Space__c>> propertySpaceMap = new Map<Id, List<Space__c>>();
        if(propertyIdSet != null && propertyIdSet.size() > 0) {
            for(Space__c spaceRec :[SELECT Id, Property__c, MainFloor__c, FloorPlanURL__c
                                    FROM Space__c 
                                    WHERE Property__c IN :propertyIdSet]) {
                                        if(propertySpaceMap.containsKey(spaceRec.Property__c)) {
                                            propertySpaceMap.get(spaceRec.Property__c).add(spaceRec);
                                        } else {
                                            propertySpaceMap.put(spaceRec.Property__c, new List<Space__c>{spaceRec});
                                        }
                                    }
        }
        return propertySpaceMap;
    }
    
    public static Map<Id, List<SpaceGroup__c>> getSpaceGroupMap(Set<Id> spaceIdSet) {
        Map<Id, List<SpaceGroup__c>> spaceGroupMap = new Map<Id, List<SpaceGroup__c>>();
        if(spaceIdSet != null && spaceIdSet.size() > 0) {
            for(SpaceGroup__c temp :[SELECT Id, ParentSpace__c, Active__c, Type__c, EffectiveDate__c FROM SpaceGroup__c WHERE ParentSpace__c IN :spaceIdSet]) {
                if(spaceGroupMap.containsKey(temp.ParentSpace__c)) {
                    spaceGroupMap.get(temp.ParentSpace__c).add(temp);
                } else {
                    spaceGroupMap.put(temp.ParentSpace__c, new List<SpaceGroup__c>{temp});
                }
            }
        }
        return spaceGroupMap;
    }
    
    public static Set<String> getForecastFieldSet() {
        Set<String> forecastFieldSet = new Set<String>();
        for(OpportunityForecastField__mdt temp :[SELECT Id, Label FROM OpportunityForecastField__mdt]) {
            forecastFieldSet.add(temp.Label);
        }
        return forecastFieldSet;
    }
    
    public static List<ClauseLibrary__c> getFilteredClauseLibraryList(Set<Id> clauseIdSet) {
        return [SELECT Id, Name, ClauseDetails__c, 
                Type__c, DocumentLocation__c, ApplicableState__c,
                RecordType.DeveloperName
                FROM ClauseLibrary__c 
                WHERE Status__c = :Constants.ACTIVE
                AND Id NOT IN :clauseIdSet
                ORDER BY Name];
    }
    
    public static List<OpportunityClause__c> getOpportunityClauseListForStandardResponse(Set<Id> opportunityIdSet) {
        List<OpportunityClause__c> oppClauseList = new List<OpportunityClause__c>();
        if(opportunityIdSet != null && opportunityIdSet.size() > 0) {
            oppClauseList = [SELECT Id, ReferencedClause__c,
                             RecordType.Name, ClauseDetails__c, Name, 
                             RecordType.DeveloperName, Type__c, 
                             ReferencedClause__r.DocumentLocation__c
                             FROM OpportunityClause__c 
                             WHERE Opportunity__c IN :opportunityIdSet
                             AND RecordType.DeveloperName = :Constants.OC_STANDARD_RESPONSE_CLAUSE
                             ORDER BY Name];
        }
        return oppClauseList;
    }
    
    public static List<Contract__c> getContractByProperty(Set<Id> propertyIdSet){
        Set<String> contractStatusSet = new Set<String>();
        contractStatusSet.addAll(Label.ContractStausforRisk.split(';'));
        
        return [SELECT Id, Name, Opportunity__c, Opportunity__r.Category__c,toLabel(Account__r.Category__c)
                FROM Contract__c 
                WHERE Property__c IN: propertyIdSet
                    AND LeaseStatus__c IN : contractStatusSet];
    }
    
    public static List<OpportunityClause__c> getHighRiskOppClause(Set<Id> oppoIdSet, Set<String> accCategorySet){
        return [SELECT Id, Name,Type__c, Opportunity__c, Opportunity__r.Property__c, Opportunity__r.Space__c,
                Opportunity__r.Space__r.Name, Opportunity__r.Account.Id, Opportunity__r.Account.Name, 
                Opportunity__r.Property__r.Name, Opportunity__r.Category__c, ReferencedClause__r.HighRiskClause__c,
                ReferencedClause__r.RiskApplies__c, ReasonRecommendation__c, Approved__c,
                Opportunity__r.Account.Category__c//, EffectiveToDate__c
                FROM OpportunityClause__c 
                WHERE Opportunity__c IN: oppoIdSet 
                    AND Opportunity__r.Account.Category__c IN: accCategorySet 
                    AND (ReferencedClause__r.HighRiskClause__c = true)];
    }
    
    public static List<GST__mdt> getGST() {
        return [SELECT GSTAmount__c, DeveloperName FROM GST__mdt];
    }
    
    public static List<OpportunityContactRole> getOppContactRoleListByAccount(Set<Id> accountIdSet) {
        List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
        if(accountIdSet != null && accountIdSet.size() > 0) {
            oppContactRoleList = [SELECT Id, ContactId, Opportunity.AccountId, OpportunityId
                                  FROM OpportunityContactRole 
                                  WHERE Opportunity.AccountId IN :accountIdSet];
        }
        return oppContactRoleList;
    }
    
    public static Map<String, List<ClauseLibrary__c>> getHighRiskClauseLibraryBySubType(){
        Map<String, List<ClauseLibrary__c>> subTypeClauseLibraryListMap = new Map<String, List<ClauseLibrary__c>>();
        
        for(ClauseLibrary__c cLibrary : [SELECT Id, Name, Type__c, SubType__c, ClauseDetails__c, RiskApplies__c, ReasonRecommendation__c
                                         FROM ClauseLibrary__c 
                                         WHERE Status__c = :Constants.ACTIVE AND RecordType.DeveloperName='CLA_RetailClauses'
                                            AND (HighRiskClause__c = TRUE
                                                OR RiskApplies__c = TRUE)]){
            if(subTypeClauseLibraryListMap.containsKey(cLibrary.SubType__c)){
                subTypeClauseLibraryListMap.get(cLibrary.SubType__c).add(cLibrary);
            } else {
                subTypeClauseLibraryListMap.put(cLibrary.SubType__c, new List<ClauseLibrary__c>{cLibrary});
            }
        }
        
        return subTypeClauseLibraryListMap;
    }
    
    public static Map<String, List<ClauseLibrary__c>> getHighRiskClauseLibraryBySubType(Set<String> subTypeSet){
        Map<String, List<ClauseLibrary__c>> subTypeClauseLibraryListMap = new Map<String, List<ClauseLibrary__c>>();
        
        for(ClauseLibrary__c cLibrary : [SELECT Id, Name, Type__c, SubType__c, ClauseDetails__c, RiskApplies__c, ReasonRecommendation__c
                                         FROM ClauseLibrary__c 
                                         WHERE Status__c = :Constants.ACTIVE 
                                            AND SubType__c IN: subTypeSet
                                            AND (HighRiskClause__c = TRUE
                                                OR RiskApplies__c = TRUE)]){
            if(subTypeClauseLibraryListMap.containsKey(cLibrary.SubType__c)){
                subTypeClauseLibraryListMap.get(cLibrary.SubType__c).add(cLibrary);
            } else {
                subTypeClauseLibraryListMap.put(cLibrary.SubType__c, new List<ClauseLibrary__c>{cLibrary});
            }
        }
        
        return subTypeClauseLibraryListMap;
    }
    
    public static Map<Id, List<OpportunityClause__c>> getHightRiskOpportunityClause(Set<Id> opportunityIdSet){
        Map<Id, List<OpportunityClause__c>> oppIdOppClauseMap = new Map<Id, List<OpportunityClause__c>>();
        
        for(OpportunityClause__c oppClause : [SELECT Id, Name, ReferencedClause__c,SubType__c, ReferencedClause__r.SubType__c,
                                              Opportunity__c, IsAutomated__c
                                              FROM OpportunityClause__c
                                              WHERE Opportunity__c IN: opportunityIdSet
                                                AND (ReferencedClause__r.HighRiskClause__c = TRUE
                                                    OR ReferencedClause__r.RiskApplies__c = TRUE)]){
            if(oppIdOppClauseMap.containsKey(oppClause.Opportunity__c)){
                oppIdOppClauseMap.get(oppClause.Opportunity__c).add(oppClause);
                
            } else {
                oppIdOppClauseMap.put(oppClause.Opportunity__c, new List<OpportunityClause__c>{oppClause});
            }
        }
        
        return oppIdOppClauseMap;
    }
    
    public static List<OpportunityRCA__mdt> getOpportunityRCACMetadata(){
        return [SELECT Id, ClauseSubType__c, Condition__c, ConditionValue__c
                FROM OpportunityRCA__mdt];
    }
    
    //SG 11.26.18
    public static List<Case> getChildCase(Set<Id> parentIdSet){
        return [SELECT Id, ParentId, Status, Approved__c FROM Case WHERE ParentId IN :parentIdSet];
    }
    
    public static List<Opportunity> getOpportunityList(Set<Id> oppIdSet) {
        return [SELECT Id, Name, Property__c,Property__r.Country__c, AnnualMinimumRent__c, NZProperty__c, PromoLevyIncluded__c, DealType__c, 
                    NationalAgreement__r.PromoPercentage__c,NationalAgreement__r.CurrentMinimumThreshold__c,NationalAgreement__r.CurrentMaximumThreshold__c, 
                    NationalAgreement__r.Status__c , DealAchieved__c,Space__c,Space__r.CurrentRent__c,Space__r.ReconfiguredCurrentRent__c,
                    Space__r.CurrentSemiGrossRent__c,Space__r.ReconfiguredCurrentRentSemiGross__c, 
                    AccountId, Account.Name, Account.ParentId, Account.Parent.ParentId, Account.RentApprovalTolerance__c, Account.CapitalApprovalTolerance__c,
                    Account.CapitalApprovalToleranceCurrency__c,Account.Category__c,Account.SuperfineCategory__c,
                    Account.ShippingCountry,Account.ShippingState,Account.BillingCountry,Account.BillingState,Account.RecordTypeId,Account.RecordType.DeveloperName 
                FROM Opportunity 
                WHERE Id IN :oppIdSet];
    }
    
    public static List<Account> getAccountList(String tradingName, String lesseeName) {
        return [SELECT Id FROM Account WHERE TradingName__c = :tradingName AND LesseeName__c != :lesseeName AND RecordType.DeveloperName = :Constants.GROUP_LEVEL_APINAME];
    }
    
  public static List<PricebookEntry> getPricebookOption(String productFamily, Id pricebookId){
        List<PricebookEntry> pricebookEntryList;
        
        pricebookEntryList = [SELECT Id, Product2Id 
                              FROM PricebookEntry 
                              WHERE pricebook2Id=:pricebookId and Product2.Family=:productFamily];
        System.debug(' Return PB List: '+ pricebookEntryList);                  
        return pricebookEntryList;
    }
    
    public static List<OpportunityLineItem> getOptionsLineItem(Id oppId, Id PBEntryId){
        List<OpportunityLineItem> oppLineItemList;
        
        oppLineItemList = [Select id,Product2Id,OptionsTerm__c,Description,ProductName__c
                           from OpportunityLineItem
                           where OpportunityId=:oppId
                           AND PricebookEntryId=:PBEntryId];
        
        return oppLineItemList;
    }
    
    public static List<Lead> getLeadList(Set<String> convertedLeadSet) {
        return [SELECT Id, Company FROM Lead WHERE Id IN :convertedLeadSet];
    }
    
    public static List<Account> getAccountOfLead(Id accountRecTypeId, Set<String> convertedLeadSet) {
        return [SELECT Id, TechConvertedLeadId__c, ParentId, LesseeName__c  FROM Account WHERE RecordTypeId = :accountRecTypeId AND TechConvertedLeadId__c IN :convertedLeadSet];
    }
    
    public static List<OpportunityClause__c> getSelectedClauseOfOpportunity(Id oppId){
        return [SELECT Id, Name,Type__c, Subtype__c,
                             ReferencedClause__r.RiskApplies__c,ReasonRecommendation__c
                             FROM OpportunityClause__c WHERE Opportunity__c = :oppId
                             ORDER BY ReferencedClause__r.RiskApplies__c];
    }
    
    public static Map<Id, PrecedentClause__c> getPrecedentClause(Set<Id> precedentClauseIdSet){
        Map<Id, PrecedentClause__c> preClauseMap = new Map<Id, PrecedentClause__c>(
            [SELECT Id, Name, RequiredSecurityDepositDays__c, RequiredSecurityDepositWeeks__c, RequiredSecurityDepositMonths__c, Account__c,
             Account__r.PartnershipSegmentation__c
             FROM PrecedentClause__c
             WHERE Id IN: precedentClauseIdSet]
        );
        
        return preClauseMap;
    }
    
    public static List<Opportunity> getOpportunityFromSpace(Set<Id> spaceIdSet){
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        opportunityList = [SELECT Id,ForecastedRentTerminationDate__c,Name,Space__c,IsClosed,Space__r.LatestAchievedOpportunity__c
                          FROM Opportunity WHERE DealAchieved__c = false AND IsClosed = false AND (NOT Name LIKE '%Variation%') AND
                          (NOT Name LIKE '%JDE Lease%') AND StageName !=: Constants.OPPTY_STAGENAME_CLOSED
                          AND Space__c IN: spaceIdSet];
        return opportunityList;
    }
    
    public static Opportunity getLatestAchievedOpportunity(Set<Id> opportunityIdSet){
        Opportunity returnedOpportunity;
        
        returnedOpportunity = [SELECT Id,ForecastedRentTerminationDate__c,Name,
                               Space__c,IsClosed,Space__r.LatestAchievedOpportunity__c 
                               FROM Opportunity WHERE Id IN: opportunityIdSet LIMIT 1];
        
        return returnedOpportunity;
    }

    public static List<Opportunity> getForecastOpptyForSpace(Set<Id> spcIds){
        List<Opportunity> forecastOppty = [SELECT Id, Name, Space__c, AccountId, Account.Type 
                                                FROM Opportunity 
                                                WHERE Space__c IN :spcIds 
                                                AND Account.Type =: Constants.FORECAST];
        return forecastOppty;
    }

    public static List<Account> getForecastAccountForProperty(Set<Id> propertyIds){
        List<Account> forecastAccounts = [SELECT Id, Property__c, Property__r.PropertyOwnershipType__c 
                                            FROM Account 
                                            WHERE Property__c IN :propertyIds 
                                            AND Type =: Constants.FORECAST 
                                            AND Property__r.PropertyStatus__c =: Constants.ACTIVE];
        return forecastAccounts;
    }

    public static List<User> getdataMigrationUser(){
        List<User> dataMigrationUser = [SELECT Id FROM User WHERE Name = 'Data Migration' AND Profile.Name =: Constants.SCG_DATA_MIGRATION AND IsActive = TRUE];
        return dataMigrationUser;
    }
    
    //RPP-10771 START
    public static Map<Id, List<Contract__c>> getExpiredContractsPerSpace(Set<Id> spaceIdSet){
		Map<Id, List<Contract__c>> spaceIdContractListMap = new Map<Id, List<Contract__c>>();
        
		if(spaceIdSet != null && spaceIdSet.size() > 0){
            for(Contract__c con :[SELECT Id,LeaseStatus__c,ActualVacateDate__c,LeaseStartDate__c, Space__c
		                          FROM Contract__c WHERE Space__c IN: spaceIdSet AND 
                                  LeaseStatus__c = 'E' AND 
                                  ActualVacateDate__c != null
                                  ORDER BY ActualVacateDate__c DESC]){
                                      if(con.ActualVacateDate__c != con.LeaseStartDate__c){
                                         if(spaceIdContractListMap.containsKey(con.Space__c)){
                                             spaceIdContractListMap.get(con.Space__c).add(con);
                                         }else{
                                             spaceIdContractListMap.put(con.Space__c, new List<Contract__c>());
                                             spaceIdContractListMap.get(con.Space__c).add(con);
                                         }
                                        }
            }   
            
		
        }
               
        return spaceIdContractListMap;
    }
    //RPP-10771 END
    
    public static List<Case> getChildCases(Set<Id> parentCaseIds, List<Copy_Covid_Case_Details__mdt> fieldsToCopyMetadata){
        String fieldsToQuery = ' ';
        
        for(Copy_Covid_Case_Details__mdt fieldToCopy : fieldsToCopyMetadata){
            fieldsToQuery += fieldToCopy.Field_API_Name__c + ', ';
        }
        
        System.debug('fieldsToQuery: '+fieldsToQuery);
        String query = 'SELECT ' + fieldsToQuery + ' ParentId'+ ' FROM Case WHERE ParentId IN :parentCaseIds';
        System.debug('query: '+query);
        
        return (List<Case>) Database.query(query);
    }
    
    public static List<Copy_Covid_Case_Details__mdt> getCopyCovidCaseDetailsMetadata(){
        return [SELECT MasterLabel, DeveloperName, Copy_Every_Time__c, Copy_Only_Once__c, Field_API_Name__c 
                FROM Copy_Covid_Case_Details__mdt];
    }
    
    public static List<Case> parentCovidCaseVsTaskList(Set<Id> covidCaseIds){
        return [SELECT Id, OwnerId, (SELECT Id, Subject 
                            FROM Tasks 
                            WHERE Subject =: Constants.TASK_UPDATE_CHILD_CASES 
                            AND isClosed = false) 
                FROM Case 
                WHERE Id IN: covidCaseIds];
    }
}