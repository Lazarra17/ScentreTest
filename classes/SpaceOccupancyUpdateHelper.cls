public class SpaceOccupancyUpdateHelper{
    
    
    public static Map<Id,Space__c> updateOccupancyStatus(Set<Id> spaceidsSet,List<Space__c> spaceList,Map<Id,Space__c> dbspaceRecordsMap) {
        Map<id,Space__c> spacemap=new Map<Id,Space__c>();
        
        Set<String> opptytypeforvacancy=new Set<String>();
        opptytypeforvacancy.add(Constants.OPPTY_STAGENAME_NEWRETAILER);
        opptytypeforvacancy.add(Constants.OPPTY_STAGENAME_NEWLEASE);
        
        Set<String> spacesstatuslistone=new Set<String>();
        spacesstatuslistone.add(Constants.SPACE_STATUS_ATRISK);
        spacesstatuslistone.add(Constants.SPACE_STATUS_CLOSED);
        spacesstatuslistone.add(Constants.SPACE_STATUS_NEW);
        
        Set<String> spacesstatuslisttwo=new Set<String>();
        spacesstatuslisttwo.add(Constants.SPACE_STATUS_HELD);
        spacesstatuslisttwo.add(Constants.SPACE_STATUS_PROJECT);
        Map<Id,Opportunity> opportunityMap=new Map<Id,opportunity>([Select Id,Type,ProposedStartDate__c,ProposedEndDate__c from opportunity where Space__c IN : spaceidsSet]);
        Set<Id> spacecurrentleaseId=new Set<Id>();
        for (Space__c spaceRecord : spaceList){
            if(spaceRecord.CurrentLease__c!=null){
                spacecurrentleaseId.add(spaceRecord.CurrentLease__c);
            }
        }
        Map<Id,Contract__c> currentleaseMap=new Map<Id,Contract__c>();
        if(spacecurrentleaseId!=null&&spacecurrentleaseId.size()>0){
            currentleaseMap=new Map<Id,Contract__c>([select id,Opportunity__c ,LeaseStartDate__c from Contract__c where Id IN: spacecurrentleaseId]);
        }
        for (Space__c spaceRec : spaceList){
            Space__c oldRecord=new Space__c();
            if(dbspaceRecordsMap!=null && dbspaceRecordsMap.containskey(spaceRec.id)){
                oldRecord=dbspaceRecordsMap.get(spaceRec.id);
            }else{
                oldRecord=spaceRec;
            }
            
            if (spacesstatuslistone.contains(SpaceRec.Status__c)){ 
                if(spaceRec.Status__c == Constants.SPACE_STATUS_CLOSED){
                    if(spaceRec.LatestAchievedOpportunity__c==null){
                        spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_VACANCY;
                    }
                    if(currentleaseMap.containsKey(spaceRec.CurrentLease__c)){
                        If(currentleaseMap.get(spaceRec.CurrentLease__c).Opportunity__c==spaceRec.LatestAchievedOpportunity__c){
                            spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_VACANCY;
                        }
                    }
                }
                
                if((spaceRec.LatestAchievedOpportunity__c!=null &&
                    currentleaseMap.containsKey(spaceRec.CurrentLease__c) &&
                    opportunityMap.get(spaceRec.LatestAchievedOpportunity__c).Type==Constants.OPPTY_STAGENAME_NEWRETAILER &&
                    currentleaseMap.get(spaceRec.CurrentLease__c).Opportunity__c!=spaceRec.LatestAchievedOpportunity__c) ||
                   (spaceRec.LatestAchievedOpportunity__c!=null && spaceRec.CurrentLease__c ==null)) {  
                       spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LBNT;
                   } 
                else if(spaceRec.Status__c == Constants.SPACE_STATUS_ATRISK || spaceRec.Status__c == Constants.SPACE_STATUS_NEW) {
                        /*&&((oldRecord.CurrentForecastedOpportunity__r.CurrentLeaseVirtualVacancy__c!='No') 
                           || (oldRecord.LatestBudget__r.PromotionalAllowance__c !=null)
                           || (oldRecord.LatestForecast__r.CapitalSiteEstablishment__c != null)
                          )){
                              
                              spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LEASINGISSUES;
                          } else if(spaceRec.Status__c == Constants.SPACE_STATUS_NEW){*/
                              spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_LEASINGISSUES;
                          }
           
            } else if (spacesstatuslisttwo.contains(SpaceRec.Status__c)){
                
                if(spaceRec.Status__c == Constants.SPACE_STATUS_HELD && spaceRec.HeldVacantSpace__c){
                    spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_HELDVACANCIES;
                }else if(spaceRec.Status__c == Constants.SPACE_STATUS_PROJECT){
                    spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_PROJECTSHOPS;
                }
            } else if(spaceRec.Status__c == Constants.SPACE_STATUS_TRADING){
                //START END: NEEL 19072018 RPP-3449
                if(spaceRec.CurrentLeaseExpiryDate__c>=System.Today() && spaceRec.CurrentLeaseExpiryDate__c <= date.newinstance(System.Today().Year()+1, 12, 31)) {
                    
                    spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_EXPAIRINGLEASES;
                } else if(spaceRec.CurrentLeaseExpiryDate__c < System.Today()){
                    
                    spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_HOLDOVERS;
                }
                else if( spaceRec.LatestAchievedOpportunity__c!=null&&opportunityMap.containsKey(spaceRec.LatestAchievedOpportunity__c)){
                    
                    if(opportunityMap.get(spaceRec.LatestAchievedOpportunity__c).Type==Constants.OPPTY_STAGENAME_NEWRETAILER){
                        spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADINGNEWRETAILERS;
                        if(spaceRec.CurrentLease__c!=null&&currentleaseMap.containskey(spaceRec.CurrentLease__c)){
                            if(currentleaseMap.get(spaceRec.CurrentLease__c).Opportunity__c== spaceRec.LatestAchievedOpportunity__c&&currentleaseMap.get(spaceRec.CurrentLease__c).LeaseStartDate__c!=null){
                                if(currentleaseMap.get(spaceRec.CurrentLease__c).LeaseStartDate__c.Year()!=System.Today().Year()){
                                    spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADING;
                                }
                            }
                        }
                    } else {
                    	spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADING;
                	} 
                }     
                if(spaceRec.OccupancyStatus__c == Constants.SPACE_OCCUPANCYSTATUS_HOLDOVERS||spaceRec.OccupancyStatus__c == Constants.SPACE_OCCUPANCYSTATUS_EXPAIRINGLEASES){
                    
                    if(spaceRec.LatestAchievedOpportunity__c!=null&&opportunityMap.containsKey(spaceRec.LatestAchievedOpportunity__c)&&opportunityMap.get(spaceRec.LatestAchievedOpportunity__c).ProposedEndDate__c > date.newinstance(System.Today().Year()+1, 12, 31)){
                        
                        if(opportunityMap.get(spaceRec.LatestAchievedOpportunity__c).Type==Constants.OPPTY_STAGENAME_NEWRETAILER){
                            spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADINGNEWRETAILERS;
                        }else if(currentleaseMap.containskey(spaceRec.CurrentLease__c) && currentleaseMap.get(spaceRec.CurrentLease__c).Opportunity__c== spaceRec.LatestAchievedOpportunity__c){
                            spaceRec.OccupancyStatus__c = Constants.SPACE_OCCUPANCYSTATUS_TRADING;
                        }
                    }
                }
            }else if(spaceRec.Status__c == 'Inactive'){
                spaceRec.OccupancyStatus__c = '10 - Inactive';
            } 
            spacemap.put(spaceRec.id,spaceRec);
        }
        return spacemap;
    }
}