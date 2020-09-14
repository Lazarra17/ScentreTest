/* Created By - Sauce Consulting
* Purpose - to notify Property Centre Manager, RDC and Retail Manager on completion of 'Add Attach or Complete SDIC' task
* This class is called form 'TAS_OnTaskInsertOrUpdate' process builder
* This class is created to implement RPP-11001 ticket
*/
global class ChatterForSDICTaskCompletion {
    
    @InvocableMethod
    public static void chatterPostToProprtyTeam(List<Id> taskIds) {
        try{
            
            List<Task> taskList = [SELECT Id, WhatId, Opportunity__r.Space__r.Property__c, Case__r.Space__r.Property__c 
                                   FROM Task 
                                   WHERE Id IN: taskIds];
            System.debug('taskListmain class'+taskList);
            List<Case> caseListToUpdate = new List<Case>();
            
            Map<Id, Id> caseIdVsTaskId = new Map<Id, Id>();
            Map<Id, Id> oppIdVsTaskId = new Map<Id, Id>();
            Map<Id, Id> propertyIdVsTaskId = new Map<Id, Id>();
            
            for(Task t : taskList){
                if(((String)t.whatId).left(3) == '006'){
                    oppIdVsTaskId.put(t.whatId, t.Id);
                    propertyIdVsTaskId.put(t.Opportunity__r.Space__r.Property__c, t.Id);
                }
                if(((String)t.whatId).left(3) == '500'){
                    caseIdVsTaskId.put(t.whatId, t.Id);
                    propertyIdVsTaskId.put(t.Case__r.Space__r.Property__c, t.Id);
                }
            }
           
            Map<Id, Case> taskVsCaseMap = new Map<Id, Case>();
            Map<Id, Opportunity> taskVsOppMap = new Map<Id, Opportunity>();
            
            for(Case c : [SELECT Id, Subject, Property__c, Space__r.Name FROM Case WHERE Id IN: caseIdVsTaskId.keySet()]){
                taskVsCaseMap.put(caseIdVsTaskId.get(c.Id), c);
                System.debug('taskVsCaseMap'+taskVsCaseMap);
            }
            
            for(Opportunity opp : [SELECT Id, Name, Property__r.Name, Space__r.Name FROM Opportunity WHERE Id IN: oppIdVsTaskId.keySet()]){
                taskVsOppMap.put(oppIdVsTaskId.get(opp.Id), opp);
            }
            
            Map<Id, List<Id>> taskIdVsPropertyTeamMemberIds = new Map<Id, List<Id>>();
            
            for(PropertyTeam__c team : [SELECT Id, TeamMember__c, Property__c 
                                        FROM PropertyTeam__c 
                                        WHERE Property__c IN: propertyIdVsTaskId.keySet()
                                        AND Role__c IN ('Centre Manager', 'Retail Delivery Coordinator', 'Retail Manager')]){
                                            
                                            Id taskId = propertyIdVsTaskId.get(team.Property__c);
                                            
                                            if(taskIdVsPropertyTeamMemberIds.containsKey(taskId)){
                                                List<Id> teamIds = taskIdVsPropertyTeamMemberIds.get(taskId);
                                                teamIds.add(team.TeamMember__c);
                                                taskIdVsPropertyTeamMemberIds.put(taskId, teamIds);
                                            }else{
                                                List<Id> teamIds = new List<Id>();
                                                teamIds.add(team.TeamMember__c);
                                                taskIdVsPropertyTeamMemberIds.put(taskId, teamIds);
                                            }
                                        }
            
            List<ChatterPostUtil.chatterNotificationWrapper> chatterLst = new List<ChatterPostUtil.chatterNotificationWrapper>();
            
            for(Task t : taskList){
               ChatterPostUtil.chatterNotificationWrapper chatterItem = new ChatterPostUtil.chatterNotificationWrapper();
                Set<Id> mentionUsers = new Set<Id>(taskIdVsPropertyTeamMemberIds.get(t.Id));
                
                chatterItem.mentionedUsers = mentionUsers;
                chatterItem.subjectId = t.WhatId;
                
                List<String> parameters = new List<String>();
                String chatterBody = '';
                
                if(((String)t.whatId).left(3) == '006'){
                    if(taskVsOppMap.containsKey(t.Id)){
                        System.debug('taskVsOppMap'+t.Id);
                        Opportunity opp = taskVsOppMap.get(t.Id);
                        parameters.add(opp.name);
                        
                        chatterBody = '\'Attach or Complete SDIC\' task has been completed for the space - ';
                        chatterBody += opp.Space__r.Name + ' at ' + opp.Property__r.Name;
                    }
                }
                
                if(((String)t.whatId).left(3) == '500'){
                    if(taskVsCaseMap.containsKey(t.Id)){
                       Case c = taskVsCaseMap.get(t.Id);
                        parameters.add(c.Subject);
                        
                        chatterBody = '\'Attach or Complete SDIC\' task has been completed for the space - ';
                        chatterBody += c.Space__r.Name + ' at ' + c.Property__c;
                        c.TECH_Is_SDIC_Task_Completed__c = true;
                        caseListToUpdate.add(c);
                    }
                }
                
                String paramChatterBody = String.format(chatterBody, parameters);
                chatterItem.body = paramChatterBody;
                chatterLst.add(chatterItem);
            }
            
            if(chatterLst.size() > 0){
                ChatterPostUtil.chatterpostBulk(chatterLst);
            }
            
            if(!caseListToUpdate.isEmpty()){
                update caseListToUpdate;
            }
            
        }catch(Exception ex){
            System.debug('Caught Exception : '+ex);
        }
    }
    
}