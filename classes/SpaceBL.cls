public class SpaceBL{
    /**
* @Author: Chen Chen
* @Para: List<String> jsonPayloads, List of json payload that need to send out as space event
* @Desc: This is used for generating space platform events by the providing payloads
*/
    
    public static List<SpaceEvent__e> generateSpaceEvents(List<String> payloads) {
        List<SpaceEvent__e> spaceEvents = new List<SpaceEvent__e>();
        if (payloads.size() > 0) {
            for (String payload : payloads) {
                SpaceEvent__e spaceE = new SpaceEvent__e();
                spaceE.JSONPayload__c = payload;
                spaceEvents.add(spaceE);
            }
        }
        return spaceEvents;
    }
    
    public static List<Space__c> updatedispatchdetailsonSpace(){
        List<Space__c> spacelist=new List<Space__c>();
        
        return spacelist;
    }
    
    public static void updateSpaceWhenSpaceEventSentSuccess(List<SpaceEvent__e> successfullpublish) {
        List<Space__c> spacetoupdatedispatchdetailsList=new List<Space__c>(); 
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceBL.class.getName());
        if(!successfullpublish.isEmpty()&&successfullpublish.size()>0){
            for(SpaceEvent__e publishedevent: successfullpublish){
                // get values from pubished event payload to update parent records
                Map<String, Object> publishedspaceevents;
                try {
                    publishedspaceevents=(Map<String, Object>)JSON.deserializeUntyped(publishedevent.JSONPayload__c);
                } catch (Exception e) {
                    publishedspaceevents = NULL;
                }
                if(publishedspaceevents != NULL && !publishedspaceevents.isEmpty()) {
                    System.debug('**DISPATCHEEVENT**'+publishedspaceevents);
                    Space__c spacetoupdatedispatchdetails=new Space__c();
                    spacetoupdatedispatchdetails.id=(id)publishedspaceevents.get(Constants.DML_ID.toUpperCase());
                    String dispatchtimestampstr=(String)publishedspaceevents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                    spacetoupdatedispatchdetails.TechDispatchedTimeStamp__c =DateTime.valueOf(dispatchtimestampstr);
                    String dispatchversionstr=(String)publishedspaceevents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                    spacetoupdatedispatchdetails.TechDispatchedVersion__c=Decimal.valueOf(dispatchversionstr);
                    spacetoupdatedispatchdetailsList.add(spacetoupdatedispatchdetails);
                }
            }
        }
        System.debug('**FORUPDATE**'+spacetoupdatedispatchdetailsList);
        if(!spacetoupdatedispatchdetailsList.isEmpty()&&spacetoupdatedispatchdetailsList.size()>0){
            try{
                Database.update(spacetoupdatedispatchdetailsList);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
    
    public static List<SpaceGroup__c> getAllSpaceGroupByGroupNumber(Set<Id> childSpaceIdSet){
        Set<Decimal> spacegroupNumberSet = new Set<Decimal>();
        List<SpaceGroup__c> spaceGroupList = new List<SpaceGroup__c>();
        
        try{
            for(SpaceGroup__c spaceGroup : DatabaseSOQLBank.getSpaceGroupOfChildSpace(childSpaceIdSet)){
                spacegroupNumberSet.add(spaceGroup.SpaceGroupNumber__c);
            }
        } catch(Exception e){
            spacegroupNumberSet = null;
        }
        
        if(spaceGroupNumberSet != null){
            try{
                spaceGroupList = DatabaseSOQLBank.getSpaceGroupBySpaceGroupNumber(spacegroupNumberSet);
            } catch(Exception e){
                spaceGroupList = null;
            }
        }
        
        return spaceGroupList;
    }
    
    //RPP-4311 SG 6.26.18
    
    public static List<Space__c> updateSpaceRecords(Map<Id, Opportunity> opportunityMap, List<SpaceGroup__c> spaceGroupList){
        Space__c spaceTemp;
        Set<Id> spaceIdSet = new Set<Id>();
        Set<Id> childSpaceIdSet = new Set<Id>();
        Set<Decimal> spacegroupNumberSet = new Set<Decimal>();
        List<Space__c> spaceTempList = new List<Space__c>();
        List<Space__c> spaceToUpdateList = new List<Space__c>();
        Map<Id, Space__c> spaceMap = new Map<Id, Space__c>();
        Map<Id, Opportunity> spaceIdOpportunityMap = new Map<Id, Opportunity>();
        //Map<Decimal, Set<Id>> sGroupNumberChildSpaceIdSetMap = new Map<Decimal, Set<Id>>();
        //Map<Decimal, Set<Id>> sGroupNumberParentSpaceIdSetMap = new Map<Decimal, Set<Id>>();
        Map<Decimal, Map<Id, Space__c>> sGroupNumberChildSpaceMap = new Map<Decimal, Map<Id, Space__c>>();
        Map<Decimal, Map<Id, Space__c>> sGroupNumberParentSpaceMap = new Map<Decimal, Map<Id, Space__c>>();
        Map<String, Schema.RecordTypeInfo> spaceRecordTypeByDeveloperName=RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.SPACE);
        Set<String> openStageSet = new Set<String>{
            Constants.APPROVE,
                Constants.PROPOSE_ACCEPT,
                Constants.UNDERSTAND_NEGOTIATE
                };
                    
                    for(Opportunity opp : opportunityMap.values()){
                        if(opp.Space__c != null){
                            spaceTemp = new Space__c(Id = opp.Space__c);
                            spaceMap.put(spaceTemp.Id, spaceTemp);                            
                            if(opp.DealAchieved__c && !opp.TechByPassOnClone__c){
                                spaceMap.get(opp.Space__c).LatestAchievedOpportunity__c=opp.Id;
                            } else if(openStageSet.contains(opp.StageName) && opp.BestBet__c){
                                spaceMap.get(opp.Space__c).CurrentForecastedOpportunity__c=opp.Id;
                            }
                            // update space record type to SPA_LeasedSpaces
                            if(opp.JDESentStatus__c==Constants.OPPO_JDE_STATUS_READY){
                                spaceMap.get(opp.Space__c).RecordTypeId=spaceRecordTypeByDeveloperName.get('SPA_LeasedSpaces').getRecordTypeId();
                            }
                        }
                    }
        if(spaceGroupList != null && !spaceGroupList.isEmpty()){
            if(spaceGroupList != null && spaceGroupList.size() > 0){
                for(SpaceGroup__c spaceGroupRecord : spaceGroupList){
                    if(spaceMap.containsKey(spaceGroupRecord.ChildSpace__c)){
                        spaceTemp = spaceMap.get(spaceGroupRecord.ChildSpace__c);
                    } else {
                        spaceTemp = new Space__c(Id = spaceGroupRecord.ChildSpace__c);
                    }
                    spaceTemp.ReadyToForecast__c = true;
                    if(sGroupNumberParentSpaceMap.containsKey(spaceGroupRecord.SpaceGroupNumber__c)){
                        if(!sGroupNumberParentSpaceMap.get(spaceGroupRecord.SpaceGroupNumber__c).containsKey(spaceGroupRecord.ParentSpace__c)){
                            sGroupNumberParentSpaceMap
                                .get(spaceGroupRecord.SpaceGroupNumber__c)
                                .put(spaceGroupRecord.ParentSpace__c, spaceGroupRecord.ParentSpace__r);
                        }
                    } else {
                        sGroupNumberParentSpaceMap.put(spaceGroupRecord.SpaceGroupNumber__c,
                                                       new Map<Id, Space__c>{
                                                           spaceGroupRecord.ParentSpace__c => spaceGroupRecord.ParentSpace__r
                                                               }
                                                      );
                    }
                    
                    if(sGroupNumberChildSpaceMap.containsKey(spaceGroupRecord.SpaceGroupNumber__c)){
                        if(!sGroupNumberChildSpaceMap.get(spaceGroupRecord.SpaceGroupNumber__c).containsKey(spaceGroupRecord.ChildSpace__c)){
                            sGroupNumberChildSpaceMap
                                .get(spaceGroupRecord.SpaceGroupNumber__c)
                                .put(spaceGroupRecord.ChildSpace__c, spaceGroupRecord.ChildSpace__r);
                        }
                    } else {
                        sGroupNumberChildSpaceMap.put(spaceGroupRecord.SpaceGroupNumber__c,
                                                      new Map<Id, Space__c>{
                                                          spaceGroupRecord.ChildSpace__c => spaceGroupRecord.ChildSpace__r
                                                              }
                                                     );
                    }
                    
                    spaceMap.put(spaceTemp.Id, spaceTemp);
                }
            }
            
            if(!sGroupNumberParentSpaceMap.isEmpty() && !sGroupNumberChildSpaceMap.isEmpty()){
                for(Decimal groupNumber : sGroupNumberParentSpaceMap.keySet()){
                    if(sGroupNumberChildSpaceMap.containsKey(groupNumber)){
                        spaceTempList = SpaceManagementController.calculateCurrenRent(
                            sGroupNumberParentSpaceMap.get(groupNumber).values(),
                            sGroupNumberChildSpaceMap.get(groupNumber).values()
                        );
                        for(Space__c space : spaceTempList){
                            if(spaceMap.containsKey(space.Id)){
                                spaceTemp = spaceMap.get(space.Id);
                                spaceTemp.ReconfiguredCurrentRent__c = space.ReconfiguredCurrentRent__c;
                                spaceTemp.ReconfiguredCurrentRentSemiGross__c = space.ReconfiguredCurrentRentSemiGross__c;
                            } else {
                                spaceTemp = new Space__c(
                                    Id = space.Id,
                                    ReconfiguredCurrentRent__c = space.ReconfiguredCurrentRent__c,
                                    ReconfiguredCurrentRentSemiGross__c = space.ReconfiguredCurrentRentSemiGross__c
                                );
                            }
                            
                            spaceMap.put(spaceTemp.Id, spaceTemp);
                        }
                    }
                }
            }
        }
        
        return spaceMap.values();
    }
    
    /**
* @author:          Kyle Tan
* @desc:            check any of the space group is reconfigured
**/
    public static Boolean checkActiveConfigurations(List<SpaceGroup__c> spaceGroupList, Id spaceId) {
        Boolean isConfigured = false;
        if(spaceGroupList != null && spaceGroupList.size() > 0) {
            for(SpaceGroup__c spaceGroupRec :spaceGroupList) {
                if(spaceGroupRec.Active__c && spaceGroupRec.ParentSpace__c == spaceId) {
                    isConfigured = true;
                }
            }
        }
        return isConfigured;
    }
    
    /**
* @author:          Kyle Tan
* @desc:            updates spaces by adding in the new tenant
**/
    public static List<Space__c> updateCurrentAndPreviousTenant(List<Contract__c> contractList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceBL.class.getName());
        List<Space__c> spaceToUpdateList = new List<Space__c>();
        List<Space__c> spaceList = new List<Space__c>();
        Set<Id> spaceIdSet = new Set<Id>();
        Map<Id, Contract__c> spaceIdContractMap = new Map<Id, Contract__c>();
        system.debug('contractList-->' + contractList);
        if(contractList != null && contractList.size() > 0) {
            for(Contract__c contractRecord :contractList) {
                if(contractRecord.Space__c != null) {
                    spaceIdSet.add(contractRecord.Space__c);
                    //if(contractRecord.LeaseStartDate__c == date.today()) {
                    //if(contractRecord.LeaseStartDate__c <= date.today() && contractRecord.ActualVacateDate__c == null) {
                    //if(contractRecord.ActualVacateDate__c == null) {
                    spaceIdContractMap.put(contractRecord.Space__c, contractRecord);
                    //}
                }
            }
            system.debug('spaceIdContractMap-->' + spaceIdContractMap);
            if(spaceIdSet != null && spaceIdSet.size() > 0) {
                try{
                    spaceList = DatabaseSOQLBank.getSpaces(spaceIdSet);
                } catch(Exception e) {
                    spaceList = null;
                    errorHandler.createError(e);
                }
                system.debug('spaceList-->' + spaceList);
                if(spaceList != null && spaceList.size() > 0) {
                    for(Space__c spaceRecord :spaceList) {
                        //if(!(spaceIdContractMap.get(spaceRecord.Id).Account__c == spaceRecord.CurrentRetailer__c)){   //commented out and logic enhanced for RPP-10741
                        if(spaceRecord.CurrentLease__c != spaceIdContractMap.get(spaceRecord.Id).Id){
                            
                            if(spaceRecord.CurrentLease__c == null 
                               && spaceIdContractMap.get(spaceRecord.Id).LeaseStartDate__c <= date.today() 
                               && spaceIdContractMap.get(spaceRecord.Id).ActualVacateDate__c == null){
                                   
                                spaceRecord.CurrentLease__c = spaceIdContractMap.get(spaceRecord.Id).Id;
                                spaceRecord.CurrentRetailer__c = spaceIdContractMap.get(spaceRecord.Id).Account__c;
                                spaceRecord.CurrentRetailerName__c  = spaceIdContractMap.get(spaceRecord.Id).Account__r.Name;
                                spaceToUpdateList.add(spaceRecord);
                            } 
                            else {
                                if(spaceRecord.CurrentLease__c != null &&
                                   spaceRecord.CurrentRetailer__c != null) {
                                       spaceRecord.PreviousLease__c = spaceRecord.CurrentLease__c;
                                       spaceRecord.PreviousTenant__c = spaceRecord.CurrentRetailer__c;
                                   }
                                spaceRecord.CurrentLease__c = spaceIdContractMap.get(spaceRecord.Id).Id;
                                spaceRecord.CurrentRetailer__c = spaceIdContractMap.get(spaceRecord.Id).Account__c;
                                spaceRecord.CurrentRetailerName__c  = spaceIdContractMap.get(spaceRecord.Id).Account__r.Name;
                                spaceToUpdateList.add(spaceRecord);
                            } 
                            
                        }
                        
                        
                        /*if((spaceRecord.CurrentLease__c != null && 
spaceRecord.CurrentLease__r.ActualVacateDate__c != null && 
spaceRecord.CurrentLease__r.ActualVacateDate__c < date.today()) || 
spaceRecord.CurrentLease__c == null) {
if(spaceIdContractMap.containsKey(spaceRecord.Id)) {
if(spaceRecord.CurrentLease__c != null &&
spaceRecord.CurrentRetailer__c != null) {
spaceRecord.PreviousLease__c = spaceRecord.CurrentLease__c;
spaceRecord.PreviousTenant__c = spaceRecord.CurrentRetailer__c;
}
spaceRecord.CurrentLease__c = spaceIdContractMap.get(spaceRecord.Id).Id;
spaceRecord.CurrentRetailer__c = spaceIdContractMap.get(spaceRecord.Id).Account__c;
spaceRecord.CurrentRetailerName__c  = spaceIdContractMap.get(spaceRecord.Id).Account__r.Name;
}
spaceToUpdateList.add(spaceRecord);
}*/
                    }
                }
            }
        }
        errorHandler.save();
        return spaceToUpdateList;
    }
    // RPP-10553 Lean Flores June 19 2019
    public static Space__c updateStatusBasedOnVirtualVacancy(Space__c spc, Opportunity opp) {
        
        if (spc == null) {
            return null;
        }
        
        Boolean virtualVacancy = !Constants.NO.equalsIgnoreCase(opp.CurrentLeaseVirtualVacancy__c) && !String.isBlank(opp.CurrentLeaseVirtualVacancy__c);
        
        if(virtualVacancy && Constants.SPACE_STATUS_TRADING.equalsIgnoreCase(spc.Status__c)) { 
            
            spc.Status__c = Constants.SPACE_STATUS_ATRISK;
            
        } else if (!virtualVacancy && Constants.SPACE_STATUS_ATRISK.equalsIgnoreCase(spc.Status__c) && !Constants.SPACE_OCCUPANCYSTATUS_LBNT.equalsIgnoreCase(spc.OccupancyStatus__c) && String.isBlank(spc.Relationship__c)) {
            
            spc.Status__c = Constants.SPACE_STATUS_TRADING;
        }
        
        return spc;
    }    
}