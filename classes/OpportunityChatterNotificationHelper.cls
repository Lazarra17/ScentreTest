/**
* Description: Utility class for Opportunity chatter post notification.
*/
public class OpportunityChatterNotificationHelper {
    
    public static List<ChatterPostUtil.ChatterNotificationWrapper> preparedatafornotification(List<Opportunity> OpportunityList) {
        Set<Id> propertyidSet=new Set<Id>();
        Set<Id> opportunityidSet=new Set<Id>();
        Set<String> propertyroleSet = new Set<String>();
        Map<Id,Set<String>> opportunityIdpropertyroleSet = new Map<Id,Set<String>>();
        Map<Id, Map<String,Set<Id>>> propertyIdroleandteamMap = new Map<Id, Map<String,Set<Id>>>();
        
        List<ChatterPostUtil.ChatterNotificationWrapper> chatterwrapperItemList = new List<ChatterPostUtil.ChatterNotificationWrapper>();
        
        
        if(!OpportunityList.isEmpty()&OpportunityList.size()>0){
            for(Opportunity opportunityRecord: OpportunityList){
                opportunityidSet.add(opportunityRecord.Id);
                if(String.IsNotBlank(opportunityRecord.property__c)){
                    propertyidSet.add(opportunityRecord.property__c);
                }
            }
            
            for(OpportunityClause__c oppclause: [select id,opportunity__c,ReferencedClause__c,ReferencedClause__r.RiskClauseNotifyUsers__c
                                                 from OpportunityClause__c where opportunity__c in : opportunityidSet and ReferencedClause__r.RiskClauseNotifyUsers__c != null]){
                                                     if(String.isNotBlank(oppclause.ReferencedClause__r.RiskClauseNotifyUsers__c)){
                                                         propertyroleSet.addall((oppclause.ReferencedClause__r.RiskClauseNotifyUsers__c).split(';')); 
                                                         if(opportunityIdpropertyroleSet.containskey(oppclause.opportunity__c)){
                                                             opportunityIdpropertyroleSet.get(oppclause.opportunity__c).addall((oppclause.ReferencedClause__r.RiskClauseNotifyUsers__c).split(';'));
                                                         }else{
                                                             opportunityIdpropertyroleSet.put(oppclause.opportunity__c,propertyroleSet);
                                                         }
                                                     }
                                                 }
            
            // get all active property team records.
            for(propertyteam__c propertyTeam: [select property__c,id,teammember__c,role__c from propertyteam__c where property__c in: propertyidSet and teammember__c != null AND teammember__r.IsActive=true AND Active__c=true]){
                if(propertyIdroleandteamMap.containskey(propertyTeam.property__c)){
                    if(propertyIdroleandteamMap.get(propertyTeam.property__c).containsKey(propertyTeam.role__c)){
                        propertyIdroleandteamMap.get(propertyTeam.property__c).get(propertyTeam.role__c).add(propertyTeam.teammember__c);
                    }else{
                        propertyIdroleandteamMap.get(propertyTeam.property__c).put(propertyTeam.role__c,new Set<Id>{propertyTeam.teammember__c});
                    }
                }else{
                    propertyIdroleandteamMap.put(propertyTeam.property__c,new Map<String,Set<Id>>());
                    propertyIdroleandteamMap.get(propertyTeam.property__c).put(propertyTeam.role__c,new Set<Id>{propertyTeam.teammember__c});
                }
            }
            
            for(Opportunity opportunityRecord: OpportunityList){
                
                Set<Id> mentionUsers = new Set<Id>();
                mentionUsers.add(opportunityRecord.OwnerId);
                system.debug('OWNERID: '+opportunityRecord.OwnerId);
                List<String> parameters = new List<String>();
                parameters.add(opportunityRecord.Name);
                // prepare data to post message
                ChatterPostUtil.ChatterNotificationWrapper chatterwrapperItem = new ChatterPostUtil.ChatterNotificationWrapper();
                chatterwrapperItem.subjectId = opportunityRecord.id;
                
               // if(opportunityRecord.ApprovalStatus__c==Constants.PENDING_RISK_APRV &&String.IsNotBlank(opportunityRecord.Property__c)){
                if((opportunityRecord.ApprovalStatus__c==Constants.RSKAPPR_GRANTED || opportunityRecord.ApprovalStatus__c==Constants.RISK_APPRV_REJ) &&
                   String.IsNotBlank(opportunityRecord.Property__c)){
                       
                       if(opportunityIdpropertyroleSet.containsKey(opportunityRecord.Id)){
                           Set<String> applicableroleSet=opportunityIdpropertyroleSet.get(opportunityRecord.Id);
                           if(propertyIdroleandteamMap.containsKey(opportunityRecord.Property__c)){
                               for(String applicablerole : propertyIdroleandteamMap.get(opportunityRecord.Property__c).keySet()){
                                   if(applicableroleSet.contains(applicablerole)){
                                       mentionUsers.addAll(propertyIdroleandteamMap.get(opportunityRecord.Property__c).get(applicablerole));
                                   }
                               }
                           }
                       }
                       
                       parameters.add(opportunityRecord.ApprovalStatus__c==Constants.RSKAPPR_GRANTED ? 'approved' : 'rejected');
                       
                       chatterwrapperItem.body=String.format(Label.RiskApprovalChatterMsg, parameters);
                }
                
                // logic to get message after opportunity is approved.
                // if(opportunityRecord.ApprovalStatus__c==Constants.RSKAPPR_GRANTED ||
                if(opportunityRecord.ApprovalStatus__c==Constants.FINALAPPR_GRANT||
                   opportunityRecord.ApprovalStatus__c==Constants.INIAPPR_GRANTED ||
                   opportunityRecord.ApprovalStatus__c==Constants.STRAPPOVALGRANTED){
                       
                       //if(opportunityRecord.ApprovalStatus__c==Constants.INIAPPR_GRANTED  || opportunityRecord.ApprovalStatus__c==Constants.RSKAPPR_GRANTED  || opportunityRecord.ApprovalStatus__c==Constants.FINALAPPR_GRANT){
                       if(opportunityRecord.ApprovalStatus__c==Constants.INIAPPR_GRANTED  || opportunityRecord.ApprovalStatus__c==Constants.FINALAPPR_GRANT){
                           if(opportunityRecord.GMLARS__c != null){
                               mentionUsers.add(opportunityRecord.GMLARS__c);
                           }
                           if(opportunityRecord.RMLARS__c != null){
                               mentionUsers.add(opportunityRecord.RMLARS__c);
                           }
                           if(opportunityRecord.GMRetailAdmin__c != null){
                               mentionUsers.add(opportunityRecord.GMRetailAdmin__c);
                           }
                           if(opportunityRecord.DirectorLARSNZDevelopment__c != null){
                               mentionUsers.add(opportunityRecord.DirectorLARSNZDevelopment__c);
                           }
                           if(opportunityRecord.CorporateLegal__c != null){
                               mentionUsers.add(opportunityRecord.CorporateLegal__c);
                           }
                           if(opportunityRecord.COO__c != null){
                               mentionUsers.add(opportunityRecord.COO__c);
                           }
                       }
                       if(opportunityRecord.ApprovalStatus__c==Constants.FINALAPPR_GRANT){
                           parameters.add(Constants.FINAL_APRV_REQ);
                       }else if(opportunityRecord.ApprovalStatus__c==Constants.STRAPPOVALGRANTED){
                           // this is for storeroom opportunity 
                           parameters.add(Constants.LIC_APRV_REQ);
                       }else if(opportunityRecord.ApprovalStatus__c==Constants.INIAPPR_GRANTED){
                           parameters.add(Constants.IN_APPR_REQ);
                       }
                       //else if(opportunityRecord.ApprovalStatus__c==Constants.RSKAPPR_GRANTED){
                       //    parameters.add(Constants.RISK_APPRV_REQ);
                       //}
                       chatterwrapperItem.body = String.format(Label.OpportunityApprovedChatterMessage, parameters);
                   }
                
                // logic to get message after Initial approval is rejected.
                if(opportunityRecord.ApprovalStatus__c==Constants.INI_APPV_REJ){
                    parameters.add(Constants.IN_APPR_REQ);
                    chatterwrapperItem.body = String.format(Label.OpportunityRejectedChatterMessage, parameters);
                }
                // logic to get message after Risk approval is rejected.
                //else if(opportunityRecord.ApprovalStatus__c==Constants.RISK_APPRV_REJ){
                //    parameters.add(Constants.RISK_APPRV_REQ);
                 //   chatterwrapperItem.body = String.format(Label.OpportunityRejectedChatterMessage, parameters);
                //}
                // logic to get message after final approval is rejected.
                else if(opportunityRecord.ApprovalStatus__c==Constants.FINALAPPR_REJ){
                    parameters.add(Constants.FINAL_APRV_REQ);
                    chatterwrapperItem.body = String.format(Label.OpportunityRejectedChatterMessage, parameters);
                }
                // logic to get message after license approval is rejected.
                else if(opportunityRecord.ApprovalStatus__c==Constants.STRAPPOVALREJ){
                    parameters.add(Constants.STRAPPOVALREJ);
                    chatterwrapperItem.body = String.format(Label.OpportunityRejectedChatterMessage, parameters);
                }
                chatterwrapperItem.mentionedUsers=mentionUsers;
                chatterwrapperItemList.add(chatterwrapperItem);
            }
        }
        return chatterwrapperItemList;
    }
}