public class OpportunityRejectApproval {
	@InvocableMethod
	public static void rejectApprovalFromOpportunity(List<ID> oppoIdP) {
        
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityRejectApproval.class.getName());
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, JDESentStatus__c, Property__c, RecordType.DeveloperName , Type,
                                                                   Name, AccountId, ExistingContract__r.Name, Account.TradingName__c,
                                                                   Property__r.Name, Space__r.Name, StageName,
                                                                 	(SELECT Id, Name FROM Contracts__r)
                                                                   FROM Opportunity WHERE Id IN :oppoIdP]);
        
        
    	Set<Id> oppoIds = oppMap.keySet();
    	Set<Id> pIds = (new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId in :oppoIds])).keySet();
    	Set<Id> pInstanceWorkitems = (new Map<Id, ProcessInstanceWorkitem>([SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pIds])).keySet();
    
        // START Lean/Prince RPP-10222 4/17/19
        Map<String, Schema.RecordTypeInfo> taskRecordTypeMapByDevName = RecordTypeUtil.getAllRecordTypesByDeveloperName(Constants.TASK);
        List<Task> taskList = DatabaseSOQLBank.getTasks(new Set<Id>(oppoIdP));
        Set<Id> propertyIdSet = new Set<Id>();		// Property__c of Opportunity records that will pass the conditions for notif
        Set<Opportunity> oppsToNotifySet = new Set<Opportunity>();	
        Map<Id, Task> task39ByOppId = new Map<Id, Task>();
        
        
        
        for (Task ts : taskList) {
            if(ts.Status == Constants.COMPLETED && ts.TaskType__c == Constants.TASK_TYPE_INSTRUCT_SOLICITOR) {
                task39ByOppId.put(ts.WhatId, ts);    
            }
        }
        
        // Get affected Opportunities and their Property 
        for (Opportunity op: oppMap.values()) {
            if (op.RecordType.DeveloperName == Constants.OPP_STORE_ROOM_LEASING_API_NAME) {
                if (op.JDESentStatus__c != '' && op.JDESentStatus__c != Constants.OPPO_JDE_STATUS_READY) {
                    // Storeroom AND JDESentStatus not null AND not 'Ready'
                    propertyIdSet.add(op.Property__c);
                    oppsToNotifySet.add(op);
                }
                
            } else if(task39ByOppId.containsKey(op.Id)){                
                propertyIdSet.add(op.Property__c);
                oppsToNotifySet.add(op);
            }
        }
        // --- end for loop
        
        // Query PropertyTeam of affected properties
        Map<Id, Map<String, PropertyTeam__c>> propTeamsMap = DatabaseSOQLBank.getPropertyTeamByProperty(propertyIdSet);
        
        List<Task> assignedTaskList = new List<Task>();
        List<ChatterPostUtil.chatterNotificationWrapper> chatterList = new List<ChatterPostUtil.chatterNotificationWrapper>();
        
        // Loop on affected Opportunities
        for (Opportunity opp: oppsToNotifySet) {
            
            if (propTeamsMap.containsKey(opp.Property__c)) {
            	Map<String, PropertyTeam__c> propTeam = propTeamsMap.get(opp.Property__c);
                Set<Id> revAdmins = new Set<Id>();
                for (String role: propTeam.keySet()) {
                    
                    if (role == Constants.TEAM_ROLE_REV_ADMIN) {
                        Task adhocTask = new Task();
                        adhocTask.Opportunity__c = opp.Id;
                        adhocTask.OwnerId = propTeam.get(role).TeamMember__c;
                        adhocTask.RecordTypeId = taskRecordTypeMapByDevName.get(Constants.TAS_ADHOC_DEV_NAME).getRecordTypeId();
                        adhocTask.Status = Constants.OPEN;
                        adhocTask.Subject = Label.RevenueAssuranceNotification;
                        adhocTask.WhatId = opp.Id;
                        assignedTaskList.add(adhocTask);
                        revAdmins.add(propTeam.get(role).TeamMember__c);
                    }
                    
                }
                
                chatterList.add(ChatterPostUtil.ChatterPostToRevenueAssurance(opp, revAdmins));
                
            }
        }
        // END Lean/Prince RPP-10222 4/17/19
        
    	Approval.ProcessWorkitemRequest[] allReq = New Approval.ProcessWorkitemRequest[]{}; 
    	for (Id pInstanceWorkitemsId:pInstanceWorkitems) {
        	system.debug(pInstanceWorkitemsId);
        	Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        	req2.setComments('Opportunity is cancelled');
        	req2.setAction('Reject'); //to approve use 'Approve'
        	req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
    
        	// Use the ID from the newly created item to specify the item to be worked
        	req2.setWorkitemId(pInstanceWorkitemsId);

        	// Add the request for approval
        	allReq.add(req2);
    	}
    	Approval.ProcessResult[] result2 =  Approval.process(allReq);
     
    	//Select all open tasks and cancel them
    	List<Task> tasks = [Select id, status From Task Where WhatId in :oppoIdP];
      	for (Task task : tasks) {
        	task.status = 'Cancelled';
      	}
      	update tasks;
    
        // If opportunity is closed - cancelled, it should remove from space latest achieved opportunity
    	List<Space__c> spacesWithOppos = [Select Id, LatestAchievedOpportunity__c From Space__c Where LatestAchievedOpportunity__r.DealAchieved__c = true and LatestAchievedOpportunity__c in: oppoIdP];
    	System.debug('spacesWithOppos ' + spacesWithOppos);
    	for (Space__c space : spacesWithOppos) {
    		space.LatestAchievedOpportunity__c = null;
    	}
    	if (spacesWithOppos.size() > 0) {
   			update spacesWithOppos;   
    	}
        
        
        // START Lean/Prince RPP-10222 4/17/19
        if (chatterList.size() > 0) {
            ChatterPostUtil.chatterpostBulk(chatterList);
        }
        
        if (assignedTaskList.size() > 0) {
            try {
                database.insert(assignedTaskList);
            } catch (Exception e) {
                errorHandler.createError(e);
            }
        }        
        
        errorHandler.save();
        // END Lean/Prince RPP-10222 4/17/19
        
	}
}