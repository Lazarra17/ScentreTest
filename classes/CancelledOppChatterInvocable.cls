global class CancelledOppChatterInvocable {
    
    @InvocableMethod
    public static void postChatterToPropTeam(List<Id> oppIdList) {
        Map<String, Schema.RecordTypeInfo> oppRecordTypeMapByDeveloperName = RecordTypeUtil.getAllRecordTypesByDeveloperName(CONSTANTS.OPPORTUNITY);
        Set<String> teamRolesToNotify = new Set<String>{ 
            	Constants.TEAM_ROLE_AT,
                Constants.TEAM_ROLE_RDC,
                Constants.TEAM_ROLE_RDM, 
                Constants.TEAM_ROLE_RMR_DESIGN, 
                Constants.TEAM_ROLE_RMR_DELIVERY,
                Constants.TEAM_ROLE_RA
                };
                
		Map<Id, List<Id>> propTeamMembersByOppMap = new Map<Id, List<Id>>();
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name, RecordURL__c, Property__c, RecordTypeId FROM Opportunity WHERE Id IN:oppIdList]);
		Set<Id> propIdSet = new Set<Id>();
        Map<Id, Map<String, PropertyTeam__c>> propTeamMembersMap = new Map<Id, Map<String, PropertyTeam__c>>();
        List<ChatterPostUtil.chatterNotificationWrapper> chatterList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        
        for (Opportunity opp : oppMap.values()) {            
            if (opp.Property__c != null) {
                propIdSet.add(opp.Property__c);    
            }
        }
        
        propTeamMembersMap = DatabaseSOQLBank.getPropertyTeamByProperty(propIdSet);
        Id retailOppRecTypeId = oppRecordTypeMapByDeveloperName.get(Constants.OPP_RETAIL_LEASING_API_NAME).getRecordTypeId();
        
        
        for (Opportunity opp : oppMap.values()) {            			
            System.debug('propTeamMembersMap.containsKey(opp.Property__c) '+propTeamMembersMap.containsKey(opp.Property__c) );
            System.debug(opp.RecordTypeId +' '+retailOppRecTypeId);
            if (propTeamMembersMap.containsKey(opp.Property__c) && opp.RecordTypeId == retailOppRecTypeId) {
                
                Set<Id> teamMembersToMention = new Set<Id>();
                
                for (PropertyTeam__c propTeam : propTeamMembersMap.get(opp.Property__c).values()) {
                    if (teamRolesToNotify.contains(propTeam.Role__c)) {
                        teamMembersToMention.add(propTeam.TeamMember__c);
                    }
                }
                
                
                chatterList.add(ChatterPostUtil.ChatterPostGeneric(
                    Label.ChatterCancelledOppGeneric,
                    opp.Id,
                    new List<String>(),
                    teamMembersToMention,
                    opp.Id
                ));
                
            }
            
        }
        
        if (chatterList.size() > 0) {
            ChatterPostUtil.chatterpostBulk(chatterList);
        }
            
    }
}