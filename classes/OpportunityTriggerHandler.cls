/**
* Class OpportunityTriggerHandler
*
* Trigger Handler for the Opportunity SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public without sharing class OpportunityTriggerHandler extends TriggerHandler implements ITrigger {
    //private Id standardPriceBookId;
    List<OpportunityAuditHistory__c> histories = new List<OpportunityAuditHistory__c>();
    private Id rentReviewId;
    private Map<String, PriceBookEntry> productNameandPricebookEntryMap = new Map<String, PriceBookEntry>();
    private Map<Id, Id> topParentAccountMap  = new Map<Id,Id>();
    private List<Product2> productList    = new List<Product2>();
    private Set<String> opportunityDealTypeSet    = new Set<String>();
    private Map<Id, Space__c> opportunitySpaceMap  = new Map<Id, Space__c>();
    private Map<String, List<Product2>> productMap  = new Map<String, List<Product2>>();
    private Map<Id,Map<Id,PriceBookEntry>> priceBookProductIdMap = new Map<Id,Map<Id,PriceBookEntry>>();
    private List<OpportunityLineItem> opportunityProductList  = new List<OpportunityLineItem>();
    private List<OpportunityClause__c> opportunityClauseList  = new List<OpportunityClause__c>();
    private Map<Id, List<PrecedentClause__c>> accountPrecedentClauseMap    = new Map<Id, List<PrecedentClause__c>>();
    private Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
    private Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
    private Map<String, Schema.RecordTypeInfo> opportunityClauseRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY_CLAUSE_API);
    private Map<String, Schema.RecordTypeInfo> opportunityRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.OPPORTUNITY);
    private List<Id> oppSpaceIdList = new List<Id>();//Start-end MDC RPP-2762 5.16.18
    private Map<Id, PrecedentClause__c> nationalAgreementClauseMap = new Map<Id, PrecedentClause__c>();
    private Map<Id, Property__c> propertyMap = new Map<Id, Property__c>();
    private List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
    private Map<Id, List<OpportunityLineItem>> flexiOpportunityLineItemMap = new Map<Id, List<OpportunityLineItem>>();
    private Set<OpportunityLineItem> opportunityLineItemtoDelete = new Set<OpportunityLineItem>(); // RPP - 10674 - Changed from List to Set
    private List<OpportunityEvent__e> oppoEventsToPublish = new List<OpportunityEvent__e>();
    private Map<Id, List<OpportunityLineItem>> opportunityLineItemMap = new Map<Id, List<OpportunityLineItem>>();
    //private List<OpportunityLineItem> opportunityLineItemtoUpdate = new List<OpportunityLineItem>();
    // START : YN RPP-3275 5.30.18
    private TaskUtility.TaskOwnerWrapper taskOwnerWrap = new TaskUtility.TaskOwnerWrapper();
    private List<Task> newTaskForInsertList = new List<Task>();
    private static Map<String, Schema.RecordTypeInfo> taskRecordTypeMap;
    // END : YN RPP-3275 5.30.18
    Set<Id> opportunityIdSetforLock=new Set<Id>();
    private Set<Id> opptyIdsForSecurityDeposit = new Set<Id>();
    
    private Map<Id, List<OpportunityLineItem>> oppoIdOpportunityLineItemMap;
    private Map<Id, List<Opportunity>> spaceIdOpportunityListMap;
    
    private static Map<Id, Schema.RecordTypeInfo> oppRecordTypeById; // START-END : YN RPP-4310 6.22.18
    private static List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
    
    private List<Space__c> spaceToUpdateList = new List<Space__c>();
    private List<Space__c> spaceToUpdateForVirtualVacancyList = new List<Space__c>(); // LF RPP-10553 6.20.2019
    private List<OpportunityClause__c> clausetoUpdate=new List<OpportunityClause__c>();
    
    private List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>(); // START-END : YN RPP-4948 7.17.2018
    
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    private Map<Id, TaskTemplateAndCondition__c> taskTemplateMap;
    
    // START : KT RPP-4921 7.20.18
    private Map<Id, List <Affiliation__c>> affiliationsMap = new Map<Id, List <Affiliation__c>>();
    private List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
    // END : KT RPP-4921 7.20.18
    
    private Map<Id, Contact> affiliationContactsMap = new Map<Id, Contact>(); // START-END : LF RPP-10238 4.23.2019
    
    // START : KT RPP-5548 8.3.18
    private Map<Id, List<SpaceGroup__c>> spaceGroupMap = new Map<Id, List<SpaceGroup__c>>();
    // END : KT RPP-5548 8.3.18
    
    private Set<Id> jvRequiredIdSet = new Set<Id>();
    
    private Map<Id, List<PropertyOwnership__c>> propIdJVPropOwnershipListMap;
    
    private Map<Id, Map<Id, List<OpportunityClause__c>>> propIdOppIdOppClauseListMap; // START-END : YN RPP-5640 8.10.2018
    
    // START : RPP-6061 Yana Navarro 9.12.2018
    private List<OpportunityClause__c> newOppClauseList = new List<OpportunityClause__c>();
    private List<OpportunityClause__c> oppClauseToDeleteList = new List<OpportunityClause__c>();
    private Map<Id, Space__c> oppSpaceMap = new Map<Id, Space__c>();
    private List<OpportunityRCA__mdt> oppRCAMetadataList = new List<OpportunityRCA__mdt>();
    private Map<String, Set<String>> clauseLibSubTypeToCreateMap = new Map<String, Set<String>>();
    private Map<Id, List<OpportunityClause__c>> highRiskOppClauseListMap = new Map<Id, List<OpportunityClause__c>>();
    private Map<String, List<ClauseLibrary__c>> subTypeClauseLibraryListMap = new Map<String, List<ClauseLibrary__c>>();
    private Map<Id, Map<String, List<OpportunityClause__c>>> oppIdSubTypeOppClauseListMap = new Map<Id, Map<String, List<OpportunityClause__c>>>();
    // END : RPP-6061 Yana Navarro 9.12.2018
    // START : KT 10.12.2018
    private List<Opportunity> chatterPostOppList = new List<Opportunity>();
    // END : KT 10.12.2018
    private Set<String> forecastFieldSet = new Set<String>();
    private List<GST__mdt> GSTList = new List<GST__mdt>();
    
    private Map<Id, PrecedentClause__c> nationalAgreementByIdMap = new Map<Id, PrecedentClause__c>();
    private static Map<Id,PriceBookEntry> priceBookRentRevProdIdMap = new Map<Id,PriceBookEntry>();
    private static Map<Id,PriceBookEntry> priceBookPromoRevProdIdMap = new Map<Id,PriceBookEntry>();
    
    public static Map<Id, Opportunity> opportunityMapById = new Map<Id, Opportunity>();
    
    public static List<Task> opptyReversalTask = new List<Task>();
    public static Map<Id, Double> opptyWithRent = new Map<Id, Double>();
    
    // START : YN RPP-10092 7.23.19
    private List<Opportunity> LockedOpportunityList = new List<Opportunity>();
    private List<Opportunity> opportunityUpdateList = new List<Opportunity>();
    // END : YN RPP-10092 7.23.19
    
    
    private static Map<Id, Id> oppIdVsProcessInstWorkItm = new Map<Id,Id>(); //10677 22-10-2019
    private static Boolean isApprovalPresenceChecked = false; //10677 22-10-2019 - Check if query on Approval Process ran and found any pending approval process or not
    private static Map<String,Set<String>> fieldSetandfieldAPInameOpp = new Map<String,Set<String>>(); //10677 22-10-2019
    List<Profile> ProfileIdsOpp = new List<Profile>(); //10677
    List<ProcessInstance> ProInstance1 = new List<ProcessInstance>(); //10677
    public List<ProcessInstance> ProcessInstRecords = new List<ProcessInstance>(); //10677
    public List<ProcessInstanceStep> PendingApprovalStepRecords = new List<ProcessInstanceStep>(); //10677
    public Map<Id, ProcessInstanceWorkitem> oppIdVsProcessInstanceWorkItem = new Map<Id, ProcessInstanceWorkitem>();
    public Map<Id, List<Task>> oppIdVsTaskList = new Map<Id, List<Task>>();
    public static Boolean bypassApprovalLock = false; //10677
    
    //RPP-10345-start
	public List<Property__c> propertyList = new List<Property__c>();
    public Map<Id,Opportunity> propIdVsOpportunityRecordMap = new Map<Id,Opportunity>();
    public Map<Id,Opportunity> opportunityIdVsOpportunityMap = new Map<Id,Opportunity>();
    //RPP-10345-end
    //public Set<Id> forecastOppSpaceIdSetTemp = new Set<Id>(); //SOQL FIX - 14
    
    public List<Opportunity> opportunityListToBePassed = new List<Opportunity>();
    
    private Set<Id> oppSpaceIdSet = new Set<Id>();  //10771
    private Map<Id, List<Contract__c>> spaceIdContractListMap = new Map<Id, List<Contract__c>>(); //10771
    
    // Constructor
    public OpportunityTriggerHandler()
    {
    }
    
    public void bulkBefore()
    {
        taskRecordTypeMap = RecordTypeUtil.getAllRecordTypesByName(Constants.TASK);
        oppRecordTypeById = RecordTypeUtil.getAllRecordTypesById(Constants.OPPORTUNITY);
        
        Set<Id> opportunityAccountIdSet = new Set<Id>();
        Set<Id> spaceIdSet = new Set<Id>();
        Set<Id> propertyIdSet = new Set<Id>();
        Set<Id> forecastOppSpaceIdSet = new Set<Id>();
        Set<String> oppCategorySet = new Set<String>();
        List<Opportunity> newOpportunityList;
        
        if(Trigger.isInsert || Trigger.isUpdate) {
            newOpportunityList = (List<Opportunity>) Trigger.new;
            for(Opportunity opp : newOpportunityList){
                //forecastOppSpaceIdSetTemp.add(opp.Space__c); //SOQL FIX - 14
                if(opp.Property__c != null){
                    propIdVsOpportunityRecordMap.put(opp.Property__c, opp);
                }
            }
            //RPP-10771 - START
            if(Trigger.isInsert){
                for(Opportunity opp : newOpportunityList){
                    if(opp.Space__c != null){
                        oppSpaceIdSet.add(opp.Space__c);
                    }
                }
                spaceIdContractListMap = DatabaseSOQLBank.getExpiredContractsPerSpace(oppSpaceIdSet);
            }
            //RPP-10771 - END
            
            propertyList = DatabaseSOQLBank.getProperty(propIdVsOpportunityRecordMap.keySet()); //SOQL FIX - 7, //SOQL FIX - 8
            
            for(Property__c prop : propertyList){
                propertyMap.put(prop.Id,prop); //SOQL FIX - 8
                if(propIdVsOpportunityRecordMap.containsKey(prop.Id)){
                    propIdVsOpportunityRecordMap.get(prop.Id).Tech_PropertyState__c = prop.PropertyState__c;
                }
            }
            
            
         	//10677 22-10-2019 START
            Set<Id> oppIds = new Set<Id>();
            
            for(Opportunity opp : (List<Opportunity>) Trigger.new){
                oppIds.add(opp.Id);
            }
            
            fieldSetandfieldAPInameOpp = SchemaDescribeBL.describefieldnamefromFS(Constants.OPPORTUNITY,Constants.OPP_FIELDS_ALLOWED_FOR_EDITS);
            if(FeatureManagement.checkPermission('BypassOpportunityFieldLock')){
            	bypassApprovalLock = true; /*IdVsProfile = new Map<Id, Profile>([SELECT Id, Name 
                                                    FROM Profile 
                                                    WHERE Name = :Constants.SYSTEM_ADMINISTRATOR 
                                                    OR Name = :Constants.SCG_INTEGRATION 
                                                    OR Name = :Constants.SCG_SYS_ADM]);*/
            }
            system.debug('isApprovalPresenceChecked----------'+isApprovalPresenceChecked);
            if(oppIdVsProcessInstWorkItm.isEmpty()
              	&& !isApprovalPresenceChecked){
                isApprovalPresenceChecked = true;
                for(ProcessInstance pr : [SELECT Id, Status, TargetObjectId, (SELECT ActorId, StepStatus FROM StepsAndWorkitems) FROM ProcessInstance WHERE Status = 'Pending' AND TargetObjectId IN :oppIds]){
                    System.debug('ProcessInstance===>>> '+ pr);
                    for(ProcessInstanceHistory pIS : pr.StepsAndWorkitems){
                        System.debug('pIS===>>> '+ pIS);
                        if(pIS.StepStatus == 'Pending')
                            oppIdVsProcessInstWorkItm.put(pr.TargetObjectId, pIS.ActorId);
                        System.debug('oppIdVsProcessInstWorkItm===>>> '+ oppIdVsProcessInstWorkItm);
                    }
                }
            }
            System.debug('oppIdVsProcessInstWorkItm===>>> '+ oppIdVsProcessInstWorkItm);
            System.debug('In bulkbefore for 10677');
            //10677 22-10-2019 END     
            
            if(trigger.isUpdate){ //SOQL FIX - 1
                opportunityMapById = new Map<Id, Opportunity>(DatabaseSOQLBank.getOpportunityList(oppIds));
                accountMap = OpportunityBL.getAccountMap(opportunityMapById); //SOQL FIX - 5
                opptyIdsForSecurityDeposit = OpportunityBL.opptyWithSecurityDepositUpdationRequired((Map<Id,Opportunity>) Trigger.oldMap,(Map<Id,Opportunity>) Trigger.newMap); //SOQL FIX - 2, //SOQL FIX - 4
            }
            
            for(Opportunity opportunityRecord : newOpportunityList) {
                opportunityAccountIdSet.add(opportunityRecord.AccountId);
                
                if(opportunityRecord.Space__c != null){
                    spaceIdSet.add(opportunityRecord.Space__c);
                }
                if(opportunityRecord.Property__c != null){
                    propertyIdSet.add(opportunityRecord.Property__c);
                }
                if(Constants.UNDERSTAND_NEGOTIATE.equalsIgnoreCase(opportunityRecord.StageName)) {
                    forecastOppSpaceIdSet.add(opportunityRecord.Space__c);
                }
                
                oppCategorySet.add(opportunityRecord.Category__c);
            }
            
            //START : KT RPP-3542 6.5.18
            if(Trigger.isInsert
                || !opptyIdsForSecurityDeposit.isEmpty()){ //SOQL FIX - 2, //SOQL FIX - 4
                topParentAccountMap = OpportunityBL.buildTopParentAccountMap(opportunityAccountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId()); //SOQL FIX - 2
                //accountPrecedentClauseMap = OpportunityBL.buildAccountPrecedentClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId()); //SOQL FIX - 3
                //END : KT RPP-3542 6.5.18
                
                //START : KT RPP-4921 7.17.18
                nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId()); //SOQL FIX - 4
            }
            Set<Id> parentAccountIdSet = new Set<Id>();
            try{
                if(accountMap.isEmpty()) accountMap = DatabaseSOQLBank.getAccountById(opportunityAccountIdSet); //SOQL FIX - 5
            } catch(Exception e){
                accountMap = null;
            }
            //END : KT RPP-4921 7.17.18
            
            // START : KT RPP-4921 7.20.18
            try{
                affiliationsMap = DatabaseSOQLBank.getAffiliationMap(opportunityAccountIdSet); //SOQL FIX - 6
            } catch(Exception e) {
                affiliationsMap = null;
            }
            // END : KT RPP-4921 7.20.18
            
            // START : LF RPP-10238 4.23.2019
            for (Id accId : affiliationsMap.keySet()) {
                List<Affiliation__c> affList = affiliationsMap.get(accId);
                for(Affiliation__c aff : affList) {
                    if (!affiliationContactsMap.containsKey(aff.Contact__c)) {
                        affiliationContactsMap.put(aff.Contact__c, aff.Contact__r);
                    }
                }
            }
            // END : LF RPP-10238 4.23.2019
            
            // START : KT RPP-5548 8.3.18
            if(spaceIdSet != null && spaceIdSet.size() > 0) {
                try{
                    spaceGroupMap  = DatabaseSOQLBank.getSpaceGroupMap(spaceIdSet);
                } catch(Exception e) {
                    spaceGroupMap  = null;
                }
            }
            // END : KT RPP-5548 8.3.18
            
            try{
                forecastFieldSet = DatabaseSOQLBank.getForecastFieldSet();
            } catch(Exception e) {
                forecastFieldSet = null;
            }
            try {
                GSTList = DatabaseSOQLBank.getGST();
            } catch(Exception e) {
                GSTList = null;
            }
        }
        
        if(Trigger.isInsert || Trigger.isUpdate) {
            // START : YN RPP-5640 8.10.2018
            Set<Id> contractOppIdSet = new Set<Id>();
            //Set<String> accCategorySet = new Set<String>();
            List<OpportunityClause__c> highRiskOppClauseList;
            List<Contract__c> oppContractList = new List<Contract__c>();
            // END : YN RPP-5640 8.10.2018
            
            //START -- RPP-2762 Bry Gorospe 5/9/2018
            //standardPriceBookId    = DatabaseSOQLBank.getStandardPricebookId();
            //propertyPricebookMap  = DatabaseSOQLBank.getPropertyPricebookMap(); //SOQL FIX - 7 (Replaced with propertyMap)
            //END -- RPP-2762 Bry Gorospe 5/9/2018
            spaceIdOpportunityListMap = DatabaseSOQLBank.getActiveOpportunityPerSpace(spaceIdSet);
            
            // pkumarlg:  moved from bulkafter methode
            //nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId()); //SOQL FIX - 4
            //propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet)); //SOQL FIX - 8
            
            //jvRequiredIdSet = TaskUtility.getJVRequiredOppIds((List<Opportunity>) Trigger.new, propertyMap);
            propIdJVPropOwnershipListMap = DatabaseSOQLBank.getJVPropertyOwnerShipByProperty(propertyIdSet);
            
            // START : YN RPP-5640 8.10.2018
            try{
                oppContractList = DatabaseSOQLBank.getContractByProperty(propertyIdSet);
                system.debug('oppContractList: '+oppContractList);
            } catch(Exception e){
                oppContractList = null;
            }
            
            if(oppContractList != null){
                for(Contract__c con : oppContractList){
                    if(con.Opportunity__c != null){
                        contractOppIdSet.add(con.Opportunity__c);
                        //accCategorySet.add(con.Opportunity__r.Category__c);
                    }
                }
            }
            /*
            if(accountMap != null){
            for(Account acc : accountMap.values()){
            if(acc.Category__c != null){
            //accCategorySet.add(acc.Category__c);
            }
            }
            }*/
            //{0065D00000376gRQAQ, 0065D0000037RJPQA2, 0065D000003OPxjQAG} S890
            try{
                highRiskOppClauseList = DatabaseSOQLBank.getHighRiskOppClause(contractOppIdSet, oppCategorySet);
                system.debug('highRiskOppClauseList: '+highRiskOppClauseList.size());
            } catch(Exception e){
                highRiskOppClauseList = null;
            }
            
            if(highRiskOppClauseList != null){
                propIdOppIdOppClauseListMap = HighRiskOpportunityClauseUtility.getOppClausePerProperty(highRiskOppClauseList);
            }
            // END : YN RPP-5640 8.10.2018
            
            system.debug('highRiskOppClauseList : ' + highRiskOppClauseList);
            system.debug('propIdOppIdOppClauseListMap : ' + propIdOppIdOppClauseListMap);
            
            // START : YN RPP-5553 10.30.2018
            oppSpaceMap = DatabaseSOQLBank.getSpaceRecords(spaceIdSet); //SOQL FIX - 9
            // END : YN RPP-5553 10.30.2018
        }
    }
    
    public void bulkAfter(){  
        Set<Id> issueLeaseOppSpaceIdSet = new Set<Id>(); // START-END : YN RPP-4948 7.17.2018 
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> propertyIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<String> oppStageNameSet = new Set<String>();
        Set<String> specialityLeaseTypeSet = new Set<String>();
        Set<Id> insertOpptywithspaceIdSet = new Set<Id>();
        Set<Id> updateOpptywithspacechangeIdSet = new Set<Id>();
        Set<Id> spaceIdSet = new Set<Id>();  
        Set<Id> priceBookIdSet = new Set<Id>();
        Set<Id> opportunityAccountIdSet = new Set<Id>();
        Set<Id> preClauseIdSet = new Set<Id>();
        List<Id> opportunityIdList = new List<Id>();
        List<Space__c> spaceList = new List<Space__c>();
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        
        Map<Id, Opportunity> opportunityForSpaceUpdateMap = new Map<Id, Opportunity>();
        
        for(Opportunity newOpportunity : (List<Opportunity>) Trigger.new) { //SOQL FIX - 1
            opportunityIdSet.add(newOpportunity.Id);
        }
        opportunityMapById = new Map<Id, Opportunity>(DatabaseSOQLBank.getOpportunityList(opportunityIdSet)); //SOQL FIX - 1
        
        Set<String> openStageSet = new Set<String>{
            Constants.APPROVE,
            Constants.PROPOSE_ACCEPT,
            Constants.UNDERSTAND_NEGOTIATE
        };
                    
        opptyWithRent = RentUtility.getRentInfo(opportunityMapById.values()); //SOQL FIX - 1
        
        // below if loop code is added by pradeep to consolidate insert/update 
        if(Trigger.isUpdate || Trigger.isInsert) {
            oppRCAMetadataList = DatabaseSOQLBank.getOpportunityRCACMetadata();
            String oppRecordType;
            Opportunity oppOld = new Opportunity();
            Set<Id> allSpaceIdSet = new Set<Id>();
            Set<String> leaseTypeSet = new Set<String>();
            Set<String> businessUnitSet = new Set<String>();
            
            // for loop run for both insert/update
            for(Opportunity newOpportunity : (List<Opportunity>) Trigger.new) {
                //opportunityIdSet.add(newOpportunity.Id); //SOQL FIX - 1
                priceBookIdSet.add(newOpportunity.Pricebook2Id);
                opportunityAccountIdSet.add(newOpportunity.AccountId);
                
                if(newOpportunity.NationalAgreement__c != null){
                    preClauseIdSet.add(newOpportunity.NationalAgreement__c);
                }
                
                if(oppRecordTypeById.containsKey(newOpportunity.RecordTypeId)){
                    oppRecordType = oppRecordTypeById.get(newOpportunity.RecordTypeId).getName();
                }
                
                if(newOpportunity.Type != null){
                    leaseTypeSet.add(newOpportunity.Type);
                }
                
                if(Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(oppRecordType)){
                    businessUnitSet.add(Constants.COMMERCIAL);
                } else if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(oppRecordType)){
                    businessUnitSet.add(Constants.RETAIL);
                }else if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(oppRecordType)){
                    businessUnitSet.add(Constants.STOREROOMTYPE);
                }
                
                if(newOpportunity.AccountId != null){
                    accountIdSet.add(newOpportunity.AccountId);
                }
                
                if(newOpportunity.Property__c != null){
                    propertyIdSet.add(newOpportunity.Property__c);
                }
                
                if(newOpportunity.Space__c != null){
                    allSpaceIdSet.add(newOpportunity.Space__c);
                }
                
                if(String.isBlank(newOpportunity.SpecialityLeaseType__c)){
                    specialityLeaseTypeSet.add(Constants.STR_DEFAULT);
                } else{
                    specialityLeaseTypeSet.add(newOpportunity.SpecialityLeaseType__c);
                }
                
                // run this logic only for after insert 
                if(Trigger.isInsert){
                    oppStageNameSet.add(newOpportunity.StageName);
                    
                    
                    if(String.isNotBlank(newOpportunity.DealType__c) && newOpportunity.Space__c != null){
                        insertOpptywithspaceIdSet.add(newOpportunity.id);
                    }
                    if(newOpportunity.BestBet__c){
                        opportunityForSpaceUpdateMap.put(newOpportunity.Id, newOpportunity);
                    }
                }
                
                // run this logic only for after update
                if(Trigger.isUpdate){
                    oppOld = (Opportunity) Trigger.oldMap.get(newOpportunity.Id);
                    
                    // START : SG RPP-4311 6.25.18 Moving the logic to Deal Achieved
                    //if(oppOld.StageName != CONSTANTS.OPPORTUNITYSTAGE_ISSUE_LEASE 
                    //   && newOpportunity.StageName == CONSTANTS.OPPORTUNITYSTAGE_ISSUE_LEASE){
                    //  opportunityForSpaceUpdateMap.put(newOpportunity.Id, newOpportunity);
                    //system.debug('Enter Opportunity Deal Achieved');
                    if(oppOld.DealAchieved__c == false && newOpportunity.DealAchieved__c){
                        opportunityForSpaceUpdateMap.put(newOpportunity.Id, newOpportunity);
                        // START : YN RPP-4948 7.17.2018 
                        if(newOpportunity.Space__c != null){
                            issueLeaseOppSpaceIdSet.add(newOpportunity.Space__c);
                        }
                        // END : YN RPP-4948 7.17.2018 
                    }
                    // END : SG RPP-4311 6.25.18
                    
                    //Start MDC RPP-2762 5.16.18,
                    if(newOpportunity.Space__c != null && String.isNotBlank(newOpportunity.DealType__c)){
                        oppSpaceIdList.add(newOpportunity.space__c);
                        // 14.06.18 , pkumarlg to create outgoing when space or dealType is changed.
                        if(newOpportunity.space__c != oppOld.Space__c || newOpportunity.DealType__c != oppOld.DealType__c || newOpportunity.ProposedRentCommencementDate__c != oppOld.ProposedRentCommencementDate__c){
                               updateOpptywithspacechangeIdSet.add(newOpportunity.Id);
                           }  
                    }
                    //End MDC RPP-2762 5.16.17
                    
                    // START : YN RPP-3275 5.30.18
                    if(newOpportunity.StageName != oppOld.StageName || newOpportunity.ApprovalStatus__c != oppOld.ApprovalStatus__c){
                        oppStageNameSet.add(newOpportunity.StageName);
                    }
                    // END : YN RPP-3275 5.30.18
                    
                    if(newOpportunity.BestBet__c && 
                       newOpportunity.BestBet__c != oppOld.BestBet__c && 
                       openStageSet.contains(newOpportunity.StageName)){ opportunityForSpaceUpdateMap.put(newOpportunity.Id, newOpportunity);
                       }
                    if(newOpportunity.JDESentStatus__c!=oppOld.JDESentStatus__c&&newOpportunity.JDESentStatus__c==Constants.OPPO_JDE_STATUS_READY){
                        opportunityForSpaceUpdateMap.put(newOpportunity.Id, newOpportunity);
                    }
                }
            }
            
            if(Trigger.isUpdate){
                //History tracking
                HistoryTrackingUtil.HistoryTrackingWrapper historyTracker =  new HistoryTrackingUtil.HistoryTrackingWrapper();
                historyTracker.newMap = Trigger.newMap;
                historyTracker.oldMap = Trigger.oldMap;
                historyTracker.objectAPIName = Constants.OPPORTUNITY;
                historyTracker.FieldSetAPIName = Constants.FIELD_SET_API_NAME;
                historyTracker.historyobjectAPIname = Constants.HISTORY_TRACKING_OPPO;
                histories = (List<OpportunityAuditHistory__c>) HistoryTrackingUtil.historyTracking(historyTracker);
            }
            
            //topParentAccountMap = OpportunityBL.buildTopParentAccountMap(opportunityAccountIdSet, accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId()); //SOQL FIX - 2
            // opportunityLineItemMap = DatabaseSOQLBank.getOpportunityLineItem(opportunityIdSet); //SOQL FIX - 10 No where used
            pbEntryList = DatabaseSOQLBank.getPriceBookEntry(priceBookIdSet); //SOQL FIX - 11
            
            // Start LF RPP-10151 5.8.2019
            priceBookRentRevProdIdMap = OpportunityBL.filterPriceBookEntryByName(pbEntryList, Constants.PRODUCT_RENT_REVIEW); //SOQL FIX - 11
            priceBookPromoRevProdIdMap = OpportunityBL.filterPriceBookEntryByName(pbEntryList, Constants.PRODUCT_PROMO_REVIEW); //SOQL FIX - 11
            // End LF RPP-10151 5.8.2019
            
            // START : YN RPP-6061 9.12.2018
            //oppSpaceMap = DatabaseSOQLBank.getSpaceRecords(allSpaceIdSet); //SOQL FIX - 9
            // END : YN RPP-6061 9.12.2018
            
            // bulk logic for after insert goes here
            if(Trigger.isInsert){
                List<Opportunity> opportunityList = (List<Opportunity>) Trigger.new;
                accountPrecedentClauseMap = OpportunityBL.buildAccountPrecedentClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId()); //SOQL FIX - 3
                opportunityIdList.addAll(insertOpptywithspaceIdSet);
                // method to create content documentlink of type lease plan on oppty creation.
                contentDocumentLinkList = ContentBL.createContentDocumentLink(opportunityList, 'Opportunity');
                
                // START : KT RPP-4921 7.20.18
                /*try{
                    affiliationsMap = DatabaseSOQLBank.getAffiliationMap(opportunityAccountIdSet);
                } catch(Exception e){
                    affiliationsMap = null;
                }*/ //SOQL FIX - 6
                // END : KT RPP-4921 7.20.18
            }
            
            // bulk logic for after update goes here
            if(Trigger.isUpdate){
                
                
                // Start LF RPP-10151 5.8.2019
                Set<Id> productIdSet = new Set<Id>();
                
                if (priceBookRentRevProdIdMap != null) {
                    for (PriceBookEntry pbe : priceBookRentRevProdIdMap.values()) {
                        productIdSet.add(pbe.Product2Id);
                    }
                }
                if (priceBookPromoRevProdIdMap != null) {
                    for (PriceBookEntry pbe : priceBookPromoRevProdIdMap.values()) {
                        productIdSet.add(pbe.Product2Id);
                    }
                }     
                // End LF RPP-10151 5.8.2019
                
                if(opportunityIdSet.size() > 0) {
                    for(OpportunityLineItem oppRec : DatabaseSOQLBank.getFlexiOppLineItems(opportunityIdSet, productIdSet)) {
                        if(flexiOpportunityLineItemMap.containsKey(oppRec.OpportunityId)){
                            flexiOpportunityLineItemMap.get(oppRec.OpportunityId).add(oppRec);
                        } else {
                            flexiOpportunityLineItemMap.put(oppRec.OpportunityId, new List<OpportunityLineItem>{oppRec});
                        }
                    }
                }
                // START : YN RPP-4948 7.17.2018 
                if(issueLeaseOppSpaceIdSet != null && !issueLeaseOppSpaceIdSet.isEmpty()){
                    spaceGroupList = SpaceBL.getAllSpaceGroupByGroupNumber(issueLeaseOppSpaceIdSet);
                }
                
                
                //RPP-3590 NG 23072018 - START
                for(SpaceGroup__c sGroup : spaceGroupList){
                    if(sGroup.EffectiveDate__c == null){
                        sGroup.EffectiveDate__c = System.Date.today();   
                    }    
                }
                //RPP-3590 NG 23072018 - END
                
                // update space records
                if(opportunityForSpaceUpdateMap != null && !opportunityForSpaceUpdateMap.isEmpty()){
                    //spaceList = DatabaseSOQLBank.getSpaces(spaceIdSet);
                    spaceToUpdateList = SpaceBL.updateSpaceRecords(opportunityForSpaceUpdateMap, spaceGroupList);
                }
                // END : YN RPP-4948 7.17.2018
                
                // opportunity platform event start
                Map<Id, Opportunity> dbOppoDataMapToPublish = OpportunityBL.oppoEventTriggerCriteriaCheck(Trigger.newmap); //SOQL FIX - 12
                EventpublishHelper.Eventpublishwrapper oppoWrapper = new EventpublishHelper.Eventpublishwrapper();
                
                if(EventpublishHelper.isValidpublish() && dbOppoDataMapToPublish != null && dbOppoDataMapToPublish.size() > 0){
                    oppoWrapper = EventpublishHelper.opportunityFieldChangePublishHelper(Trigger.oldMap, Trigger.newMap, dbOppoDataMapToPublish);
                    oppoEventsToPublish.addAll((List<OpportunityEvent__e>) oppoWrapper.eventsobjectList);
                }
                
                opportunityIdList.addAll(updateOpptywithspacechangeIdSet);
                oppoIdOpportunityLineItemMap = DatabaseSOQLBank.getOpportunityLineItem(updateOpptywithspacechangeIdSet);
            }
            
            opportunityProductList = OpportunityLineItemController.AddOutgoings(opportunityIdList);
            
            // below logic will run for both after insert/update
            
            //START -- RPP-3048 Kyle Tan 5/29/2018, pkumarlg: below code is moved to beforebulk
            //nationalAgreementClauseMap = OpportunityBL.buildNationalAgreementClauseMap(topParentAccountMap, precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_AGREEMENTS).getRecordTypeId()); //SOQL FIX - 4
            //propertyMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet)); //SOQL FIX - 8
            //END -- RPP-3048 Kyle Tan 5/29/2018 
            
            nationalAgreementByIdMap = DatabaseSOQLBank.getPrecedentClause(preClauseIdSet);
            
            Set<Id> parentAccountIdSet = new Set<Id>();
            /*try{
                accountMap = DatabaseSOQLBank.getAccountById(accountIdSet);
            } catch(Exception e){
                accountMap = null;
            }*/ //SOQL FIX - 5
            
            for(Account acc : accountMap.values()){
                if(acc.ParentId != null){
                    parentAccountIdSet.add(acc.ParentId);
                    
                    if(acc.Parent.ParentId != null){
                        parentAccountIdSet.add(acc.Parent.ParentId);
                    }
                }
            }
            
            // START : YN RPP-3275 5.30.18
            taskOwnerWrap = TaskUtility.getOppAndPropertyTeamMember(propertyIdSet, opportunityIdSet, parentAccountIdSet);
            
            try{
                system.debug('TASK TEMPLATE QUERY');
                taskTemplateMap = DatabaseSOQLBank.getTaskTemplate(
                    Constants.OPPORTUNITY, businessUnitSet, leaseTypeSet, specialityLeaseTypeSet
                );
                system.debug('TASK TEMPLATE QUERY : ' + taskTemplateMap);
            } catch(Exception e){
                system.debug('e.getMessage() : ' + e.getMessage());
                taskTemplateMap = null;
            }
            // END : YN RPP-3275 5.30.18
            
            TaskUtility.getSpaceWithLeasePlan(allSpaceIdSet);
            
            system.debug('taskTemplateMap : ' + taskTemplateMap);
            system.debug('leaseTypeSet : ' + leaseTypeSet);
            system.debug('businessUnitSet : ' + businessUnitSet);
            system.debug('specialityLeaseTypeSet : ' + specialityLeaseTypeSet);
            
            // START : RPP-6061 Yana Navarro 9.12.2018
            System.debug('opportunityIdSet FORCOVERAG   ' + opportunityIdSet);
            highRiskOppClauseListMap = DatabaseSOQLBank.getHightRiskOpportunityClause(opportunityIdSet);
            System.debug('highRiskOppClauseListMap FORCOVERAGE   ' + highRiskOppClauseListMap);
            
            system.debug('highRiskOppClauseListMap : ' + highRiskOppClauseListMap);
            
            for(Id oppId : highRiskOppClauseListMap.keySet()){
                for(OpportunityClause__c oppClause : highRiskOppClauseListMap.get(oppId)){
                    if(oppClause.IsAutomated__c) {
                        if(oppIdSubTypeOppClauseListMap.containsKey(oppId)){
                            if(oppIdSubTypeOppClauseListMap.get(oppId).containsKey(oppClause.ReferencedClause__r.SubType__c)){
                                oppIdSubTypeOppClauseListMap.get(oppId).get(oppClause.ReferencedClause__r.SubType__c).add(oppClause);
                            } else {
                                oppIdSubTypeOppClauseListMap
                                    .get(oppId)
                                    .put(
                                        oppClause.ReferencedClause__r.SubType__c, 
                                        new List<OpportunityClause__c>{
                                            oppClause
                                                }                                        
                                    );
                            }
                        } else {
                            oppIdSubTypeOppClauseListMap.put(
                                oppId, 
                                new Map<String, List<OpportunityClause__c>>{
                                    oppClause.ReferencedClause__r.SubType__c => new List<OpportunityClause__c>{
                                        oppClause
                                            }
                                }
                            );
                        }
                    }
                }
            }
            
            system.debug('oppIdSubTypeOppClauseListMap : ' + oppIdSubTypeOppClauseListMap);
            
            subTypeClauseLibraryListMap = DatabaseSOQLBank.getHighRiskClauseLibraryBySubType();
            // END : RPP-6061 Yana Navarro 9.12.2018
        }
    }
    
    public void beforeInsert(SObject so)
    {
        Space__c oppSpace;
        Opportunity newOpportunity  = (Opportunity)so;
        Property__c propertyRecord  = new Property__c();
        List<OpportunityContactRole> tempList = new List<OpportunityContactRole>();
        Boolean isConfigured = false;
        String newOppRecordTypeName = oppRecordTypeById.get(newOpportunity.RecordTypeId).getName();
        
        List<PropertyOwnership__c> propertyOwnershipList;
        
        // RPP - 5521
        OpportunityBL.populateTechBudgetFields(newOpportunity);
        
        //RPP-10771 START
        System.debug('spaceIdContractListMap 10771 >>>'+spaceIdContractListMap);
        if(spaceIdContractListMap.containsKey(newOpportunity.Space__c)){
           newOpportunity.ForecastedRentTerminationDate__c = spaceIdContractListMap.get(newOpportunity.Space__c)[0].ActualVacateDate__c;
        }
        //RPP-10771 END
        
        // if(!newOpportunity.TechByPassOnClone__c){
        // START : YN RPP-5553 10.30.2018
        if(oppSpaceMap.containsKey(newOpportunity.Space__c)){
            oppSpace = oppSpaceMap.get(newOpportunity.Space__c);
            // START : YN RPP-913 8.7.2018
            if(!Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(oppSpace.Status__c) && propertyMap != null
                && propertyMap.containsKey(newOpportunity.Property__c))
            {
                    if(propIdJVPropOwnershipListMap != null
                        && propIdJVPropOwnershipListMap.containsKey(newOpportunity.Property__c)){
                        propertyOwnershipList = propIdJVPropOwnershipListMap.get(newOpportunity.Property__c);
                    }
                   
                    newOpportunity.TECHJVRequired__c = TaskUtility.isJVRequired(
                        newOpportunity, 
                        propertyMap.get(newOpportunity.Property__c),
                        propertyOwnershipList
                    );
            } 
            else {
                newOpportunity.TECHJVRequired__c = false;
                System.debug('TECHJVRequired__c is explicitly set to false');
            }
        }
        // END : YN RPP-913 8.7.2018
        // END : YN RPP-5553 10.30.2018 
        
        //START -- RPP-2762 Bry Gorospe 5/9/2018
        // use standard pricebook if no Property selected
        System.debug('TechByPassOnClone__c === '+newOpportunity.TechByPassOnClone__c);
        if(!newOpportunity.TechByPassOnClone__c){ //// ************* NEEL
            if (newOpportunity.Property__c != NULL && propertyMap.containsKey(newOpportunity.Property__c)) {
                propertyRecord = propertyMap.get(newOpportunity.Property__c);
                newOpportunity.CurrencyIsoCode=propertyRecord.CurrencyIsoCode;
                if(propertyRecord.PriceBook__c != null) {
                    newOpportunity.Pricebook2Id = propertyRecord.PriceBook__c;
                }
            }
            //END -- RPP-2762 Bry Gorospe 5/9/2018
            
            //START : KT RPP-3542 6.5.18
            /*if(topParentAccountMap.containsKey(newOpportunity.AccountId)){
                if(accountPrecedentClauseMap.containsKey(topParentAccountMap.get(newOpportunity.AccountId))) {
                    for(PrecedentClause__c precClauseRec : accountPrecedentClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId))){
                        if(precClauseRec.PercentageRentPercent__c != null) {
                            //newOpportunity.PercentageRentPercent__c = precClauseRec.PercentageRentPercent__c;
                        }
                    }
                }
            }*/ //SOQL FIX - 3 - PercentageRentPercent__c was already commented. Thus commented the block
            //END : KT RPP-3542 6.5.18
            
            if(nationalAgreementClauseMap.containsKey(topParentAccountMap.get(newOpportunity.AccountId))) {
                if(nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).FitOutPeriod__c > 0) {
                    newOpportunity.NationalFitoutPeriod__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).FitOutPeriod__c;
                }
                if(String.isNotEmpty(nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).StandardReviewTypes__c)) {
                    newOpportunity.StandardReviewType__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).StandardReviewTypes__c;
                } else if(propertyMap.containsKey(newOpportunity.Property__c)&& String.isNotEmpty(propertyMap.get(newOpportunity.Property__c).RentReviewType__c)) {
                    newOpportunity.StandardReviewType__c = propertyMap.get(newOpportunity.Property__c).RentReviewType__c;                    
                }
                if(String.isNotEmpty(nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).GuaranteesType__c)) {
                    newOpportunity.GuaranteesType__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).GuaranteesType__c;
                }
                if(nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).PercentageRentPercent__c != null && !Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)) {
                    newOpportunity.PercentageRentPercent__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).PercentageRentPercent__c;
                }
                
                //RPP-10989 - START
                System.debug('nationalAgreementClauseMap === '+nationalAgreementClauseMap);
                System.debug('topParentAccountMap === '+topParentAccountMap);
                System.debug('AccountId === '+newOpportunity.AccountId);
                if(nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).Name == Constants.NATIONAL_AGREEMENTS
                  && !Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
                    newOpportunity.Nil_Holdover_Increase__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).Nil_Holdover_Increase__c;
                    System.debug('Nil_Holdover_Increase__c === '+newOpportunity.Nil_Holdover_Increase__c);
                }
                //RPP-10989 - END
            }
            if(newOpportunity.Type==Constants.OPPTY_STAGENAME_NEWRETAILER){
                newOpportunity.FitoutDays__c=21;
                if(newOpportunity.NationalFitoutPeriod__c!=0&&newOpportunity.NationalFitoutPeriod__c!=null){
                    newOpportunity.FitoutDays__c=newOpportunity.NationalFitoutPeriod__c;  
                }else if(newOpportunity.Tech_SpaceType__c==Constants.SPACETYPEKIOSK){
                    newOpportunity.FitoutDays__c=14;
                } else if(newOpportunity.Tech_SpaceType__c==Constants.STOREROOM){
                    newOpportunity.FitoutDays__c=0;
                }
                
                // START : YN RPP-7399 12.17.2018
                if(newOpportunity.CurrencyISOCode == 'AUD'){
                    if(newOpportunity.ProposedHandoverDate__c!=null){
                        newOpportunity.ProposedStartDate__c = newOpportunity.ProposedHandoverDate__c;
                    }
                    if(newOpportunity.ProposedHandoverDate__c!=null&&newOpportunity.FitoutDays__c!=null){
                        newOpportunity.ProposedStartDate__c=newOpportunity.ProposedHandoverDate__c.addDays(Integer.valueOf(newOpportunity.FitoutDays__c));
                    }          
                    newOpportunity.ProposedRentCommencementDate__c = newOpportunity.ProposedStartDate__c;
                    newOpportunity.ForecastRentCommencementDate__c = newOpportunity.ProposedStartDate__c;   // -- 4/10/19
                    if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(newOppRecordTypeName) || Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(newOppRecordTypeName) ){    // -- RPP - 10788
                      newOpportunity.ProposedShopOpeningDate__c = newOpportunity.ProposedStartDate__c;        // -- RPP - 10788  
                    }
                } else if(newOpportunity.CurrencyISOCode == 'NZD'){
                    if(newOpportunity.ProposedHandoverDate__c != null){
                        newOpportunity.ProposedStartDate__c = newOpportunity.ProposedHandoverDate__c;
                    } else if(newOpportunity.ProposedStartDate__c != null){
                        newOpportunity.ProposedHandoverDate__c = newOpportunity.ProposedStartDate__c;
                    }
                    
                    if(newOpportunity.ProposedHandoverDate__c != null && newOpportunity.FitoutDays__c != null){
                        newOpportunity.ProposedRentCommencementDate__c = newOpportunity.ProposedHandoverDate__c.addDays(Integer.valueOf(newOpportunity.FitoutDays__c));
                        newOpportunity.ForecastRentCommencementDate__c = newOpportunity.ProposedHandoverDate__c.addDays(Integer.valueOf(newOpportunity.FitoutDays__c)); // -- 4/10/19
                        if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(newOppRecordTypeName) || Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(newOppRecordTypeName) ){    // -- RPP - 10788
                           newOpportunity.ProposedShopOpeningDate__c = newOpportunity.ProposedHandoverDate__c.addDays(Integer.valueOf(newOpportunity.FitoutDays__c));           // -- RPP - 10788 
                        } 
                    }
                }
                // END : YN RPP-7399 12.17.2018
            }
            
            newOpportunity.ProposedEndDate__c=OpportunityBL.CalculateProposedEndDate(newOpportunity);
            //default development type base on space create on create only.
            newOpportunity.DevelopmentType__c=newOpportunity.TechSpaceStatus__c;
            newOpportunity.TECH_RecoverableArea__c=newOpportunity.SpaceRecoverableArea__c;
            
            
            //START : SG RPP-4159 6.15.18
            if(newOppRecordTypeName == CONSTANTS.OPP_COMMERCIAL_LEASING){
                newOpportunity.ChargeCommencementDate__c = newOpportunity.ProposedRentCommencementDate__c;
            }
            //END : SG RPP-4159 6.15.18
            if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
                newOpportunity.StandardReviewType__c = CONSTANTS.FIXED_FIVE_PERCENT;
            }
            // START : YN RPP-4359 6.29.18
            // START : YN RPP-10092 7.23.19
            if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(newOppRecordTypeName)||Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
                if(spaceIdOpportunityListMap.containsKey(newOpportunity.Space__c) && spaceIdOpportunityListMap.get(newOpportunity.Space__c).size() > 0){
                    Opportunity oppTemp = spaceIdOpportunityListMap.get(newOpportunity.Space__c)[0];
                    if(!spaceIdOpportunityListMap.get(newOpportunity.Space__c)[0].BestBet__c){
                        newOpportunity.BestBet__c = true;
                    } else if(newOpportunity.BestBet__c) {
                        for(Opportunity opp: spaceIdOpportunityListMap.get(newOpportunity.Space__c)){
                            opp.BestBet__c = false;
                            if(Approval.isLocked(opp.Id)){
                                Approval.unlock(opp.id);
                                LockedOpportunityList.add(opp);
                            }else{
                                opportunityUpdateList.add(opp);
                            }
                        }  
                        //newOpportunity.addError(Label.ExistingBestBetErrorMessage);
                    }
                }else{
                    newOpportunity.BestBet__c = true;
                }
            }
            // END : YN RPP-10092 7.23.19     
            // END : YN RPP-4359 6.29.18
            
            // START : KT RPP-4921 7.17.18
            if(topParentAccountMap.containsKey(newOpportunity.AccountId) && nationalAgreementClauseMap.containsKey(topParentAccountMap.get(newOpportunity.AccountId))) {
                PrecedentClause__c nationalAggClauseRec = new PrecedentClause__c();
                nationalAggClauseRec = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId));
                if(nationalAggClauseRec.RequiredSecurityDepositMonths__c != null && nationalAggClauseRec.RequiredSecurityDepositMonths__c > 0) {
                    newOpportunity.SecurityDepositMonths__c = nationalAggClauseRec.RequiredSecurityDepositMonths__c;
                } else if(nationalAggClauseRec.RequiredSecurityDepositWeeks__c != null && nationalAggClauseRec.RequiredSecurityDepositWeeks__c > 0) {
                    newOpportunity.SecurityDepositWeeks__c = nationalAggClauseRec.RequiredSecurityDepositWeeks__c;
                } else if(nationalAggClauseRec.RequiredSecurityDepositDays__c != null && nationalAggClauseRec.RequiredSecurityDepositDays__c > 0) {
                    newOpportunity.SecurityDepositDays__c = nationalAggClauseRec.RequiredSecurityDepositDays__c;
                }
                if(String.isNotEmpty(nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).SecurityDepositType__c)) {
                    newOpportunity.SecurityDepositType__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).SecurityDepositType__c;
                }
                newOpportunity.NationalAgreement__c = nationalAgreementClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId)).Id;
            } else {
                if(propertyMap.containsKey(newOpportunity.Property__c) && Constants.ACT.equalsIgnoreCase(propertyMap.get(newOpportunity.Property__c).PropertyState__c )) {
                    //3 months for ACT
                    newOpportunity.SecurityDepositMonths__c = 3;
                } else {
                    //4 months for other states
                    newOpportunity.SecurityDepositMonths__c = 4;
                }
            }
            if(newOpportunity.AnnualMinimumRent__c != null && newOpportunity.AnnualMinimumRent__c > 0&&!newOpportunity.DealAchieved__c) {
                newOpportunity.SecurityDeposit__c = OpportunityBL.updateSecurityDeposit(newOpportunity, topParentAccountMap, nationalAgreementClauseMap, accountMap, propertyMap, GSTList);
            }
            // END : KT RPP-4921 7.17.18
            
            // START : KT RPP-4921 7.20.18
            tempList = OpportunityBL.createOppContactRoles(newOpportunity, affiliationsMap);
            newOpportunity.NumberofGuarantors__c = tempList.size();
            // END : KT RPP-4921 7.20.18
            
            // START : LF RPP-10238 4.23.2019
            List<String> guarantors = new List<String>();
            for(OpportunityContactRole opcr : tempList) {
                guarantors.add(affiliationContactsMap.get(opcr.ContactId).Name);
            }
            newOpportunity.Guarantors__c = String.join(guarantors, ', ');
            system.debug(newOpportunity.Guarantors__c);
            // END : LF RPP-10238 4.23.2019     
            /*
            //START : NEEL RPP-8990 - COMMENTED OUT
            //// START : KT RPP-5548 8.3.18
            if(Constants.UNDERSTAND_NEGOTIATE.equalsIgnoreCase(newOpportunity.StageName) && 
            spaceGroupMap.containsKey(newOpportunity.Space__c)) {
            isConfigured = SpaceBL.checkActiveConfigurations(spaceGroupMap.get(newOpportunity.Space__c), newOpportunity.Space__c);
            }
            if(isConfigured) {
            newOpportunity.addError(Label.SpaceReconfig_ErrorMessage);
            }
            // END : KT RPP-5548 8.3.18
            // END : NEEL RPP-8990
            // */
            
            // START : YN RPP-5640 8.10.2018
            if(propIdOppIdOppClauseListMap.containsKey(newOpportunity.Property__c)&&newOpportunity.Tech_SpaceType__c!=Constants.STOREROOM){
                HighRiskOpportunityClauseUtility.countRCA(newOpportunity, propIdOppIdOppClauseListMap.get(newOpportunity.Property__c));
            }else{
                newOpportunity.NoofRCA__c = 0;  
            }
            // END : YN RPP-5640 8.10.2018
        }
        
        System.debug('TechByPassOnClone__c === '+newOpportunity.TechByPassOnClone__c);
        // START: RPP - 10553 LF 6.20.2019
        OpportunityBL.virtualVacancyUpdates(newOpportunity);
        Space__c updateSpace = SpaceBL.updateStatusBasedOnVirtualVacancy(oppSpace, newOpportunity);
        if (updateSpace != null) {
            spaceToUpdateForVirtualVacancyList.add(updateSpace);
        }
        // END: RPP - 10553 LF 6.20.2019N
        
        // START: RPP - 10961
         if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
            newOpportunity.PromoLevyIncluded__c = 'No';
        }
        // END: RPP - 10961
       
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {  
        Space__c oppSpace;
        Opportunity updateOpportunity  = (Opportunity)so;
        //START -- RPP-2762 MDC 5/23/2018
        Opportunity oldOpportunity  = (Opportunity)oldSo;
        Opportunity oppTemp;
        Property__c propertyRecord  = new Property__c();
        String newOppRecordTypeName;
        Boolean forecastOppisConfigured = false;
        Boolean forcastFieldsisChanged = false;
        Set<String> approvalstatusvalues=new Set<String>();
        Boolean allowEdit = TRUE;    //10677
        
        //RPP-10975 START
        if(updateOpportunity.DealAchieved__c != oldOpportunity.DealAchieved__c && updateOpportunity.DealAchieved__c == TRUE ){
            updateOpportunity.Stretch_Rent_Fixed__c = oldOpportunity.Stretch_Rent__c;
            updateOpportunity.Stretch_Rent_Variance_Fixed__c = oldOpportunity.Stretch_Rent_Variance__c;
        }
        //RPP-10975 END
        
        // RPP - 5521
        OpportunityBL.populateTechBudgetFields(updateOpportunity);
        
        //10677 22-10-2019 START
        System.debug('updateOpportunity.ApprovalStatus__c'+updateOpportunity.ApprovalStatus__c);
        if(updateOpportunity.ApprovalStatus__c == '' || updateOpportunity.ApprovalStatus__c == NULL ){
            if(updateOpportunity.AccountId != oldOpportunity.AccountId ||  updateOpportunity.Property__c != oldOpportunity.Property__c  ||  updateOpportunity.Type != oldOpportunity.Type){
              	if(!bypassApprovalLock){
                  	allowEdit = FALSE;
              	}
            }
        }
        
        //Current Approver
        Id cuApproverId;
        if(oppIdVsProcessInstWorkItm.containsKey(updateOpportunity.Id))
        	cuApproverId = oppIdVsProcessInstWorkItm.get(updateOpportunity.Id);
        
        System.debug('cuApproverId: '+cuApproverId);
        //System.debug('IdVsProfile: '+IdVsProfile);
        System.debug('IdVsProfile.containsKey(UserInfo.getProfileId(): '+bypassApprovalLock);
        System.debug('UserInfo.getUserId(): '+UserInfo.getUserId());
                     
        /*Pending Initial Approval*/
        if(!bypassApprovalLock 
            && oldOpportunity.ApprovalStatus__c ==  Constants.PENDING_INI_APRV  
            && !updateOpportunity.Name.containsIgnoreCase('Variation')){
           /*&& UserInfo.getUserId() != updateOpportunity.OwnerId*/
          	if(cuApproverId != NULL){
                if(cuApproverId != UserInfo.getUserId())
                    allowEdit = FALSE;
            }
        }
        
        /*Initial Approval Granted AND Update Deal Terms task Completed*/
        if(!bypassApprovalLock 
            && updateOpportunity.ApprovalStatus__c ==  Constants.INIAPPR_GRANTED 
            && updateOpportunity.UpdateDealTermsCompleted__c == FALSE 
            && !updateOpportunity.Name.containsIgnoreCase('Variation')){
               allowEdit = FALSE;
        }
        
        /*Pending Final Approval*/
        if(!bypassApprovalLock 
            && updateOpportunity.ApprovalStatus__c == Constants.PEND_FINALAPPROV  
            && cuApproverId != UserInfo.getUserId()){
           /*&& UserInfo.getUserId() != updateOpportunity.OwnerId*/
            if(cuApproverId != NULL){
                   if(cuApproverId != UserInfo.getUserId())
                       allowEdit = FALSE;
               }
        }
        
        /*Final Approval Granted*/
        if(!bypassApprovalLock  
            && updateOpportunity.ApprovalStatus__c == Constants.FINALAPPR_GRANT){
           /*&& UserInfo.getUserId() != updateOpportunity.OwnerId*/
           allowEdit = FALSE;
        }
        
        // RPP - 10840 - Restrict fields for store room record type once oppty approval is sent for approval till end of lifecycle.
        if(!bypassApprovalLock 
            && updateOpportunity.ApprovalStatus__c == Constants.STRAPPOVALGRANTED 
            && updateOpportunity.RecordTypeId == opportunityRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId()){
           	
            allowEdit = FALSE;
        }
        
        //the below if condition added for RPP - 10875 -- 26/11/2019
        if(updateOpportunity.StageName != oldOpportunity.StageName 
            && Constants.OPPTY_STAGENAME_CLOSED.equalsIgnoreCase(updateOpportunity.StageName) 
            && updateOpportunity.RecordTypeId == opportunityRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId()){
           allowEdit = TRUE;
        }
        
        if(!allowEdit){
         for(String fieldapiname :fieldSetandfieldAPInameOpp.get(Constants.OPP_FIELDS_ALLOWED_FOR_EDITS)){
                System.debug('Field: '+fieldapiname+'====Old Value: '+oldOpportunity.get(fieldapiname)+'====New Value: '+updateOpportunity.get(fieldapiname));
             	
             	//For All Fields in FieldSet
             	if(updateOpportunity.get(fieldapiname) != oldOpportunity.get(fieldapiname)){
                    updateOpportunity.addError('RPP-10677: This record is Locked. If you need to edit it, contact your Admin.');
                }

             	//For ForecastRent__c AND TotalASRForecastCapital__c only for Final Approval Granted
             	if((updateOpportunity.get('ForecastRent__c') != oldOpportunity.get('ForecastRent__c')  || updateOpportunity.get('TotalASRForecastCapital__c') != oldOpportunity.get('TotalASRForecastCapital__c'))  && updateOpportunity.ApprovalStatus__c == Constants.FINALAPPR_GRANT){
                   updateOpportunity.addError('RPP-10677: This record is Locked. If you need to edit it, contact your Admin.');
                   }
            }
        }
        //10677 22-10-2019 END
        
        /*
        SYstem.debug('newOpportunity123==>  ' +updateOpportunity);
        SYstem.debug('newOpportunity123==>  ' +oldOpportunity);
        if(updateOpportunity.ApprovalStatus__c == 'Pending Final Approval' || updateOpportunity.ApprovalStatus__c == 'Pending Initial Approval'){

        List<ProcessInstance> pendingApproverLst = [select id,status, targetobjectid, (SELECT actor.name,originalactorid,StepStatus FROM StepsAndWorkitems) 
        from ProcessInstance where targetobjectid =: updateOpportunity.id AND STATUS = 'Pending'];

        for(ProcessInstance p: pendingApproverLst){
        system.debug('The pending actor after '+  p.StepsAndWorkitems);
        for(ProcessInstanceHistory h: p.StepsAndWorkitems){
        if(h.StepStatus == 'Pending'){
        system.debug('data=> ' + h.actor.name);

        System.debug('LockStatus==> ' + Approval.isLocked(updateOpportunity.id));
        //Approval.unlock(updateOpportunity.id);
        System.debug('LockStatus==> ' + Approval.isLocked(updateOpportunity.id));
        updateOpportunity.Pending_Approver__c = h.actor.id;
        //Approval.lock(updateOpportunity.id);
        System.debug('LockStatus==> ' + Approval.isLocked(updateOpportunity.id));
        }
        }
        }

        }
        */
        List<PropertyOwnership__c> propertyOwnershipList;
        
        if(oppRecordTypeById.containsKey(updateOpportunity.RecordTypeId)){
            newOppRecordTypeName = oppRecordTypeById.get(updateOpportunity.RecordTypeId).getName();
        }
        
        Savepoint sp = Database.setSavepoint();
        //List<Opp_Fields_Allowed_For_Edits__mdt> fieldsAllowedForEdits = [SELECT MasterLabel FROM Opp_Fields_Allowed_For_Edits__mdt]; //SOQL FIX - 13
        
        
        //RPP-10473: Added by Abhishek M.
        /*if(!Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
        if(updateOpportunity.Reverse_Opportunity__c != oldOpportunity.Reverse_Opportunity__c && updateOpportunity.Reverse_Opportunity__c){

        Opportunity opp = [SELECT Id, (SELECT Id, Status, Subject FROM Tasks WHERE TaskType__c =: Constants.TASK_TYPE_INSTRUCT_SOLICITOR AND Status =: Constants.COMPLETED)
        FROM Opportunity 
        WHERE Id = :updateOpportunity.Id];

        if(opp.Tasks.size() > 0){
        updateOpportunity.addError('Instruct Solicitor task is completed. Opportunity cannot be reversed.');
        return;
        }else{
        Boolean oppCheck;// = OpportunityReversal.reverseOpportunity(updateOpportunity);
        if(oppCheck){
        //opptyReversalTask.add(OpportunityReversal.createTaskOnnewOpptyReversal(updateOpportunity));
        }
        }
        }
        }*/
        //RPP-10473
        
        // START : YN RPP-5553 10.30.2018
        if(oppSpaceMap.containsKey(updateOpportunity.Space__c)){
            oppSpace = oppSpaceMap.get(updateOpportunity.Space__c);
            
            // END : YN RPP-5553 10.30.2018
            system.debug('propertyMapBeforeUpdate--------'+propertyMap); 
            // START : YN RPP-913 8.7.2018     OR RPP-10935
            if(!Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(oppSpace.Status__c)&& propertyMap != null
               && propertyMap.containsKey(updateOpportunity.Property__c) 
               //RPP-11032 - JV approval task is not generated in opportunity workflow for JV properties
               && updateOpportunity.StageName != Constants.OPPTY_STAGENAME_ISSUE_LEASE){
                   
                   if(propIdJVPropOwnershipListMap != null
                      && propIdJVPropOwnershipListMap.containsKey(updateOpportunity.Property__c)){
                          propertyOwnershipList = propIdJVPropOwnershipListMap.get(updateOpportunity.Property__c);
                      }
                   updateOpportunity.TECHJVRequired__c = TaskUtility.isJVRequired(
                       updateOpportunity, 
                       propertyMap.get(updateOpportunity.Property__c),
                       propertyOwnershipList
                   );
               } else {
                   updateOpportunity.TECHJVRequired__c = false;
               }
        }
        // END : YN RPP-913 8.7.2018
        
        if (updateOpportunity.Property__c != NULL && oldOpportunity.Property__c != updateOpportunity.Property__c && propertyMap.containsKey(updateOpportunity.Property__c)) {
            propertyRecord = propertyMap.get(updateOpportunity.Property__c);
            if(propertyRecord.PriceBook__c != null) {
                updateOpportunity.Pricebook2Id = propertyRecord.PriceBook__c;
            }
        }
        //END -- RPP-2762 MDC 5/23/2018
        
        if(oldOpportunity.TermDays__c <> updateOpportunity.TermDays__c || oldOpportunity.TermMonths__c <> updateOpportunity.TermMonths__c || oldOpportunity.TermYr__c <> updateOpportunity.TermYr__c){
            updateOpportunity.ProposedEndDate__c=OpportunityBL.CalculateProposedEndDate(updateOpportunity);
        }
        // START : CG RPP-6949 9.6.2018 
        else if(oldOpportunity.ProposedStartDate__c <> updateOpportunity.ProposedStartDate__c || oldOpportunity.ProposedEndDate__c <> updateOpportunity.ProposedEndDate__c){
            Date startDate = updateOpportunity.ProposedStartDate__c;
            Date startDateTemp = updateOpportunity.ProposedStartDate__c;
            Date endDate;
            Integer monthBet;
            Integer oppDay = 0;
            Integer oppYear = 0;
            Integer oppMonth = 0;
            
            if(updateOpportunity.ProposedEndDate__c != null){
                endDate = updateOpportunity.ProposedEndDate__c.addDays(1);
                monthBet = startDate.monthsBetween(endDate);
                oppYear = monthBet /12;
                oppMonth = Math.Mod(monthBet ,12);
                startDate = startDate.addYears(oppYear);
                startDate = startDate.addMonths(oppMonth);
                oppDay = startDate.daysBetween(endDate);
                
                if(oppDay < 0) {
                    oppYear -= 1;
                    startDateTemp = startDateTemp.addYears(oppYear);
                    oppMonth = startDateTemp.monthsBetween(endDate) - 1;
                    
                    if(oppMonth>=12) {
                        oppYear = oppMonth / 12;
                        oppMonth = Math.Mod(oppMonth ,12);
                        startDateTemp = startDateTemp.addYears(1);
                    }
                    startDateTemp = startDateTemp.addMonths(oppMonth);
                    oppDay = startDateTemp.daysBetween(endDate);
                }
            }
            
            updateOpportunity.TermDays__c = oppDay;
            updateOpportunity.TermMonths__c = oppMonth;
            updateOpportunity.TermYr__c = oppYear;
            
        }
        // END: CG RPP-6949 9.6.2018 
        /*
        if((updateOpportunity.AnnualMinimumRent__c!=null&&updateOpportunity.AnnualMinimumRent__c!=0&&oldOpportunity.AnnualMinimumRent__c!=updateOpportunity.AnnualMinimumRent__c)||updateOpportunity.AnnualMinimumRent__c!=null&&updateOpportunity.AnnualMinimumRent__c!=0&&updateOpportunity.RentInAdvance__c==null){
        if(updateOpportunity.Type!=Constants.OPPTY_STAGENAME_NEWLEASE){
        updateOpportunity.RentInAdvance__c=updateOpportunity.AnnualMinimumRent__c/12;
        }else{
        updateOpportunity.RentInAdvance__c=0;
        }

        }
        */
        
        //RPP-9733 enhancements NEEL
        if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(newOppRecordTypeName)||Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
            
            if(((updateOpportunity.TECHJVRequired__c && updateOpportunity.TECHJVCompleted__c) || !updateOpportunity.TECHJVRequired__c) && 
               (updateOpportunity.ApprovalStatus__c == constants.FINALAPPR_GRANT || (updateOpportunity.ApprovalStatus__c ==Constants.RSKAPPR_GRANTED&&updateOpportunity.DealAchieved__c)) && (oldOpportunity.ApprovalStatus__c != updateOpportunity.ApprovalStatus__c || oldOpportunity.TECHJVCompleted__c != updateOpportunity.TECHJVCompleted__c)){
               
                   
                   //NEEL 25.03.2019
                   if(String.isEmpty(updateOpportunity.SpecialtyLeaseCase__c)){
                       System.debug('here is stage change 1');
                       updateOpportunity.stageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
                   } else {
                       if(Constants.VARIATION_OF_LEASE.equalsIgnoreCase(updateOpportunity.SpecialityLeaseType__c)){ //Of a Lease
                           if(updateOpportunity.TECHJVCompleted__c || (!updateOpportunity.TECHJVRequired__c && !updateOpportunity.TECHJVCompleted__c)) {
                               updateOpportunity.stageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
                           }
                       } else { // to a Lease
                           if(updateOpportunity.TECHJVCompleted__c || (!updateOpportunity.TECHJVRequired__c && !updateOpportunity.TECHJVCompleted__c)) {
                               updateOpportunity.stageName = Constants.OPPSTAGE_CLOSE_COMPLETED;
                           }
                       }
                   }     
                   
                   /*             if(String.isEmpty(updateOpportunity.SpecialtyLeaseCase__c)){
                    System.debug('here is stage change 1');
                    updateOpportunity.stageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
                    } else if(!String.isEmpty(updateOpportunity.SpecialtyLeaseCase__c) 
                    && Constants.VARIATION_TO_LEASE.equalsIgnoreCase(updateOpportunity.SpecialityLeaseType__c)
                    && updateOpportunity.TECHJVCompleted__c){
                    System.debug('here is stage change 2');
                    updateOpportunity.stageName = Constants.OPPSTAGE_CLOSE_COMPLETED;
                    } else if (!String.isEmpty(updateOpportunity.SpecialtyLeaseCase__c) 
                    && Constants.VARIATION_OF_LEASE.equalsIgnoreCase(updateOpportunity.SpecialityLeaseType__c)
                    && updateOpportunity.TECHJVCompleted__c) {
                    updateOpportunity.stageName = Constants.OPPORTUNITYSTAGE_ISSUE_LEASE;
                    } else if (!String.isEmpty(updateOpportunity.SpecialtyLeaseCase__c) //NEEL 25.03.2019
                    && !updateOpportunity.TECHJVRequired__c 
                    && !updateOpportunity.TECHJVCompleted__c) {
                    updateOpportunity.stageName = Constants.OPPSTAGE_CLOSE_COMPLETED;
                    } */
            }        
            
            if((oldOpportunity.ApprovalStatus__c != updateOpportunity.ApprovalStatus__c) &&   ((updateOpportunity.ApprovalStatus__c == constants.RSKAPPR_GRANTED && updateOpportunity.stageName != constants.OPPORTUNITYSTAGE_ISSUE_LEASE)  || (updateOpportunity.ApprovalStatus__c == constants.INIAPPR_GRANTED))){
                updateOpportunity.stageName = constants.PROPOSE_ACCEPT;
            }
        }
        
        if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
            if((oldOpportunity.ApprovalStatus__c != updateOpportunity.ApprovalStatus__c) &&
               (updateOpportunity.ApprovalStatus__c == constants.STRAPPOVALGRANTED)){
                   updateOpportunity.stageName = constants.PROPOSE_ACCEPT;
               }
        }
        
        // START : YN RPP-4359 6.29.18
        // START : YN RPP-10092 7.23.19
        if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(newOppRecordTypeName)||Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(newOppRecordTypeName)){
            if(updateOpportunity.StageName != oldOpportunity.StageName){
                if(Constants.OPPORTUNITYSTAGE_ISSUE_LEASE.equalsIgnoreCase(updateOpportunity.StageName)){
                    updateOpportunity.BestBet__c = false;
                }
            }
            
            if(updateOpportunity.BestBet__c && spaceIdOpportunityListMap.containsKey(updateOpportunity.Space__c) && spaceIdOpportunityListMap.get(updateOpportunity.Space__c).size() > 0){
                oppTemp = spaceIdOpportunityListMap.get(updateOpportunity.Space__c)[0];
                if(updateOpportunity.Id != oppTemp.Id && oppTemp.BestBet__c){
                    for(Opportunity opp: spaceIdOpportunityListMap.get(updateOpportunity.Space__c)){
                        opp.BestBet__c = false;
                        if(Approval.isLocked(opp.Id)){
                            Approval.unlock(opp.id);
                            LockedOpportunityList.add(opp);
                        }else{
                            opportunityUpdateList.add(opp);
                        }
                    } 
                    //updateOpportunity.addError(Label.ExistingBestBetErrorMessage);            
                }
            }
        }
        // END : YN RPP-10092 7.23.19
        // END : YN RPP-4359 6.29.18
        
        // START : KT RPP-4921 7.17.18
        // RPP-10497 LF modified condition to avoid misfire
        if(opptyIdsForSecurityDeposit.contains(updateOpportunity.Id)) { //SOQL FIX - 2, //SOQL FIX - 4
            updateOpportunity.SecurityDeposit__c = OpportunityBL.updateSecurityDeposit(updateOpportunity, topParentAccountMap, nationalAgreementClauseMap, accountMap, propertyMap, GSTList);
        }
        // END : KT RPP-4921 7.17.18
        
        // START : NEEL RPP-8990
        // START : KT RPP-5548 8.3.18
        /*if(Constants.UNDERSTAND_NEGOTIATE.equalsIgnoreCase(updateOpportunity.StageName)) {
        forecastOppisConfigured = SpaceBL.checkActiveConfigurations(spaceGroupMap.get(updateOpportunity.Space__c), updateOpportunity.Space__c);
        forcastFieldsisChanged = OpportunityBL.checkForecastFieldChanges(updateOpportunity, oldOpportunity, forecastFieldSet);
        if(forecastOppisConfigured && forcastFieldsisChanged) {
        updateOpportunity.addError(Label.SpaceReconfig_ErrorMessage);
        }
        }
        // END : KT RPP-5548 8.3.18
        // END : NEEL RPP-8990
        */
        
        // START : YN RPP-5640 8.10.2018
        if(propIdOppIdOppClauseListMap.containsKey(updateOpportunity.Property__c) && updateOpportunity.Tech_SpaceType__c!=Constants.STOREROOM){
            HighRiskOpportunityClauseUtility.countRCA(updateOpportunity, propIdOppIdOppClauseListMap.get(updateOpportunity.Property__c));
        }else{
            updateOpportunity.NoofRCA__c = 0;   
        }
        // END : YN RPP-5640 8.10.2018
        if(updateOpportunity.StageName != oldOpportunity.StageName&&Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(newOppRecordTypeName)&&updateOpportunity.StageName=='Closed - Completed'){
            if(updateOpportunity.Type == Constants.OPPTY_STAGENAME_NEWRETAILER){
                updateOpportunity.JDESentStatus__c=Constants.OPPO_JDE_STATUS_READY;
            } 
            updateOpportunity.DealAchieved__c=true;            
            if(updateOpportunity.DealAchievedDate__c==null){
                updateOpportunity.DealAchievedDate__c=system.today();
            }
        }
        // Add by chen --- when opportunity is deal achieved, copy the field
        if(updateOpportunity.DealAchieved__c&&updateOpportunity.DealAchieved__c!=oldOpportunity.DealAchieved__c) {
            updateOpportunity.ForecastRent__c = updateOpportunity.AnnualMinimumRent__c;
            updateOpportunity.TotalASRForecastCapital__c = updateOpportunity.TotalForecastCapital__c;
        }
        // START : KT 10.12.2018
        approvalstatusvalues.add(Constants.RM_APPV_REJ);
        //approvalstatusvalues.add(Constants.RISK_APPRV_REJ);
        approvalstatusvalues.add(Constants.INI_APPV_REJ);
        approvalstatusvalues.add(Constants.FINALAPPR_REJ);
        approvalstatusvalues.add(Constants.STRAPPOVALREJ);
        if(updateOpportunity.ApprovalStatus__c != oldOpportunity.ApprovalStatus__c && (approvalstatusvalues.contains(updateOpportunity.ApprovalStatus__c))) {
            chatterPostOppList.add(updateOpportunity);
        }
        // END : KT 10.12.2018
        if(updateOpportunity.ApprovalStatus__c != oldOpportunity.ApprovalStatus__c&&updateOpportunity.ApprovalStatus__c == constants.FINALAPPR_GRANT){
            if(oldOpportunity.DealAchievedDate__c!=null){
                updateOpportunity.DealAchievedDate__c=oldOpportunity.DealAchievedDate__c;
            }
        }
        
        // START: RPP - 10553 LF 6.20.2019
        Boolean oldVirtualVacancy = !Constants.NO.equalsIgnoreCase(oldOpportunity.CurrentLeaseVirtualVacancy__c) && !String.isBlank(oldOpportunity.CurrentLeaseVirtualVacancy__c);
        Boolean newVirtualVacancy = !Constants.NO.equalsIgnoreCase(updateOpportunity.CurrentLeaseVirtualVacancy__c) && !String.isBlank(updateOpportunity.CurrentLeaseVirtualVacancy__c);
        system.debug('oldVirtualVacancy -- ' + oldVirtualVacancy);
        system.debug('newVirtualVacancy -- ' + newVirtualVacancy);
        if (oldVirtualVacancy != newVirtualVacancy) {
            OpportunityBL.virtualVacancyUpdates(updateOpportunity);
            
            Space__c updateSpace = SpaceBL.updateStatusBasedOnVirtualVacancy(oppSpace, updateOpportunity);
            if (updateSpace != null) {
                spaceToUpdateForVirtualVacancyList.add(updateSpace);
            }
            
        } else if (newVirtualVacancy) {
            if (updateOpportunity.ForecastRentCommencementDate__c != null && oldOpportunity.ForecastRentCommencementDate__c != updateOpportunity.ForecastRentCommencementDate__c) {
                updateOpportunity.VirtualVacancyEndDate__c = updateOpportunity.ForecastRentCommencementDate__c.addDays(-1);
            } 
            if (updateOpportunity.ForecastRent__c != null && oldOpportunity.ForecastRent__c != updateOpportunity.ForecastRent__c) {
                updateOpportunity.VirtualVacancyRent__c = updateOpportunity.ForecastRent__c;
            } 
            if (updateOpportunity.ForecastedRentTerminationDate__c != null && oldOpportunity.ForecastedRentTerminationDate__c != updateOpportunity.ForecastedRentTerminationDate__c) {
                updateOpportunity.VirtualVacancyStartDate__c = updateOpportunity.ForecastedRentTerminationDate__c.addDays(1);
            }
        }
        // END: RPP - 10553 LF 6.20.2019          
        
        //Changes on 08_05_19 
        //Opportunity opp1 = new Opportunity();
        //opp1 = [SELECT Id,DealAchieved__c,Opportunity.Space__c,Opportunity.Space__r.CurrentRent__c, Opportunity.Space__r.ReconfiguredCurrentRent__c, Opportunity.Space__r.CurrentSemiGrossRent__c, Opportunity.Space__r.ReconfiguredCurrentRentSemiGross__c FROM Opportunity WHERE Id=:oldOpportunity.Id  ];
        
        Opportunity opp1 = opportunityMapById.containsKey(oldOpportunity.Id) ? opportunityMapById.get(oldOpportunity.Id) : new Opportunity();
        
        if(updateOpportunity.DealAchieved__c  &&  updateOpportunity.DealAchieved__c != oldOpportunity.DealAchieved__c ) {
            Boolean isConfigured = false;
            //Set<Id> forecastOppSpaceIdSet = new Set<Id>();
            //forecastOppSpaceIdSet.add(updateOpportunity.Space__c);
            system.debug('updateOpportunity.Space__c: '+updateOpportunity.Space__c);
            /*Map<Id, List<SpaceGroup__c>> spaceGroupMap = new Map<Id, List<SpaceGroup__c>>(); //SOQL FIX - 14
            system.debug('spaceGroupMap: '+spaceGroupMap);
            //system.debug('forecastOppSpaceIdSet: '+forecastOppSpaceIdSet);
            try{    
                //Map<Id, List<SpaceGroup__c>> spaceGroupMap = new Map<Id, List<SpaceGroup__c>>();
                if(forecastOppSpaceIdSetTemp != null && forecastOppSpaceIdSetTemp.size() > 0){
                    for(SpaceGroup__c temp :[SELECT Id, ParentSpace__c, Active__c, Type__c, EffectiveDate__c FROM SpaceGroup__c WHERE ParentSpace__c IN :forecastOppSpaceIdSetTemp]) {
                        if(spaceGroupMap.containsKey(temp.ParentSpace__c)) {
                            spaceGroupMap.get(temp.ParentSpace__c).add(temp);
                        } else {
                            spaceGroupMap.put(temp.ParentSpace__c, new List<SpaceGroup__c>{temp});
                        }
                    }
                }   
                //spaceGroupMap  = DatabaseSOQLBank.getSpaceGroupMap(forecastOppSpaceIdSet);
            } catch(Exception e) {
                spaceGroupMap  = null;
            }*/ //SOQL FIX - 14
            
            if(spaceGroupMap.containsKey(updateOpportunity.Space__c)) {
                //Boolean isConfigured = false;
                List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
                spaceGroupList = spaceGroupMap.get(updateOpportunity.Space__c);
                if(spaceGroupList != null && spaceGroupList.size() > 0) {
                    for(SpaceGroup__c spaceGroupRec :spaceGroupList) {
                        if(spaceGroupRec.Active__c && spaceGroupRec.ParentSpace__c == updateOpportunity.Space__c) {
                            isConfigured = true;
                        }
                    }
                }    
                //isConfigured = SpaceBL.checkActiveConfigurations(spaceGroupMap.get(oldOpportunity.Space__r.Id), oldOpportunity.Space__r.Id);
            }     
            system.debug('isConfigured: '+isConfigured);
            if(isConfigured) {    
                
                if(opp1.Space__r.CurrentRent__c != Null && opp1.Space__r.CurrentRent__c > 0) {
                    updateOpportunity.ComparativeCurrentNetRent__c = opp1.Space__r.CurrentRent__c;
                }
                else if(opp1.Space__r.ReconfiguredCurrentRent__c != Null && opp1.Space__r.ReconfiguredCurrentRent__c > 0 ) { 
                    updateOpportunity.ComparativeCurrentNetRent__c = opp1.Space__r.ReconfiguredCurrentRent__c;
                }
                if(opp1.Space__r.CurrentSemiGrossRent__c != Null && opp1.Space__r.CurrentSemiGrossRent__c > 0){
                    updateOpportunity.ComparativeCurrentSemiGrossRent__c = opp1.Space__r.CurrentSemiGrossRent__c;
                }
                else if(opp1.Space__r.ReconfiguredCurrentRentSemiGross__c != Null && opp1.Space__r.ReconfiguredCurrentRentSemiGross__c > 0 ) {
                    updateOpportunity.ComparativeCurrentSemiGrossRent__c =  opp1.Space__r.ReconfiguredCurrentRentSemiGross__c;
                }
            }
        }
        //Changes on 08_05_19
    }
    
    public void beforeDelete(SObject so)
    {
    }
    
    public void afterInsert(SObject so){
        String oppRecordTypeName;
        Account oppAccount;
        Space__c oppSpace;
        Property__c oppProperty;
        PrecedentClause__c nationalAgreement;
        Space__c opportunitySpace  = new Space__c();
        Opportunity newOpportunity  = (Opportunity)so;
        Map<String, List<OpportunityClause__c>> subTypeOppClauseListMap = new Map<String, List<OpportunityClause__c>>();
        
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        oppLineItemWrapper.opportunityRecord = newOpportunity;
        oppLineItemWrapper.opportunityRecordtypeName = oppRecordTypeById.get(newOpportunity.RecordTypeId).getName();
        oppLineItemWrapper.propertyMap = propertyMap;
        oppLineItemWrapper.nationalAgreementClauseMap = nationalAgreementClauseMap;
        oppLineItemWrapper.topParentAccountMap = topParentAccountMap;
        oppLineItemWrapper.productNameandPricebookEntryMap = productNameandPricebookEntryMap;
        
        if(nationalAgreementByIdMap != null && nationalAgreementByIdMap.containsKey(newOpportunity.NationalAgreement__c)){
            nationalAgreement = nationalAgreementByIdMap.get(newOpportunity.NationalAgreement__c);
        }
        
        if(accountMap != null && accountMap.containsKey(newOpportunity.AccountId)){
            oppAccount = accountMap.get(newOpportunity.AccountId);
        }
        
        if(oppRecordTypeById.containsKey(newOpportunity.RecordTypeId)){
            oppRecordTypeName = oppRecordTypeById.get(newOpportunity.RecordTypeId).getName();
        }
        
        if(propertyMap.containsKey(newOpportunity.Property__c)){
            oppProperty = propertyMap.get(newOpportunity.Property__c);
        }
        
        // START : YN RPP-5553 10.30.2018
        if(oppSpaceMap != null && oppSpaceMap.containsKey(newOpportunity.Space__c)){
            oppSpace = oppSpaceMap.get(newOpportunity.Space__c);
        }
        // END : YN RPP-5553 10.30.2018
        
        //START -- RPP-2536 Kyle Tan 5/4/2018
        if(topParentAccountMap.containsKey(newOpportunity.AccountId)) {
            if(accountPrecedentClauseMap.containsKey(topParentAccountMap.get(newOpportunity.AccountId))) {
                for(PrecedentClause__c precedentClauseRecord : accountPrecedentClauseMap.get(topParentAccountMap.get(newOpportunity.AccountId))) {
                    opportunityClauseList.add(OpportunityBL.createOpportunityClause(newOpportunity, precedentClauseRecord, opportunityClauseRecordTypeMapByName.get(Constants.PRECEDENT_CLAUSE).getRecordTypeId()));
                }
            }
        }
        //END -- RPP-2536 Kyle Tan 5/4/2018
        
        // START : KT RPP-4889 7.10.18
        // START : KT RPP-3048 5.29.18
        // 
        system.debug('Opp Trig wrap map ' + oppLineItemWrapper.productNameandPricebookEntryMap);
        if(!newOpportunity.TechByPassOnClone__c){
            opportunityLineItemList.addAll(OpportunityBL.createReviewsforOpportunity(opptyWithRent, oppLineItemWrapper, Constants.PRODUCT_RENT_REVIEW, priceBookRentRevProdIdMap.get(newOpportunity.Pricebook2Id))); // LF RPP-10151 5.8.2019
			system.debug('opportunityLineItemList' + opportunityLineItemList);

        }
        
        if(opportunityRecordTypeMapByName.containsKey(Constants.OPP_STORE_ROOM_LEASING) && newOpportunity.RecordTypeId != opportunityRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId()) {
            opportunityLineItemList.addAll(OpportunityBL.createReviewsforOpportunity(opptyWithRent, oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, priceBookPromoRevProdIdMap.get(newOpportunity.Pricebook2Id))); // LF RPP-10151 5.8.2019
			system.debug('opportunityLineItemList' + opportunityLineItemList);

        }
        // END : KT RPP-4321 6.26.18 
        // END : KT RPP-3048 5.29.18
        // END : KT RPP-4889 7.10.18
        
        // START : YN RPP-4310 6.22.18
        // START : YN RPP-3275 5.30.18
        if(taskTemplateMap != null){
            newTaskForInsertList.addAll(
                TaskUtility.createOpportunityTask(
                    newOpportunity,
                    null,
                    oppRecordTypeName,
                    taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                    taskTemplateMap.values(),
                    taskOwnerWrap,
                    oppAccount,
                    oppProperty,
                    true,
                    oppSpace
                )
            );
        }
        // END : YN RPP-3275 5.30.18
        // END : YN RPP-4310 6.22.18
        
        // START : KT RPP-4921 7.20.18
        oppContactRoleList.addAll(OpportunityBL.createOppContactRoles(newOpportunity, affiliationsMap));
        // END : KT RPP-4921 7.20.18
        
        // START : YN RPP-6061 9.12.2018
        if(oppSpaceMap != null && oppSpaceMap.containsKey(newOpportunity.Space__c)){
            oppSpace = oppSpaceMap.get(newOpportunity.Space__c);
        }
        
        if(oppIdSubTypeOppClauseListMap.containsKey(newOpportunity.Id)){
            subTypeOppClauseListMap = oppIdSubTypeOppClauseListMap.get(newOpportunity.Id);
        }
        
        system.debug('oppIdSubTypeOppClauseListMap : ' + oppIdSubTypeOppClauseListMap);
        system.debug('subTypeClauseLibraryListMap : ' + subTypeClauseLibraryListMap);
        
        if(!Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(oppRecordTypeName)&&!newOpportunity.TechByPassOnClone__c){
            clauseLibSubTypeToCreateMap = OpportunityBL.getClauseSubTypeToCreateDelete(newOpportunity, null, oppSpace, subTypeOppClauseListMap.keySet(), oppRCAMetadataList, nationalAgreement);
            
            system.debug('clauseLibSubTypeToCreateMap : ' + clauseLibSubTypeToCreateMap);
            system.debug('oppRCAMetadataList : ' + oppRCAMetadataList);
            
            if(opportunityClauseRecordTypeMapByName.containsKey('Leasing Clause') && clauseLibSubTypeToCreateMap.containsKey(Constants.CREATE)){
                for(String subType : clauseLibSubTypeToCreateMap.get(Constants.CREATE)){
                    if(subTypeClauseLibraryListMap.containsKey(subType)){
                        newOppClauseList.addAll(
                            OpportunityBL.createOpportunityClause(
                                opportunityClauseRecordTypeMapByName.get('Leasing Clause').getRecordTypeId(),
                                newOpportunity,
                                subTypeClauseLibraryListMap.get(subType)
                            )
                        );
                    }
                }
            } 
            
            if(clauseLibSubTypeToCreateMap.containsKey(Constants.REMOVE)){
                for(String subType : clauseLibSubTypeToCreateMap.get(Constants.REMOVE)){
                    if(subTypeOppClauseListMap.containsKey(subType)){
                        oppClauseToDeleteList.addAll(
                            subTypeOppClauseListMap.get(subType)
                        );
                    }
                }
            }
        }
        // END : YN RPP-6061 9.12.2018
    }
    
    public void afterUpdate(SObject oldSo, SObject so){
        String oppRecordTypeName;
        Opportunity newOpportunity  = (Opportunity)so;
        Opportunity oldOpportunity  = (Opportunity)oldSo;
        Account oppAccount;
        Space__c oppSpace;
        Property__c oppProperty;
        PrecedentClause__c nationalAgreement;
        Space__c opportunitySpace  = new Space__c();
        
        //if(Approval.isLocked(newOpportunity.Id))
            //Approval.unlock(newOpportunity.Id);
        
        Map<String, List<OpportunityClause__c>> subTypeOppClauseListMap = new Map<String, List<OpportunityClause__c>>();
        
        OpportunityBL.OppLineItemWrapper oppLineItemWrapper = new OpportunityBL.OppLineItemWrapper();
        
        oppLineItemWrapper.opportunityRecord = newOpportunity;
        oppLineItemWrapper.oldOpportunityRecord = oldOpportunity; //RPP - 10674
        
        if(oppRecordTypeById.containsKey(newOpportunity.RecordTypeId)){
            oppLineItemWrapper.opportunityRecordtypeName = oppRecordTypeById.get(newOpportunity.RecordTypeId).getName(); 
        }
        system.debug('propertyMapAfterUpdate--------'+propertyMap);
        oppLineItemWrapper.propertyMap = propertyMap;
        oppLineItemWrapper.nationalAgreementClauseMap = nationalAgreementClauseMap;
        oppLineItemWrapper.topParentAccountMap = topParentAccountMap;
        oppLineItemWrapper.productNameandPricebookEntryMap = productNameandPricebookEntryMap;
        
        if(nationalAgreementByIdMap != null && nationalAgreementByIdMap.containsKey(newOpportunity.NationalAgreement__c)){
            nationalAgreement = nationalAgreementByIdMap.get(newOpportunity.NationalAgreement__c);
        }
        
        if(accountMap != null && accountMap.containsKey(newOpportunity.AccountId)){
            oppAccount = accountMap.get(newOpportunity.AccountId);
        }
        
        if(oppRecordTypeById.containsKey(newOpportunity.RecordTypeId)){
            oppRecordTypeName = oppRecordTypeById.get(newOpportunity.RecordTypeId).getName();
        }
        
        if(propertyMap.containsKey(newOpportunity.Property__c)){
            oppProperty = propertyMap.get(newOpportunity.Property__c);
        }
        
        // START : YN RPP-5553 10.30.2018
        if(oppSpaceMap != null && oppSpaceMap.containsKey(newOpportunity.Space__c)){
            oppSpace = oppSpaceMap.get(newOpportunity.Space__c);
        }
        // END : YN RPP-5553 10.30.2018
        
        // START : YN RPP-4310 6.22.18
        // START : YN RPP-3275 5.30.18
        Boolean isStageChange = false;
        if(taskTemplateMap != null && newOpportunity.StageName != oldOpportunity.StageName 
           || (newOpportunity.JDESentStatus__c != oldOpportunity.JDESentStatus__c
               && Constants.MANUAL.equalsIgnoreCase(newOpportunity.JDESentStatus__c))
           || (newOpportunity.ApprovalStatus__c != oldOpportunity.ApprovalStatus__c 
               && Constants.FINAL_APPROVAL_GRANTED.equalsIgnoreCase(newOpportunity.ApprovalStatus__c))){
                   
                   if(newOpportunity.StageName != oldOpportunity.StageName){
                       isStageChange = true;
                   }
                   
                   system.debug('taskTemplateMap.values() : ' + taskTemplateMap.values());
                   
                   newTaskForInsertList.addAll(
                       TaskUtility.createOpportunityTask(
                           newOpportunity,
                           oldOpportunity,
                           oppRecordTypeName,
                           taskRecordTypeMap.get(Constants.TASK_AUTOMATIC).getRecordTypeId(),
                           taskTemplateMap.values(),
                           taskOwnerWrap,
                           oppAccount,
                           oppProperty,
                           isStageChange,
                           oppSpace
                       )
                   );
                   
                   system.debug('newTaskForInsertList : ' + newTaskForInsertList);
                   system.debug('newOpportunity.JDESentStatus__c : ' + newOpportunity.JDESentStatus__c);
               }
        // END : YN RPP-3275 5.30.18
        // END : YN RPP-4310 6.22.18
        
        // START : KT RPP-4889 7.10.18
        system.debug('newOpportunity.PromoLevyIncluded__c---------'+newOpportunity.PromoLevyIncluded__c);
        system.debug('oldOpportunity.PromoLevyIncluded__c---------'+oldOpportunity.PromoLevyIncluded__c);
        if(newOpportunity.ProposedStartDate__c != oldOpportunity.ProposedStartDate__c 
            || newOpportunity.TermYr__c != oldOpportunity.TermYr__c 
            || newOpportunity.TermMonths__c != oldOpportunity.TermMonths__c 
            || newOpportunity.TermDays__c != oldOpportunity.TermDays__c 
            || newOpportunity.AnnualMinimumRent__c != oldOpportunity.AnnualMinimumRent__c
            || (newOpportunity.PromoLevyIncluded__c != oldOpportunity.PromoLevyIncluded__c)){
            
            List<OpportunityLineItem> existingOLI = new List<OpportunityLineItem>();
            if(flexiOpportunityLineItemMap.containsKey(newOpportunity.Id)) {
                existingOLI = flexiOpportunityLineItemMap.get(newOpportunity.Id);
            }
            // RPP - 10674 Start
            // If Opportunity record type is "Storeroom Leasing". Delete old rent and promos and insert new (Old functionality)
            // else update existing records and insert/delete if term increases or decreases.
            if(opportunityRecordTypeMapByName.containsKey(Constants.OPP_STORE_ROOM_LEASING) 
                && newOpportunity.RecordTypeId == opportunityRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId()) {

                opportunityLineItemtoDelete.addAll(existingOLI);

                opportunityLineItemList.addAll(OpportunityBL.createReviewsforOpportunity(opptyWithRent, oppLineItemWrapper, Constants.PRODUCT_RENT_REVIEW, priceBookRentRevProdIdMap.get(newOpportunity.Pricebook2Id))); // LF RPP-10151 5.8.2019
                           system.debug('opportunityLineItemList' + opportunityLineItemList);

                    if(newOpportunity.PromoLevyIncluded__c=='Yes') {
                    opportunityLineItemList.addAll(OpportunityBL.createReviewsforOpportunity(opptyWithRent, oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, priceBookPromoRevProdIdMap.get(newOpportunity.Pricebook2Id))); // LF RPP-10151 5.8.2019
                	            system.debug('opportunityLineItemList' + opportunityLineItemList);

                }
            }else{
            
                Integer years = newOpportunity.TermYr__c != null ? newOpportunity.TermYr__c.intValue() : 0;
                Integer months = newOpportunity.TermMonths__c != null ? newOpportunity.TermMonths__c.intValue() : 0;
                Integer days = newOpportunity.TermDays__c != null ? newOpportunity.TermDays__c.intValue() : 0;

                String oppPropName; 
                if(opportunityMapById.containsKey(newOpportunity.Id)){
                    oppPropName = opportunityMapById.get(newOpportunity.Id).Property__r.Country__c;
                }

                Id oppRecordTypeId = newOpportunity.RecordTypeId;
                Id storeRoomRecordTypeId = opportunityRecordTypeMapByName.get(Constants.OPP_STORE_ROOM_LEASING).getRecordTypeId(); 

                Integer counter = OpportunityBL.getCounter(years, months, days, oppPropName, storeRoomRecordTypeId, newOpportunity.RecordTypeId);
                Integer totalCount = oldOpportunity.PromoLevyIncluded__c == 'Yes' ? (counter * 2) : counter;
                system.debug('existingOLI.size()--------------'+existingOLI.size());
                List<OpportunityLineItem> reviewOLI = OpportunityBL.getFilteredOpptyLineItems(existingOLI,Constants.PRODUCT_RENT_REVIEW);
                List<OpportunityLineItem> promoOLI = OpportunityBL.getFilteredOpptyLineItems(existingOLI,Constants.PRODUCT_PROMO_REVIEW);

                
                if(totalCount <= existingOLI.size()){
                    system.debug('Inside counter if');
                    Integer startCount = (counter - 1) < 0 ? 0 : (counter - 1);

                    for(Integer i = startCount; i < reviewOLI.size(); i++){
                        opportunityLineItemtoDelete.add(reviewOLI[i]);
                    }

                    for(Integer i = startCount; i < promoOLI.size(); i++){
                        opportunityLineItemtoDelete.add(promoOLI[i]);
                    }
                }

                opportunityLineItemList.addAll(OpportunityBL.createUpdateReviewsforOpportunity(opptyWithRent.get(newOpportunity.Id), oppLineItemWrapper, Constants.PRODUCT_RENT_REVIEW, priceBookRentRevProdIdMap.get(newOpportunity.Pricebook2Id),existingOLI)); // LF RPP-10151 5.8.2019
                system.debug('opportunityLineItemList' + opportunityLineItemList);
                if(newOpportunity.PromoLevyIncluded__c=='Yes') {
                    opportunityLineItemList.addAll(OpportunityBL.createUpdateReviewsforOpportunity(opptyWithRent.get(newOpportunity.Id), oppLineItemWrapper, Constants.PRODUCT_PROMO_REVIEW, priceBookPromoRevProdIdMap.get(newOpportunity.Pricebook2Id),existingOLI)); // LF RPP-10151 5.8.2019
               		 system.debug('opportunityLineItemList' + opportunityLineItemList);
                }else{
                    opportunityLineItemtoDelete.addAll(promoOLI);
                }
            }
            // RPP - 10674 End
            
            system.debug('opportunityLineItemtoDelete--------' + opportunityLineItemtoDelete);
            system.debug('oppLineItemWrapper' + oppLineItemWrapper);            
            system.debug('opportunityLineItemList' + opportunityLineItemList);
        }
        // END : KT RPP-4889 7.10.18
        
        //START -- SG RPP-3542 6/5/2018
        
        if ((newOpportunity.StageName != oldOpportunity.StageName)&&
            (newOpportunity.StageName == CONSTANTS.OPPTY_STAGENAME_ISSUE_LEASE ||
             newOpportunity.StageName == CONSTANTS.OPPTY_STAGENAME_EXECUTE_LEASE ||
             newOpportunity.StageName == CONSTANTS.OPPTY_STAGENAME_REGISTER_LEASE)){
                 opportunityIdSetforLock.add(newOpportunity.Id);
             }  
        //END -- SG RPP-3542 6/5/2018
        
        // START : YN Outgoings 6.14.18
        if(oppoIdOpportunityLineItemMap != null && oppoIdOpportunityLineItemMap.containsKey(newOpportunity.Id)){
            if(newOpportunity.Space__c != oldOpportunity.Space__c || newOpportunity.DealType__c != oldOpportunity.DealType__c){
                for(OpportunityLineItem oppLineItem : oppoIdOpportunityLineItemMap.get(newOpportunity.Id)){
                    if(Constants.OTG.equalsIgnoreCase(oppLineItem.ProductCode)){
                        opportunityLineItemtoDelete.add(oppLineItem);
                    }
                }
            }
        }
        // END : YN Outgoings 6.14.18
        Map<Id,Opportunity> opportunitymapforclause=new Map<Id,Opportunity>();
        if((oldOpportunity.ApprovalStatus__c != newOpportunity.ApprovalStatus__c) &&
           (newOpportunity.ApprovalStatus__c == constants.RMRISK_APPRGRANTED || newOpportunity.ApprovalStatus__c == constants.RMAPPR_GRANTED)){
               opportunitymapforclause.put(newOpportunity.id,newOpportunity);
           }
        // START : KT RPP-4771 7.14.18
        // END : KT RPP-4771 7.14.18
        
        // START : KT RPP-4771 7.13.18
        //opportunityLineItemtoUpdate.addAll(OpportunityBL.updateOppLineItemDate(newOpportunity, oldOpportunity, opportunityLineItemMap));
        // END : KT RPP-4771 7.13.18
        
        // START : YN RPP-6061 9.12.2018
        if(oppSpaceMap != null && oppSpaceMap.containsKey(newOpportunity.Space__c)){
            oppSpace = oppSpaceMap.get(newOpportunity.Space__c);
        }
        
        if(oppIdSubTypeOppClauseListMap.containsKey(newOpportunity.Id)){
            subTypeOppClauseListMap = oppIdSubTypeOppClauseListMap.get(newOpportunity.Id);
        }
        
        if(!Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(oppRecordTypeName)&&!newOpportunity.TechByPassOnClone__c){
            clauseLibSubTypeToCreateMap = OpportunityBL.getClauseSubTypeToCreateDelete(newOpportunity, oldOpportunity, oppSpace, subTypeOppClauseListMap.keySet(), oppRCAMetadataList, nationalAgreement);
            System.debug('subTypeClauseLibraryListMap '+subTypeClauseLibraryListMap);
            System.debug('clauseLibSubTypeToCreateMap '+clauseLibSubTypeToCreateMap);
            
            if(opportunityClauseRecordTypeMapByName.containsKey('Leasing Clause')&&clauseLibSubTypeToCreateMap.containsKey(Constants.CREATE)){
                for(String subType : clauseLibSubTypeToCreateMap.get(Constants.CREATE)){
                    if(subTypeClauseLibraryListMap.containsKey(subType)){
                        newOppClauseList.addAll(
                            OpportunityBL.createOpportunityClause(
                                opportunityClauseRecordTypeMapByName.get('Leasing Clause').getRecordTypeId(),
                                newOpportunity,
                                subTypeClauseLibraryListMap.get(subType)
                            )
                        );
                    }
                }
            }
            
            if(clauseLibSubTypeToCreateMap.containsKey(Constants.REMOVE)){
                for(String subType : clauseLibSubTypeToCreateMap.get(Constants.REMOVE)){
                    if(subTypeOppClauseListMap.containsKey(subType)){
                        oppClauseToDeleteList.addAll(
                            subTypeOppClauseListMap.get(subType)
                        );
                    }
                }
            }
        }
        // END : YN RPP-6061 9.12.2018
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    public void andFinally()
    {
        TriggerHandler.handlerInstances.put('OpportunityTriggerHandler',this);
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityTriggerHandler.class.getName());
        
        if(!histories.isEmpty()&&histories.size()>0){
            try{
                Database.insert(histories, false);
                system.debug('histories - ' + histories);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        
        if(opptyReversalTask.size() > 0)
            Database.insert(opptyReversalTask, FALSE);
        
        // START : YN RPP-10092 7.23.19
        if(opportunityUpdateList.size() > 0){		
            Database.update(opportunityUpdateList, FALSE);		
        }		
        
        if(LockedOpportunityList.size() > 0){		
            Database.update(LockedOpportunityList, FALSE);		
            //Approval.lock(LockedOpportunityList, false);		
        }
        // END : YN RPP-10092 7.23.19
        
        //START -- RPP-2536 Kyle Tan 5/4/2018
        if(opportunityClauseList.size() > 0) {
            try{
                database.insert(opportunityClauseList, false);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        System.debug('RENTREVIEWS: '+opportunityLineItemList);
        if(opportunityLineItemList.size() > 0) {
            try{
                database.upsert(opportunityLineItemList); // RPP - 10674 - Changed from update to upsert
                System.debug('list product' +opportunityLineItemList);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        
        if(opportunityLineItemtoDelete.size() > 0) {
            try{
                database.delete(new List<OpportunityLineItem>(opportunityLineItemtoDelete)); // RPP - 10674
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        //END -- RPP-2536 Kyle Tan 5/4/2018
        
        //START -- RPP-2762 Bry Gorospe 5/8/2018
        OutgoingsRefreshController.OppLineItemUpdatesWrapper oppLineItemUpdateWrap
            = new OutgoingsRefreshController.OppLineItemUpdatesWrapper();
        List<OpportunityLineItem> oppProductTempList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> refreshOppLineItemList = new List<OpportunityLineItem>();
        Set<String> stageNameSet = new Set<String>{
            'Understand & Negotiate',
                'Approve',
                'Propose & Accept'
                };
                    
                    Boolean isSuccess = false;
        if(opportunityProductList != null && opportunityProductList.size() > 0) {
            Opportunity newOpp;
            Opportunity oldOpp;
            
            if(Trigger.isUpdate || Trigger.isInsert){
                for(OpportunityLineItem oppLine : opportunityProductList){
                    newOpp = (Opportunity) Trigger.newMap.get(oppLine.OpportunityId);
                    
                    if(Trigger.isUpdate){
                        oldOpp = (Opportunity) Trigger.oldMap.get(oppLine.OpportunityId);
                    }
                    
                    if(Trigger.isInsert || (Trigger.isUpdate && (newOpp.Space__c != oldOpp.Space__c || newOpp.DealType__c != oldOpp.DealType__c)) && !newOpp.TechByPassOnClone__c){
                        oppProductTempList.add(oppLine);
                    } else if(newOpp.ProposedRentCommencementDate__c != oldOpp.ProposedRentCommencementDate__c 
                              && stageNameSet.contains(newOpp.StageName) && !newOpp.TechByPassOnClone__c && !newOpp.DealAchieved__c){
                                  refreshOppLineItemList.add(oppLine);
                              }
                }
            }
            
            oppLineItemUpdateWrap = OutgoingsRefreshController.filterOppLineItemForRefresh((List<Opportunity>) Trigger.new, refreshOppLineItemList);
            
            if(oppLineItemUpdateWrap.oppLineItemForInsertList != null){
                oppProductTempList.addAll(oppLineItemUpdateWrap.oppLineItemForInsertList);
            }
            
            Integer counter = 0;
            List<Database.SaveResult> sResultList;
            Map<String, OpportunityLineItem> oppLineItemForDeleteMap = new Map<String, OpportunityLineItem>();
            
            for(OpportunityLineItem oppLine : oppLineItemUpdateWrap.oppLineItemForDeleteList){
                oppLineItemForDeleteMap.put(oppLine.Name, oppLine);
            }
            
            sResultList = Database.insert(oppProductTempList, false);
            
            for(Database.SaveResult sResult : sResultList){
                if(!sResult.isSuccess()){
                    errorHandler.createError(sResult, null);
                    
                    if(oppLineItemForDeleteMap.containsKey(oppProductTempList[counter].Name)){
                        oppLineItemForDeleteMap.remove(oppProductTempList[counter].Name);
                    }
                } else {
                    isSuccess = true;
                }
                counter++;
            }
            
            oppLineItemUpdateWrap.oppLineItemForDeleteList = oppLineItemForDeleteMap.values();
            
            if(isSuccess){
                try{
                    database.delete(oppLineItemUpdateWrap.oppLineItemForDeleteList);
                    isSuccess = true;
                } catch(Exception e){
                    isSuccess = false;
                    errorHandler.createError(e);
                }
            }
        }
        //END -- RPP-2762 Bry Gorospe 5/8/2018
        // START : YN RPP-3275 5.30.18
        if(newTaskForInsertList != null && newTaskForInsertList.size() > 0){
            try{
                Database.insert(newTaskForInsertList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : YN RPP-3275 5.30.18
        
        // START : SG RPP-3542 6/5/2018 
        if(opportunityIdSetforLock != null && opportunityIdSetforLock.size() > 0){
            try{
                List<Id> forlockIdList=new List<Id>();
                forlockIdList.addAll(opportunityIdSetforLock);
                Approval.lock(forlockIdList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : SG RPP-3542 6/5/2018 
        //Start RPP-4722 - attached lease plan
        if(contentDocumentLinkList.size()>0&&!contentDocumentLinkList.isEmpty()){
            try{
                Database.insert(contentDocumentLinkList,false);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END RPP-4722 - attached lease plan
        
        // Start event sent update
        List<OpportunityEvent__e> successfullpublishOppo=new List<OpportunityEvent__e>();
        if (oppoEventsToPublish.size() > 0) {
            System.debug('oppoEventsToPublish === '+oppoEventsToPublish);
            List<Database.SaveResult> resultsOppo = EventBus.publish(oppoEventsToPublish);
            for(integer i = 0; i < resultsOppo.size(); i++){
                System.debug('resultsOppo'+ i +' === '+resultsOppo[i]);
                if(resultsOppo[i].isSuccess()){
                    successfullpublishOppo.add(oppoEventsToPublish[i]);
                }
            }
            OpportunityBL.updateOppoWhenOppoEventSentSuccess(successfullpublishOppo);
        }
        // End event sent update
        
        if(spaceToUpdateList != null && spaceToUpdateList.size() > 0){
            try{
                Database.update(spaceToUpdateList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        // START : RPP - 10553 LF 6.20.2019
        if(spaceToUpdateForVirtualVacancyList != null && spaceToUpdateForVirtualVacancyList.size() > 0){
            try{
                Database.update(spaceToUpdateForVirtualVacancyList);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : RPP - 10553 LF 6.20.2019
        
        // START : KT RPP-4771 7.13.18
        /*if(opportunityLineItemtoUpdate != null && opportunityLineItemtoUpdate.size() > 0) {
        try{
        database.update(opportunityLineItemtoUpdate);
        } catch (Exception e) {
        errorHandler.createError(e);
        }
        }*/
        // END : KT RPP-4771 7.13.18
        
        // START : YN RPP-4948 7.17.2018
        if(spaceGroupList != null && spaceGroupList.size() > 0){
            try{
                Database.update(spaceGroupList);
            } catch (Exception e) {
                errorHandler.createError(e);
            }
        }
        // END : YN RPP-4948 7.17.2018
        
        // START : KT RPP-4921 7.20.2018
        if(oppContactRoleList != null && oppContactRoleList.size() > 0){
            try{
                database.insert(oppContactRoleList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : KT RPP-4921 7.20.2018
        
        // START : RPP-6061 YN 9.12.2018
        if(newOppClauseList != null && newOppClauseList.size() > 0){
            System.debug('newOppClauseList: '+newOppClauseList);
            try{
                database.insert(newOppClauseList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        
        if(oppClauseToDeleteList != null && oppClauseToDeleteList.size() > 0){
            System.debug('oppClauseToDeleteList: ' + oppClauseToDeleteList);
            try{
                database.delete(oppClauseToDeleteList);
            }catch(Exception e){
                errorHandler.createError(e);
            }
        }
        // END : RPP-6061 YN 9.12.2018
        // START : KT 10.12.2018
        if(chatterPostOppList != null && chatterPostOppList.size() > 0) {
            try{
                OpportunityChatterNotificationInvocable.getchatternotificationdataforTrigger(chatterPostOppList);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        // END : KT 10.12.2018
        errorHandler.save();
    }
}