/**
* @Author: Lean Flores
* @Description: Invocable Task Utility Class
*/
public class TaskUtilityInvocable {
    /**
* @Author: Lean Flores
* @Parameter: List of case Ids
* @Description: called in the process builder to create 'Send Documents for Execution' 
*/
    @InvocableMethod 
    public static void createSendDocsFromCase(List<Id> caseId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(TaskUtilityInvocable.class.getName());
        Case sourceCase = [SELECT Id, ParentId, CurrencyIsoCode, TechRetailAdmin__c, Opportunity__c, SubType__c, OwnerId, Space__r.Status__c, Space__r.Property__c
                           FROM Case
                           WHERE Id In:caseId];
        
        Task newTask = new Task();
        newTask.ActivityDate = Date.today().addDays(1); // SkipWeekends??
        newTask.KPI__c = 1;
        newTask.Priority = Constants.TASK_PRIORITY_NORMAL;
        newTask.RecordTypeId = Label.TASAutomaticRecordTypeId;
        newTask.Subject = 'Send Documents for Execution';
        newTask.TaskType__c = Constants.TASK_TYPE_SEND_DOCS_FOR_EXECUTION;
        newTask.CurrencyIsoCode = sourceCase.CurrencyIsoCode;
        
        if (Constants.CASE_SUBTYPE_LEASE_CHECKSHEET.equalsIgnoreCase(sourceCase.SubType__c) || Constants.CASE_SUBTYPE_VARIATION_CHECKSHEET.equalsIgnoreCase(sourceCase.SubType__c)) {
            newTask.WhatId = sourceCase.Opportunity__c;
        } else if (Constants.CASE_SUBTYPE_SURRENDER_CHECKSHEET.equalsIgnoreCase(sourceCase.SubType__c) || Constants.CASE_SUBTYPE_ASSIGNMENT_CHECKSHEET.equalsIgnoreCase(sourceCase.SubType__c)) {
            newTask.WhatId = sourceCase.ParentId;
        }
        
        
        Opportunity relatedOpp = null;
        
        try {
            relatedOpp = [SELECT Id, Tech_isCreatedFromGroupRenew__c, RecordType.DeveloperName, SpecialityLeaseType__c, CurrencyIsoCode, Type
                          FROM Opportunity
                          WHERE Id=:sourceCase.Opportunity__c];
        } catch (Exception e) {
            errorHandler.createError('No related Opportunity for Case', String.valueOf(caseId[0]));
        }
        
        if (relatedOpp != null) {
            String businessUnit = '';
            String leaseType = relatedOpp.Type != null ? relatedOpp.Type : '';
            String specialityLeaseType = String.isBlank(relatedOpp.SpecialityLeaseType__c) ? Constants.STR_DEFAULT : relatedOpp.SpecialityLeaseType__c;
            
            if (Constants.OPP_RETAIL_LEASING_API_NAME.equalsIgnoreCase(relatedOpp.RecordType.DeveloperName)) {
                businessUnit = Constants.RETAIL;
            } else if (Constants.OPP_COMMERCIAL_LEASING_API_NAME.equalsIgnoreCase(relatedOpp.RecordType.DeveloperName)) {
                businessUnit = Constants.COMMERCIAL;
            } else if (Constants.OPP_STORE_ROOM_LEASING_API_NAME.equalsIgnoreCase(relatedOpp.RecordType.DeveloperName)) {
                businessUnit = Constants.STOREROOMTYPE;
            }     
            
            
            // START Task Template 
            Map<Id, TaskTemplateAndCondition__c> taskTemplatesMap = DatabaseSOQLBank.getTaskTemplate(Constants.TASK, new Set<String>{businessUnit}, new Set<String>{leaseType}, new Set<String>{specialityLeaseType});
            
            TaskTemplateAndCondition__c matchedTaskTemplate = null;
            
            if (taskTemplatesMap.values() != null && taskTemplatesMap.values().size() > 0) {
                for (TaskTemplateAndCondition__c taskTemplate : taskTemplatesMap.values()) {
                    if (newTask.TaskType__c.equalsIgnoreCase(taskTemplate.TaskType__c) && taskTemplate.ApplicableCountry__c != null && taskTemplate.ApplicableCountry__c.contains(relatedOpp.CurrencyIsoCode)) {
                        
                        matchedTaskTemplate = taskTemplate;
                        newTask.TECHTaskTemplateId__c = taskTemplate.Id;
                        
                        // Due Date Computation
                        if (matchedTaskTemplate.DueDate__c != null && matchedTaskTemplate.DueDate__c > 0) {
                            newTask.ActivityDate = matchedTaskTemplate.SkipWeekends__c ? TaskUtility.getDueDate(Date.today(), Integer.valueOf(matchedTaskTemplate.DueDate__c)) : Date.today().addDays(Integer.valueOf(matchedTaskTemplate.DueDate__c));
                            newTask.KPI__c = matchedTaskTemplate.DueDate__c;
                        } 
                        
                        
                        break;
                    }
                }
            }
            
            // END Task Template
            
            
            // Assigned to ID 
            Id taskOwner = sourceCase.OwnerId;
            
            Map<Id, Map<String, PropertyTeam__c>> propertyTeamsByProperty = TaskUtility.getPropertyTeamPerProperty(new Set<Id>{sourceCase.Space__r.Property__c});
            Map<String, PropertyTeam__c> propertyTeamByRole = null;
            
            
            if (propertyTeamsByProperty.size() > 0 && propertyTeamsByProperty.containsKey(sourceCase.Space__r.Property__c)) {
                propertyTeamByRole = propertyTeamsByProperty.get(sourceCase.Space__r.Property__c);
            }
            system.debug('ZZZ TaskTemplate Matched ' + matchedTaskTemplate);
            if (propertyTeamByRole != null) {
                if (relatedOpp.Tech_isCreatedFromGroupRenew__c && matchedTaskTemplate != null && !String.isBlank(matchedTaskTemplate.GroupRenewalRole__c) && propertyTeamByRole.containsKey(matchedTaskTemplate.GroupRenewalRole__c)) {
                    taskOwner = propertyTeamByRole.get(matchedTaskTemplate.GroupRenewalRole__c).TeamMember__c;
                } else if (Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(sourceCase.Space__r.Status__c) && propertyTeamByRole.containsKey(Constants.TEAM_ROLE_PRA)) {
                    taskOwner = propertyTeamByRole.get(Constants.TEAM_ROLE_PRA).TeamMember__c;
                } else if (propertyTeamByRole.containsKey(Constants.TEAM_ROLE_RA)) {
                    taskOwner = propertyTeamByRole.get(Constants.TEAM_ROLE_RA).TeamMember__c;
                }
            }
            
            newTask.OwnerId = taskOwner;
            
            try {
                Database.insert(newTask);
            } catch(Exception e){
                errorHandler.createError(e);
            }            
        }
        
        errorHandler.save();
    }
}