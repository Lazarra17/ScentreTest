public class CaseBL {
    private static Map<String, Schema.RecordTypeInfo> casetRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.OBJECT_CASE);
    
    //RPP-11090
    public static set<Id> parentCovidCaseIds = new set<Id>();
    
    public class caseApproversWrapper{
        public Id userId {get;set;}
        public String Role {get;set;}
        public Id Id {get;set;}
        public Id PropId {get;set;}
    }
    //MDC  6.11.18
    //To get the property team members user ID to Case fields for reference.
    public static List<caseApproversWrapper> getApprovers(Set<Id> propertyIDs) {
        List<caseApproversWrapper> caseApproverWrapperLst = new List<caseApproversWrapper>();
        Set<String> rolesSet = new Set<String>{constants.TEAM_ROLE_FINANCE,constants.TEAM_ROLE_ACCREVPAYABLES,constants.TEAM_ROLE_GMLEASING,constants.TEAM_ROLE_REGMGR,
            constants.TEAM_ROLE_TENCOORD,constants.TEAM_ROLE_DIROFLEASE,constants.TEAM_ROLE_COMMRETMGR,constants.TEAM_ROLE_COMMPRPMGR,constants.TEAM_ROLE_REGLEAMGR,
            constants.TEAM_ROLE_REGMGRRETADM, Constants.TEAM_ROLE_REVASSU_ADMIN, Constants.TEAM_ROLE_LEAS_EXEC, Constants.TEAM_ROLE_CXMNG};
                
                for(PropertyTeam__c propTeam : [Select TeamMember__c,property__c,id,role__c from PropertyTeam__c where property__c in :propertyIDs AND TeamMember__c != null AND Active__c=true AND TeamMember__r.IsActive=true]){  
                    //if(rolesSet.contains(propTeam.role__c)){
                    caseApproversWrapper caseApprover = new caseApproversWrapper();
                    caseApprover.Role = propTeam.role__c;
                    caseApprover.userId = propTeam.TeamMember__c;
                    caseApprover.Id = propTeam.id;
                    caseApprover.PropId = propTeam.property__c;
                    caseApproverWrapperLst.add(caseApprover);
                    //}
                }
        return caseApproverWrapperLst;
    }           
    //MDC  6.11.18
    //To get the property team members user ID to Case fields for reference.
    public static String getRoleId(List<Id> contractIDLst,String roleName) {
        List<String> returnedStr = new List<String>();
        String approverId = '';
        Map<Id,String> propertyIdSpaceTypeMap = new Map<Id,String>();
        for(Contract__c contractRec : [Select Id, Space__c, Space__r.Type__c, Space__r.Property__c from contract__c where id in : contractIDLst]){
            
            if(contractRec.Space__c != null && contractRec.Space__r.Type__c != null && contractRec.Space__r.Property__c != null){
                propertyIdSpaceTypeMap.put(contractRec.Space__r.Property__c,contractRec.Space__r.Type__c);
            }
        }
        if(propertyIdSpaceTypeMap.keySet().size()>0){
            for (caseApproversWrapper caseApproversWrapp : getApprovers(propertyIdSpaceTypeMap.keySet())){
                System.debug(' **ROLE** '+caseApproversWrapp.Role);
                if(caseApproversWrapp.Role == roleName){
                    approverId = ''+caseApproversWrapp.userId;
                    break;
                }
            }
        }
        System.debug(' **FINAL ROLE ID** '+approverId);
        return approverId;
    }   
    public static List<Case> CreateInspectionforContract(List<Contract__c> contractList){
        List<Case> caseListtoCreate=new List<Case>();
        if(contractList.size()>0&&!contractList.isEmpty()){
            Set<Id> propertyIdsSet=new Set<Id>();
            Set<Id> accountIdsSet=new Set<Id>();
            for(Contract__c contractRecord: contractList){
                propertyIdsSet.add(contractRecord.Property__c);
                accountIdsSet.add(contractRecord.Account__c);
                accountIdsSet.add(contractRecord.Account__r.ParentId);
            }
            Map<String,AccountTeamMember> accountteamMap=new Map<String,AccountTeamMember>();
            Map<String,PropertyTeam__c> rolepropertyTeamMap=new Map<String,PropertyTeam__c>();
            for(AccountTeamMember memberRecod: [Select id,TeamMemberRole,UserId from AccountTeamMember where AccountId IN :accountIdsSet and TeamMemberRole=:Constants.TEAM_ROLE_RDAM AND Account.RecordType.Name=:Constants.GROUP_LEVEL]){
                accountteamMap.put(memberRecod.TeamMemberRole,memberRecod);
            }
            for(PropertyTeam__c propertyteam: [Select id,Role__c,TeamMember__c from PropertyTeam__c where Property__c IN: propertyIdsSet AND TeamMember__r.IsActive=true AND Active__c=true AND Role__c=:Constants.TEAM_ROLE_RDM]){
                rolepropertyTeamMap.put(propertyteam.Role__c,propertyteam);
            }
            for(Contract__c contractRecord: contractList){
                Case newCaseRecord=new Case();
                newCaseRecord.DueDate__c=System.Today().addDays(14);
                newCaseRecord.RecordTypeId=casetRecordTypeMapByName.get(Constants.INSPECTION_REPORT).getRecordTypeId();
                newCaseRecord.AccountId=contractRecord.Account__c;
                newCaseRecord.Space__c=contractRecord.Space__c;
                
                //RPP-10995 - Change the Subject Naming Convention
                if(contractRecord.Space__r.CurrentLease__c!=null){
                    newCaseRecord.Subject = contractRecord.Property__r.Name + ' - ' + contractRecord.Space__r.Name + ' - ' + Constants.INSPECTION_REPORT;
                }else{
                    newCaseRecord.Subject = contractRecord.Property__r.Name + ' - ' + contractRecord.Name + ' - '+ Constants.INSPECTION_REPORT; 
                }
                
                newCaseRecord.Status=Constants.CASE_STATUS_SCHEDULED;
                newCaseRecord.Contract__c=contractRecord.Id;
                newCaseRecord.Opportunity__c=contractRecord.Opportunity__c;
                //newCaseRecord.OtherInspectionComments__c=System.Label.OtherInspectionComments;
                Id ownerid=userinfo.getUserId();
                if(accountteamMap.containskey(Constants.TEAM_ROLE_RDAM)){
                    ownerid=accountteamMap.get(Constants.TEAM_ROLE_RDAM).UserId;
                }else if(rolepropertyTeamMap.containskey(Constants.TEAM_ROLE_RDM)){
                    ownerid=rolepropertyTeamMap.get(Constants.TEAM_ROLE_RDM).TeamMember__c;
                }
                newCaseRecord.OwnerId=ownerid;
                
                if(contractRecord.LeaseEndDate__c>System.Today().addMonths(9)){
                    newCaseRecord.Priority=Constants.CASE_PRIORITY_LOW;
                }else if(contractRecord.LeaseEndDate__c>=System.Today().addMonths(6)&&contractRecord.LeaseEndDate__c<=System.Today().addMonths(9)){
                    newCaseRecord.Priority=Constants.CASE_PRIORITY_LOW;
                }else if(contractRecord.LeaseEndDate__c>=System.Today().addMonths(3)&&contractRecord.LeaseEndDate__c<=System.Today().addMonths(6)){
                    newCaseRecord.Priority=Constants.CASE_PRIORITY_MEDIUM;
                }else if(contractRecord.LeaseEndDate__c<=System.Today().addMonths(3)){
                    newCaseRecord.Priority=Constants.CASE_PRIORITY_HIGH;
                }
                caseListtoCreate.add(newCaseRecord);
            }
        }
        return caseListtoCreate;
    }
    
    /**
* @Author : Chen chen
* @Parameter : list of cases need to be checked
* @Description : based on the custom meta data case event trigger to determine whether to send event or not
*/
    public static List<Case> caseEventCriteriaCheck(List<Case> cases) {
        String caseStatus = Label.CaseStatus;
        List<Case> validCases = new List<Case>();
        List<RecordType> recordTypeCases = [Select Id, Name, DeveloperName From RecordType where sobjecttype =: Constants.OBJECT_CASE];
        Map<Id, String> recordIdToName = new Map<Id, String>();
        for (RecordType recordType : recordTypeCases) {
            recordIdToName.put(recordType.Id, recordType.DeveloperName);
        }
        List<CaseEventTrigger__mdt> criteriaSelections = [SELECT CaseStatus__c, CaseType__c FROM CaseEventTrigger__mdt LIMIT 10000];
        for (Case caseRecord : cases) {
            for (CaseEventTrigger__mdt caseEventTrigger : criteriaSelections) {
                if (caseRecord.recordTypeId != null && caseRecord.JDESentStatus__c != null && recordIdToName.get(caseRecord.recordTypeId) != null) {
                    if (recordIdToName.get(caseRecord.recordTypeId) == caseEventTrigger.CaseType__c && caseRecord.JDESentStatus__c == caseEventTrigger.CaseStatus__c && caseRecord.Status != null && !caseStatus.contains(caseRecord.Status)) {
                        validCases.add(caseRecord);
                        break;
                    }
                }
            }
        }
        return validCases;
    }
    
    /**
* @Author: Chen Chen
* @Parameter: successfullpublish successfull publish case event
* @Description: according to the successful publish event, update the case dispatch verison and timestamp
*/
    public static void updateCaseWhenCaseEventSentSuccess(List<CaseEvent__e> successfullpublish) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SecurityController.class.getName());
        List<Case> caseToUpdateDispatchDetailsList=new List<Case>(); 
        if(!successfullpublish.isEmpty() && successfullpublish.size()>0){
            for(CaseEvent__e publishedEvent: successfullpublish){
                // get values from pubished event payload to update parent records
                Map<String, Object> publishedCaseEvents;
                try {
                    publishedCaseEvents = (Map<String, Object>)JSON.deserializeUntyped(publishedEvent.CasePayload__c);
                } catch (Exception e) {
                    publishedCaseEvents = NULL;
                }
                
                if (publishedCaseEvents != NULL && !publishedCaseEvents.isEmpty()) {
                    Case caseToUpdateDispatchDetails = new Case();
                    caseToUpdateDispatchDetails.id=(id)publishedCaseEvents.get(Constants.DML_ID.toUpperCase());
                    String dispatchtimestampstr=(String)publishedCaseEvents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                    caseToUpdateDispatchDetails.TechDispatchedTimeStamp__c =DateTime.valueOf(dispatchtimestampstr);
                    String dispatchversionstr=(String)publishedCaseEvents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                    caseToUpdateDispatchDetails.TechDispatchedVersion__c=Decimal.valueOf(dispatchversionstr);
                    caseToUpdateDispatchDetailsList.add(caseToUpdateDispatchDetails);
                }
            }
        }
        if(!caseToUpdateDispatchDetailsList.isEmpty() && caseToUpdateDispatchDetailsList.size()>0){
            try {
                Database.update(caseToUpdateDispatchDetailsList, false);
            } catch (Exception e) {
                errorHandler.createError(e);
            }
            errorHandler.save();
        }
    }
    
    /**
* @Author: Chen Chen
* @Parameter: payloads List of case payloads
* @Description: according to the successful publish event, update the case dispatch verison and timestamp
*/
    public static List<CaseEvent__e> generateCaseEvents(List<String> payloads) {
        //Get all record type name, take in a map
        List<CaseEvent__e> caseEvents = new List<CaseEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                CaseEvent__e caesE = new CaseEvent__e();
                caesE.CasePayload__c = payload;
                caseEvents.add(caesE);
            }
        }
        return caseEvents;
    }
    
    /**
* @Author: Chen Chen
* @Parameter: payloads map of case payloads
* @Description: according to the successful publish event, update the case dispatch verison and timestamp
*/
    public static List<CaseEvent__e> generateCaseEventsByMap(Map<Id, String> payloads, Map<Id, Id> recordIdToRecordTypeId) {
        //Get all record type name, take in a map
        List<RecordType> caseRTs = [select id, name, SobjectType from RecordType where SobjectType =: Constants.OBJECT_CASE];
        Map<Id, String> recordTypeIdToName = new Map<Id, String>();
        for (RecordType caseRT : caseRTs) {
            recordTypeIdToName.put(caseRT.Id, caseRT.Name);
        }
        List<CaseEvent__e> caseEvents = new List<CaseEvent__e>();
        if (payloads.size() > 0) {
            for (Id payload : payloads.keyset()) {
                CaseEvent__e caesE = new CaseEvent__e();
                caesE.CasePayload__c = payloads.get(payload);
                if (recordIdToRecordTypeId.get(payload) != null){
                    caesE.RecordTypeName__c = recordTypeIdToName.get(recordIdToRecordTypeId.get(payload));   
                }
                caseEvents.add(caesE);
            }
        }
        return caseEvents;
    }
    
    /**
* @Author: Chen Chen
* @Parameter: trigger new map
* @Description: when case is fulfilled the critera from custom meta data type case event trigger, put it into map
*/
    public static Map<Id, Case> caseEventTriggerCriteriaCheckMap(Map<Id, Sobject> caseNewMap) {
        Map<Id, Case> dbCaseDataMapToPublish = new Map<Id, Case>();
        List<Case> dbCasedataMap = caseNewMap.values();
        List<Case> validCases = caseEventCriteriaCheck(dbCasedataMap);
        if (validCases.size() > 0) {
            for (Case caseRecord : validCases) {
                dbCaseDataMapToPublish.put(caseRecord.Id, (Case)caseNewMap.get(caseRecord.Id));
            }   
        }
        return dbCaseDataMapToPublish;
    }
    
    /**
* @Author: Chen Chen
* @Parameter: List of case Ids
* @Description: called in the process builder to create nso billing case 
*/
    @InvocableMethod 
    public static void retailDesignBillingCase(List<Id> ids) {
        List<Case> newCases = new List<Case>();
        List<Case> sNewCases = new List<Case>();
        List<Case> originCases = [Select Id, RecordTypeId, Space__c, TechBillingTriggered__c, Contract__c From Case Where Id in: ids];
        List<RecordType> recordTypeCases = [Select Id, Name From RecordType where sobjecttype =: Constants.OBJECT_CASE];
        Map<Id, String> recordIdToName = new Map<Id, String>();
        String retailDesignBillingId = '';
        for (RecordType recordType : recordTypeCases) {
            recordIdToName.put(recordType.Id, recordType.Name);
            if (recordType.Name == Constants.RETAIL_DESIGN_BILLING) {
                retailDesignBillingId = recordType.Id;
            }
        }
        if (originCases.size() > 0) {
            for (Case originCase : originCases) {
                Case retailDesingBillingCase = new Case();
                retailDesingBillingCase.Space__c = originCase.Space__c;
                retailDesingBillingCase.RecordTypeId = retailDesignBillingId;
                retailDesingBillingCase.Status = Constants.COMPLETED;
                if (originCase.Contract__c != null) {
                    retailDesingBillingCase.Contract__c = originCase.Contract__c;
                }
                retailDesingBillingCase.ParentId = originCase.Id;
                if (originCase.RecordTypeId != null && recordIdToName.get(originCase.RecordTypeId) != null) {
                    String recordTypeName = recordIdToName.get(originCase.RecordTypeId);
                    if (Constants.INSPECTION_REPORT == recordTypeName) {
                        retailDesingBillingCase.InspectionType__c = Constants.DSIR;
                    } else if (Constants.RETAIL_DESIGN_BILLING == recordTypeName) {
                        retailDesingBillingCase.InspectionType__c = Constants.DSMT;
                    } else if (Constants.STATEMENT_OF_COMPLETION == recordTypeName) {
                        retailDesingBillingCase.InspectionType__c = Constants.DSSO;
                    }
                }
                System.debug(retailDesingBillingCase.Status);
                newCases.add(retailDesingBillingCase);
            }
        }
        insert newCases;
        for (Case uCase : newCases) {
            uCase.Status = Constants.COMPLETED;
            sNewCases.add(uCase);
        }
        for (Case urCase : originCases) {
            urCase.TechBillingTriggered__c = true;
            sNewCases.add(urCase);
        }
        update sNewCases;
    }
    
    public static Map<Id, AccountTeamMember> caseOwnerAccountTeamMap = new Map<Id, AccountTeamMember>();
    public static Map<Id, PropertyTeam__c> caseOwnerPropertyTeamMap = new Map<Id, PropertyTeam__c>();
    
    /**
    * @Author: pkumarlg
    * @Parameter: set
    * @Description: called in the process builder to create nso billing case 
    */
    public static void getRelevantCaseOwners(Set<Id> accountIdSet, Set<Id> propertIdset){
        /*if(caseOwnerAccountTeamMap != null && accountIdSet != null && accountIdSet.size() > 0){
            try{
                for(AccountTeamMember memberRecord : DatabaseSOQLBank.getRetaiDesignAccountTeamPerAccount(accountIdSet)){
                    caseOwnerAccountTeamMap.put(memberRecord.AccountId, memberRecord);
                }
            } catch(Exception e){
                caseOwnerAccountTeamMap = null;
            }
        }
        
        if(caseOwnerPropertyTeamMap != null && propertIdset != null && propertIdset.size() > 0){
            try{
                for(PropertyTeam__c propertyTeam : DatabaseSOQLBank.getRetaiDesignPropertyTeamPerProperty(propertIdset)){
                    caseOwnerPropertyTeamMap.put(propertyteam.Property__c, propertyTeam);
                }
            } catch(Exception e){
                caseOwnerPropertyTeamMap = null;
            }
        }*/
    }
    
    public static Case updateCaseOwner(Case currentCase, Space__c space, String recordTypeName, Account account, Map<Id, Map<String, AccountTeamMember>> accountTeamRoleMap, Map<String, PropertyTeam__c> rolePropertyTeamMap){
        Boolean isAssigned = false;
        
        if(Label.CaseRecordTypeForOwnerUpdate.contains(recordTypeName)){
            if(account != null && account.ParentId != null 
                && accountTeamRoleMap.containsKey(account.ParentId) 
                && !Constants.STATEMENT_OF_COMPLETION.equalsIgnoreCase(recordTypeName)){
                if(accountTeamRoleMap.get(account.ParentId).containsKey(Constants.TEAM_ROLE_RDAM)){
                    currentCase.OwnerId = accountTeamRoleMap.get(account.ParentId).get(Constants.TEAM_ROLE_RDAM).UserId;
                    isAssigned = true;
                } 
            } 
            
            if(!isAssigned && account != null && account.Parent.ParentId != null 
                && accountTeamRoleMap.containsKey(account.Parent.ParentId) 
                && !Constants.STATEMENT_OF_COMPLETION.equalsIgnoreCase(recordTypeName)){
                
                if(accountTeamRoleMap.get(account.Parent.ParentId).containsKey(Constants.TEAM_ROLE_RDAM)){
                    currentCase.OwnerId = accountTeamRoleMap.get(account.Parent.ParentId).get(Constants.TEAM_ROLE_RDAM).UserId;
                    isAssigned = true;
                }
            }
            
            if(!isAssigned && rolePropertyTeamMap != null){
                if((Constants.INSPECTION_REPORT.equalsIgnoreCase(recordTypeName) 
                    || Constants.RETAIL_DESIGN_INSTRUCTION.equalsIgnoreCase(recordTypeName))
                    && rolePropertyTeamMap.containsKey(Constants.TEAM_ROLE_PRDM)
                    && Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(space.Status__c)){
                    currentCase.OwnerId = rolePropertyTeamMap.get(Constants.TEAM_ROLE_PRDM).TeamMember__c;
                    isAssigned = true;
                } 
                
                if (!isAssigned && rolePropertyTeamMap.containsKey(Constants.TEAM_ROLE_RDM)){
                    currentCase.OwnerId = rolePropertyTeamMap.get(Constants.TEAM_ROLE_RDM).TeamMember__c;
                    isAssigned = true;
                }
            }
        }
        
        return currentCase;
    }
    
    public static Case updateCaseApprovers(Case currentCase, Map<String, String> matrixRoleFieldMap,  Map<String, PropertyTeam__c> rolePropertyTeamMap, Space__c caseSpace, String caseRecordTypeName){
		String roleName;
		String fieldName;
        if(matrixRoleFieldMap != null && rolePropertyTeamMap != null){
            for(String matrixRole : matrixRoleFieldMap.keySet()){
				fieldName = matrixRoleFieldMap.get(matrixRole);
				roleName = matrixRole;
				
				if(caseRecordTypeName == 'Leasing Checksheet' && fieldName == 'TechRetailAdmin__c'){
					if(caseSpace.Status__c == 'Project'){
						roleName = 'Project Retail Administrator';
					}
				}
				
                if(rolePropertyTeamMap.containsKey(roleName)){
                    currentCase.put(matrixRoleFieldMap.get(matrixRole), rolePropertyTeamMap.get(roleName).TeamMember__c);
                }
            }
        }
        
        return currentCase;
    }
    
    /**
     * @author:         Kyle Tan
     * @desc:           populates contract field of case from the related opportunity
     **/
    public static Id getContractfromOpportunity(Map<Id, Opportunity> opportunityMap, Id opportunityId) {
        Id contractId = null;
        Set<String> validContractStatusSet = new Set<String>();
        List<String> tempContractStatusList = new List<String>();
        try{
            tempContractStatusList = Label.ContractStatus.split(';');
        } catch(Exception e) {
            tempContractStatusList = null;
        }
        if(tempContractStatusList != null) {
            validContractStatusSet.addAll(tempContractStatusList);
        }
        for(Contract__c contractRecord :opportunityMap.get(opportunityId).Contracts__r) {
            if(contractRecord.LeaseStatus__c != null && validContractStatusSet.contains(contractRecord.LeaseStatus__c)) {
                contractId = contractRecord.LeaseStatus__c;
            }
        }        
        return contractId;
    }
    
    /**
    * @author:         Janus Gargoles
    * @parameter:	   List of Opportunities, Map<Id: Space Id,Date: Terminate Lease Date>
    * @desc:           Populates the Forecasted Rent Termination Date of the Opportunities based on 
    * 				   Case LV05 Terminate Lease Date, and also updates the Latest Achieved Opportunity
    * 				   of the Space related to the opportunities - RPP - 4286
    **/
    public static List<Opportunity> updateFRTerminationDate(List<Opportunity> oppList, Map<Id,Date> spaceIdDateMap){
        List<Opportunity> oppListUpdated = new List<Opportunity>();
        Set<Id> latestAchievedOpportunitySet = new Set<Id>();
        Set<Id> oppUpdateIdSet = new Set<Id>();
        Opportunity latestAchievedOpp;
        if(oppList.size() != 0 && !oppList.isEmpty()){
            for(Opportunity oppty : oppList){
                if(spaceIdDateMap.containsKey(oppty.Space__c)){
                    oppty.ForecastedRentTerminationDate__c = spaceIdDateMap.get(oppty.Space__c);
                }
                if(oppty.Space__r.LatestAchievedOpportunity__c != null){
                    latestAchievedOpportunitySet.add(oppty.Space__r.LatestAchievedOpportunity__c);
                }
                oppListUpdated.add(oppty);
                oppUpdateIdSet.add(oppty.Id);
            }
        }
        if(latestAchievedOpportunitySet.size() != 0){
            latestAchievedOpp = DatabaseSOQLBank.getLatestAchievedOpportunity(latestAchievedOpportunitySet);
            if(!oppUpdateIdSet.contains(latestAchievedOpp.Id)){
                if(spaceIdDateMap.containsKey(latestAchievedOpp.Space__c)){
                    latestAchievedOpp.ForecastedRentTerminationDate__c = spaceIdDateMap.get(latestAchievedOpp.Space__c);
                }
                oppListUpdated.add(latestAchievedOpp);
            }
        }
        system.debug('oppListUpdated size - ' + oppListUpdated.size());
        return oppListUpdated;
    }
    
    /**
    * @author:         Janus Gargoles
    * @parameter:	   List of Space, Map<Id :Space Id, Id :Space Contract__c>
    * @desc:           Populates the Space status to Closed if the Case Contract is equal to 
    * 				   the Space Current Lease and if Space Status is At Risk or Trading - RPP - 4286
    **/
    public static List<Space__c> updateSpaceStatus(List<Space__c> spaceList, Map<Id,Id> spaceIdCurrentLeaseMap){
        List<Space__c> spaceListUpdated = new List<Space__c>();
        if(spaceList.size() != 0 && !spaceList.isEmpty()){
            for(Space__c space : spaceList){
                if(spaceIdCurrentLeaseMap.containsKey(space.Id)){
                    if(spaceIdCurrentLeaseMap.get(space.Id).equals(space.CurrentLease__c)){
                        if(space.Status__c == Constants.SPACE_STATUS_TRADING || space.Status__c == Constants.SPACE_STATUS_ATRISK){
                            space.Status__c = Constants.SPACE_STATUS_CLOSED;
                        }
                    }
                }
                spaceListUpdated.add(space);
            }
        }
        return spaceListUpdated;
    }
    
    public static List<CaseTeamMember> populateCaseTeamMembers(List<Case> newList){
        
        List<Case> casesToOperateOn = new List<Case>();
        List<CaseTeamMember> caseTeamsToCreate = new List<CaseTeamMember>();
        
        for(Case cs : newList){
            
            if(cs.SubType__c != Constants.CASE_SUBTYPE_COVID_RENT_REQUEST && !cs.TECH_Is_National_Account__c)
                continue;
            
            casesToOperateOn.add(cs);
        }
        
        if(casesToOperateOn.size() == 0)
            return caseTeamsToCreate;
        
        Set<String> userNames = new Set<String>(); 
        for(CovidCaseAccessibleUsers__mdt customMetadata : [SELECT MasterLabel, DeveloperName FROM CovidCaseAccessibleUsers__mdt]){
        	userNames.add(customMetadata.MasterLabel);
        }
        
        List<User> usersToAddinCaseTeams = [SELECT Id FROM User WHERE Name IN :userNames];
       	List<CaseTeamRole> caseTeamRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'National Request' LIMIT 1];
		
        //List<CaseTeamMember> caseTeamsToCreate = new List<CaseTeamMember>();
        
        for(Case cs : casesToOperateOn){
            for(User u : usersToAddinCaseTeams){
                CaseTeamMember csTm = new CaseTeamMember();
                csTm.ParentId = cs.Id;
                csTm.MemberId = u.Id;
                csTm.TeamRoleId = caseTeamRole[0].Id;
                caseTeamsToCreate.add(csTm);
            }
        }
        
        return caseTeamsToCreate;
    }
    
    //RPP-11090 START
    public static Set<Id> getCovidParentCaseSet(List<Case> parentCases){
        System.debug('parentCases === '+parentCases);
        Set<Id> covidParentCases = new Set<Id>();
        for(Case parentCase : parentCases){
            system.debug('parentCase.SubType__c === '+parentCase.SubType__c);
            System.debug('Constants.CASE_SUBTYPE_COVID_RENT_REQUEST === '+Constants.CASE_SUBTYPE_COVID_RENT_REQUEST);
            System.debug('parentCase.ParentId === '+parentCase.ParentId);
            if(parentCase.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST && parentCase.ParentId == null){
                covidParentCases.add(parentCase.Id);
            }
        }
        
        return covidParentCases;
    }
    
    public static List<Case> updateChildCases(Case parentCase, Case oldParentCase, List<Case> childCases, List<Copy_Covid_Case_Details__mdt> fieldsToCheckMetadata){
        List<Case> childCasesToUpdate = new List<Case>();
        Boolean isFieldUpdate = FALSE;
            
        for(Case childCase : childCases){
            Case cs = childCase;
            isFieldUpdate = FALSE;
            
            if(cs.ParentId != parentCase.Id)
                continue;
            
            for(Copy_Covid_Case_Details__mdt metadata : fieldsToCheckMetadata){
                String fieldApiName = metadata.Field_API_Name__c;
                
                if(oldParentCase.get(fieldApiName) == parentCase.get(fieldApiName))
                    continue;
                
                if(metadata.Copy_Every_Time__c){
                	cs.put(fieldApiName, parentCase.get(fieldApiName));
                    isFieldUpdate = TRUE;
                }else if(metadata.Copy_Only_Once__c){
                    System.debug(fieldApiName + ' === ' + cs.get(fieldApiName));
                    if(cs.get(fieldApiName) == '' || cs.get(fieldApiName) == NULL){
                        cs.put(fieldApiName, parentCase.get(fieldApiName));
                        isFieldUpdate = TRUE;
                    }else{
                        parentCovidCaseIds.add(parentCase.Id);
                        System.debug('parentCovidCaseIds === '+parentCovidCaseIds);
                    }
                }
            }
            if(isFieldUpdate)
            	childCasesToUpdate.add(cs);
            	System.debug('cs === '+ cs.Id);
        }
        System.debug('childCasesToUpdate size === ' + childCasesToUpdate.size());
        return childCasesToUpdate;
    }
    //RPP-11090 - END
}