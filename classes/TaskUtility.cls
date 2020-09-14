public class TaskUtility {
    //private static Set<Id> jvRequiredOppIdSet = new Set<Id>();
    private static Set<Id> linkIdWithLeasePlanSet = new Set<Id>();
    
    public class TaskOwnerWrapper{
        public Map<Id, Map<String, OpportunityTeamMember>> oppTeamMemberMap = new Map<Id, Map<String, OpportunityTeamMember>>();
        public Map<Id, Map<String, PropertyTeam__c>> propertyTeamMemberMap = new Map<Id, Map<String, PropertyTeam__c>>();
        public Map<Id, Map<String, AccountTeamMember>> accountTeamMemberMap = new Map<Id, Map<String, AccountTeamMember>>(); 
    }
    
    public static Set<Id> getSpaceWithLeasePlan(Set<Id> spaceIdSet){
        Set<Id> cDocumentIdSet = new Set<Id>();
        Map<Id, ContentDocumentLink> docIdCDocLinkMap = new Map<Id, ContentDocumentLink>();
        
        if(spaceIdSet != null && !spaceIdSet.isEmpty()){
            for(ContentDocumentLink cDocumentLink : DatabaseSOQLBank.getContentDocumentLink(spaceIdSet)){
                cDocumentIdSet.add(cDocumentLink.ContentDocumentId);
                docIdCDocLinkMap.put(cDocumentLink.ContentDocumentId, cDocumentLink);
            }
            
            try{
                for(ContentVersion cVersion : DatabaseSOQLBank.getLeasePlanFile(cDocumentIdSet)){
                    if(docIdCDocLinkMap.containsKey(cVersion.ContentDocumentId)){
                        linkIdWithLeasePlanSet
                            .add(
                                docIdCDocLinkMap.get(cVersion.ContentDocumentId).LinkedEntityId
                            );
                    }
                }
            } catch(Exception e){
                linkIdWithLeasePlanSet = null;
            }
        }
        
        return linkIdWithLeasePlanSet;
    }
    
    public static Boolean isJVRequired(Opportunity opp, Property__c property, List<PropertyOwnership__c> propOwnershipList){
        Boolean isJVrequired = false;
        
        if(property.DexusProperty__c){
            isJVrequired = true;
        }
        
        if(!isJVrequired && propOwnershipList != null){
            for(PropertyOwnership__c propOwner : propOwnershipList){
                isJVrequired = isJVrequired(opp, propOwner);
                
                if(isJVrequired){
                    break;
                }
            }
        }
        
        return isJVrequired;
    }
    
    private static Boolean isJVrequired(Opportunity opp, PropertyOwnership__c propOwner){
        Boolean isJVRequired = false;
        Decimal capitalDiff;
        Decimal budgetCapital = opp.JVBudgetCapital__c != null ? opp.JVBudgetCapital__c : 0;
        Decimal totalForecastCap = opp.TotalForecastCapital__c != null ? opp.TotalForecastCapital__c : 0;
        
        capitalDiff = totalForecastCap - budgetCapital;
        System.debug('JVRentVariance__c === ' + opp.JVRentVariance__c +' < RentApprovalTolerance__c === '+propOwner.RentApprovalTolerance__c);
        System.debug('JVCapitalVariance__c === ' + opp.JVCapitalVariance__c +' > CapitalApprovalTolerance__c === '+propOwner.CapitalApprovalTolerance__c);
        System.debug('TotalForecastCapital__c === ' + opp.TotalForecastCapital__c +' > CapitalApprovalToleranceCurrency__c === '+propOwner.CapitalApprovalToleranceCurrency__c);
        if(opp.JVRentVariance__c < propOwner.RentApprovalTolerance__c){
            isJVRequired = true;
        } else if(opp.JVCapitalVariance__c > propOwner.CapitalApprovalTolerance__c){
            isJVRequired = true;
        } else if(opp.TotalForecastCapital__c > propOwner.CapitalApprovalToleranceCurrency__c){
            isJVRequired = true;
        }
        System.debug('isJVRequired === '+isJVRequired);
        return isJVRequired;
    }
    
    public static TaskOwnerWrapper getOppAndPropertyTeamMember(Set<Id> propertyIdSet, Set<Id> opportunityIdSet, Set<Id> accountIdSet){
        TaskOwnerWrapper taskOwnerWrap = new TaskOwnerWrapper();
        
        taskOwnerWrap.accountTeamMemberMap = getAccountTeamPerAccount(accountIdSet);
        taskOwnerWrap.propertyTeamMemberMap = getPropertyTeamPerProperty(propertyIdSet);
        taskOwnerWrap.oppTeamMemberMap = getOpportunityTeamPerOpportunity(opportunityIdSet);
        
        return taskOwnerWrap;
    }
    
    public static Map<Id, Map<String, AccountTeamMember>> getAccountTeamPerAccount (Set<Id> accountIdSet) {
        Map<Id, Map<String, AccountTeamMember>> accountIdPropertyTeamMapMap = new Map<Id, Map<String, AccountTeamMember>>();
        
        try{
            accountIdPropertyTeamMapMap = DatabaseSOQLBank.getAccountTeamPerAccount(accountIdSet);
        } catch(Exception e){
            accountIdPropertyTeamMapMap = null;
        }
        
        return accountIdPropertyTeamMapMap;
    }
    
    public static Map<Id, Map<String, PropertyTeam__c>> getPropertyTeamPerProperty (Set<Id> propertyIdSet) {
        List<PropertyTeam__c> teamMemberList;
        Map<String, PropertyTeam__c> roleTeamMemberMap;
        Map<Id, Map<String, PropertyTeam__c>> propertyIdPropertyTeamMapMap = new Map<Id, Map<String, PropertyTeam__c>>();
        
        try{
            teamMemberList = DatabaseSOQLBank.getPropertyTeam(propertyIdSet);
        } catch(Exception e){
            teamMemberList = null;
        }
        
        system.debug('teamMemberList : ' + teamMemberList);
        
        if(teamMemberList != null && teamMemberList.size() > 0){
            for (PropertyTeam__c teamMember : teamMemberList) {
                if(teamMember.TeamMember__c != null){
                    if(propertyIdPropertyTeamMapMap.containsKey(teamMember.Property__c)){
                        roleTeamMemberMap = propertyIdPropertyTeamMapMap.get(teamMember.Property__c);
                        roleTeamMemberMap.put(teamMember.Role__c, teamMember);
                    } else {
                        roleTeamMemberMap = new Map<String, PropertyTeam__c>();
                        roleTeamMemberMap.put(teamMember.Role__c, teamMember);
                        propertyIdPropertyTeamMapMap.put(teamMember.Property__c, roleTeamMemberMap);
                    }
                }
            }
        }
        
        return propertyIdPropertyTeamMapMap;
    }
    
    public static Map<Id, Map<String, OpportunityTeamMember>> getOpportunityTeamPerOpportunity (Set<Id> opportunityIdSet) {
        List<OpportunityTeamMember> teamMemberList;
        Map<String, OpportunityTeamMember> roleTeamMemberMap;
        Map<Id, Map<String, OpportunityTeamMember>> opportunityIdOppTeamMapMap = new Map<Id, Map<String, OpportunityTeamMember>>();
        
        try{
            teamMemberList = DatabaseSOQLBank.getOpportunityTeamMember(opportunityIdSet);
        } catch(Exception e){
            teamMemberList = null;
        }
        
        if(teamMemberList != null && teamMemberList.size() > 0){
            for (OpportunityTeamMember teamMember : teamMemberList) {
                if(teamMember.UserId != null){
                    if(opportunityIdOppTeamMapMap.containsKey(teamMember.OpportunityId)){
                        roleTeamMemberMap = opportunityIdOppTeamMapMap.get(teamMember.OpportunityId);
                        roleTeamMemberMap.put(teamMember.TeamMemberRole, teamMember);
                    } else {
                        roleTeamMemberMap = new Map<String, OpportunityTeamMember>();
                        roleTeamMemberMap.put(teamMember.TeamMemberRole, teamMember);
                        opportunityIdOppTeamMapMap.put(teamMember.OpportunityId, roleTeamMemberMap);
                    }
                }
            }
        }
        
        return opportunityIdOppTeamMapMap;
    }
    
    public static Map<Id, List<TaskTemplateAndCondition__c>> getDependentTaskTemplate(List<TaskTemplateAndCondition__c> taskTemplateList){
        Map<Id, List<TaskTemplateAndCondition__c>> taskTemplateMap = new Map<Id, List<TaskTemplateAndCondition__c>>();
        
        for(TaskTemplateAndCondition__c taskTemplate : taskTemplateList){
            if(taskTemplateMap.containsKey(taskTemplate.DependentTask__c)){
                taskTemplateMap.get(taskTemplate.DependentTask__c).add(taskTemplate);
            } else {
                taskTemplateMap.put(
                    taskTemplate.DependentTask__c, 
                    new List<TaskTemplateAndCondition__c>{
                        taskTemplate
                            }
                );
            }
        }
        
        return taskTemplateMap;
    }
    
    public static List<Task> createCaseTask(Case cas, String caseRecordTypeName, Id taskRecordTypeId, List<TaskTemplateAndCondition__c> taskTemplateList, 
                                            TaskOwnerWrapper taskOwnerWrap, Account account){
                                                Id ownerOriginId;
                                                List<Task> newTaskList = new List<Task>();
                                                
                                                for(TaskTemplateAndCondition__c taskTemplate : taskTemplateList){
                                                    System.debug('cas.RecordTypeId: '+cas.RecordTypeId);
                                                    if(cas.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST){
                                                        ownerOriginId = cas.ownerId;
                                                    }else if(Constants.PROPERTY_TEAM.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                        ownerOriginId = cas.TechPropertyId__c;
                                                    }else {
                                                        ownerOriginId = cas.ownerId;
                                                    }
                                                    
                                                    if(doCreateCaseTask(cas, caseRecordTypeName, taskTemplate)){
                                                        newTaskList.add(
                                                            createTaskFromTemplate(
                                                                false, cas.Id, taskRecordTypeId, taskTemplate, taskOwnerWrap, ownerOriginId, account, null, null, null
                                                            )
                                                        );
                                                    }
                                                }
                                                
                                                System.debug('newTaskList'+ newTaskList);
                                                return newTaskList;
                                            }
    
    private static Boolean doCreateCaseTask(Case cas, String caseRecordTypeName, TaskTemplateAndCondition__c taskTemplate){
        String propertyCountry;
        Boolean doCreate = true;
        System.debug('taskTemplate === '+taskTemplate);
        System.debug('caseRecordTypeName === '+caseRecordTypeName);
        System.debug('CaseRecordType__c === '+taskTemplate.CaseRecordType__c);
        
        if(String.isNotBlank(caseRecordTypeName)){
            if(!caseRecordTypeName.equalsIgnoreCase(taskTemplate.CaseRecordType__c)){
                doCreate = false;
            }
        }
        
        if(cas.SubType__c == Constants.CASE_SUBTYPE_COVID_RENT_REQUEST && taskTemplate.CaseRecordType__c == Constants.LVI_COVID19){
            
            if(cas.Status == Constants.CASE_STATUS_COMPLETED_REJECTED){
                if(taskTemplate.TaskType__c == Constants.TASKTEMPLATE_UPDATE_CASE_TERMS)
                    return TRUE;
                else
                    return FALSE;
            }
            
            if(taskTemplate.TaskType__c == Constants.TASKTEMPLATE_GENERATE_OFFER_LETTER)
                return TRUE;
            
        }
        
        
        System.debug('ApplicableCountry__c === '+taskTemplate.ApplicableCountry__c);
        System.debug('TECHPropertyCountry__c === '+cas.TECHPropertyCountry__c);
        
        if(cas.TECHPropertyCountry__c != null && !String.isEmpty(cas.TECHPropertyCountry__c)){
            if(!taskTemplate.ApplicableCountry__c.contains(cas.TECHPropertyCountry__c)){
                doCreate = false;
            }
        } else {
            doCreate = false;
        }
        System.debug('Finally === '+doCreate);
        return doCreate;
    }
    
    public static List<Task> createOpportunityTask(Opportunity opp, Opportunity oldOpp, String oppRecordTypeName, 
                                                   Id taskRecordTypeId, List<TaskTemplateAndCondition__c> taskTemplateList, TaskOwnerWrapper taskOwnerWrap, Account account, 
                                                   Property__c oppProperty, Boolean isStageChange, Space__c oppSpace){
                                                       Id ownerOriginId;
                                                       List<Task> newTaskList = new List<Task>();
                                                       
                                                       if(OpportunityReversal.opptyReversed)
                                                           return newTaskList;
                                                       
                                                       for(TaskTemplateAndCondition__c taskTemplate : taskTemplateList){
                                                           ownerOriginId = null;
                                                           system.debug('INSIDE createOpportunityTask');
                                                           if(doCreateOppTask(opp, oldOpp, oppRecordTypeName, taskTemplate, isStageChange)){
                                                               system.debug('CREATE OPP TASK');
                                                               if(Constants.OPPORTUNITY_OWNER.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                                   ownerOriginId = opp.OwnerId;
                                                               } else if(Constants.OPPORTUNITY_TEAM.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                                   ownerOriginId = opp.Id;
                                                               } else if(Constants.PROPERTY_TEAM.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                                   ownerOriginId = opp.Property__c;
                                                               }
                                                               
                                                               newTaskList.add(
                                                                   createTaskFromTemplate(
                                                                       opp.Tech_isCreatedFromGroupRenew__c, opp.Id, taskRecordTypeId, taskTemplate, taskOwnerWrap, ownerOriginId, account, oppProperty, oppSpace, opp.Group_Renewal_Retail_Admin__c
                                                                   )
                                                               );
                                                           }
                                                       }
                                                       
                                                       return newTaskList;
                                                   }
    
    private static Boolean doCreateOppTask(Opportunity opp, Opportunity oldOpp, String oppRecordTypeName, 
                                           TaskTemplateAndCondition__c taskTemplate, Boolean isStageChange){
                                               String propertyState = opp.Tech_PropertyState__c;
                                               Boolean doCreate = true;
                                               //Boolean isJVrequired = false;
                                               Boolean isLeasePlanAttached = false;
                                               String businessUnit;
                                               System.debug('INSDIE doCreateOppTask'+taskTemplate);
                                               
                                               if(opp != null){
                                                   if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(oppRecordTypeName) 
                                                      && (opp.AnnualMinimumRent__c == 0 || opp.AnnualMinimumRent__c == null)
                                                      && Constants.PROPOSE_ACCEPT.equalsIgnoreCase(opp.StageName)){
                                                          //doCreate = false;
                                                      }
                                                   
                                                   if(Constants.OPPORTUNITY.equalsIgnoreCase(taskTemplate.Object__c) 
                                                      && isStageChange != taskTemplate.IsStageChange__c){
                                                          System.debug('here lala'+taskTemplate);
                                                          doCreate = false;
                                                      }
                                                   
                                                   if(Constants.OPPORTUNITY.equalsIgnoreCase(taskTemplate.Object__c) 
                                                      && !isStageChange && !taskTemplate.IsStageChange__c && oldOpp != null){
                                                          System.debug('1 + 1: ' + Constants.FINAL_APPROVAL_GRANTED.equalsIgnoreCase(opp.ApprovalStatus__c));
                                                          System.debug('1 + 2: ' + opp.ApprovalStatus__c == oldOpp.ApprovalStatus__c );
                                                          if(Constants.GENERATE_OWNER_PACK_SUBMIT_JV_APPROVAL.equalsIgnoreCase(taskTemplate.TaskType__c)
                                                             && (opp.ApprovalStatus__c == oldOpp.ApprovalStatus__c 
                                                                 || (opp.ApprovalStatus__c != oldOpp.ApprovalStatus__c 
                                                                     && !Constants.FINAL_APPROVAL_GRANTED.equalsIgnoreCase(opp.ApprovalStatus__c)))){
                                                                         doCreate = false;
                                                                     }
                                                          
                                                          if(Constants.REV_ASSURANCE_MANUAL_PROCESSING.equalsIgnoreCase(taskTemplate.TaskType__c)
                                                             && (opp.JDESentStatus__c == oldOpp.JDESentStatus__c || 
                                                                 (opp.JDESentStatus__c != oldOpp.JDESentStatus__c 
                                                                  && !Constants.MANUAL.equalsIgnoreCase(opp.JDESentStatus__c)))){
                                                                      doCreate = false;
                                                                  }
                                                      }
                                                   
                                                   if(opp.Account_Type__c == Constants.FORECAST)
                                                       doCreate = false;
                                                   
                                                   if(doCreate){
                                                       if(Constants.OPP_COMMERCIAL_LEASING.equalsIgnoreCase(oppRecordTypeName)){
                                                           businessUnit = Constants.COMMERCIAL;
                                                       } else if(Constants.OPP_RETAIL_LEASING.equalsIgnoreCase(oppRecordTypeName)){
                                                           businessUnit = Constants.RETAIL;
                                                       } else if(Constants.OPP_STORE_ROOM_LEASING.equalsIgnoreCase(oppRecordTypeName)){
                                                           businessUnit = Constants.STOREROOMTYPE;
                                                       }
                                                       
                                                       system.debug(taskTemplate + ' businessUnit : ' + businessUnit);
                                                       system.debug('opp-->' + opp);
                                                       if(!businessUnit.equalsIgnoreCase(taskTemplate.BusinessUnit__c) || !taskTemplate.LeaseType__c.contains(opp.Type) ||
                                                          (!opp.StageName.equalsIgnoreCase(taskTemplate.OpportunityStage__c) && String.isNotBlank(taskTemplate.OpportunityStage__c))){
                                                              doCreate = false;
                                                          } else if(!taskTemplate.ApplicableCountry__c.contains(opp.CurrencyIsoCode)){
                                                              /*system.debug('taskTemplate.Applicable_States__c: '+taskTemplate.Applicable_States__c);
system.debug('propertyState: '+propertyState);
if((taskTemplate.Applicable_States__c != null)&&(!taskTemplate.Applicable_States__c.contains(propertyState))){
doCreate = false;
}else if(taskTemplate.Applicable_States__c == null){
doCreate = true;
}*/
                                                              doCreate = false;
                                                              
                                                          }else if(taskTemplate.ApplicableCountry__c.contains(opp.CurrencyIsoCode)){
                                                              if(taskTemplate.Applicable_States__c != null){
                                                                  if(!taskTemplate.Applicable_States__c.contains(propertyState))
                                                                      doCreate = false;
                                                              }
                                                          } else if(opp.SpecialityLeaseType__c != null){
                                                              if(!opp.SpecialityLeaseType__c.equalsIgnoreCase(taskTemplate.SpecialtyLeaseType__c)){
                                                                  doCreate = false;
                                                              }
                                                          } else if(opp.SpecialityLeaseType__c == null && !Constants.STR_DEFAULT.equalsIgnoreCase(taskTemplate.SpecialtyLeaseType__c)){
                                                              
                                                              doCreate = false;
                                                          }
                                                   }
                                                   
                                                   if(doCreate){
                                                       
                                                       if(linkIdWithLeasePlanSet.contains(opp.Space__c)){
                                                           isLeasePlanAttached = true;
                                                       }                
                                                       
                                                       if(isLeasePlanAttached && Constants.PROVIDE_LEASE_PLAN_TASK_API.equalsIgnoreCase(taskTemplate.TaskType__c)){
                                                           doCreate = false;
                                                       }
                                                       
                                                       if(Constants.PROPOSE_ACCEPT.equalsIgnoreCase(opp.StageName)){
                                                           if(!opp.TECHJVRequired__c && Constants.REQUIRED.equalsIgnoreCase(taskTemplate.JVApproval__c)){
                                                               doCreate = false;
                                                           } else if(opp.TECHJVRequired__c && Constants.NOT_REQUIRED.equalsIgnoreCase(taskTemplate.JVApproval__c)){
                                                               doCreate = false;
                                                           }
                                                       } 
                                                   }
                                               }
                                               system.debug('finaldoCreate' + doCreate);
                                               return doCreate;
                                           }
    
    public static List<Task> createTask(SObject parentObject, Id taskRecordTypeId, 
                                        List<TaskTemplateAndCondition__c> taskTemplateList, TaskOwnerWrapper taskOwnerWrap, Account account, Property__c property, Space__c space) {
                                            Id ownerOriginId;
                                            String propertyFieldAPI;
                                            List<Task> newTaskList = new List<Task>();
                                            
                                            if(parentObject instanceof Opportunity){
                                                propertyFieldAPI = Constants.PROPERTY;
                                            } else if(parentObject instanceof Case){
                                                propertyFieldAPI = Constants.TECH_PROPERTY_ID;
                                            }
                                            
                                            for(TaskTemplateAndCondition__c taskTemplate : taskTemplateList){
                                                ownerOriginId = null;
                                                
                                                if(Constants.OPPORTUNITY_OWNER.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                    ownerOriginId = (Id) parentObject.get(Constants.OWNER_ID);
                                                } else if(Constants.OPPORTUNITY_TEAM.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                    ownerOriginId = parentObject.Id;
                                                } else if(Constants.PROPERTY_TEAM.equalsIgnoreCase(taskTemplate.AssigneesTeam__c)){
                                                    ownerOriginId = (Id) parentObject.get(propertyFieldAPI);
                                                } else if (parentObject instanceof Case) {
                                                    ownerOriginId = (Id) parentObject.get(Constants.OWNER_ID);
                                                }
                                                
                                                Boolean isCreatedFromGroupRenew = FALSE;
                                                isCreatedFromGroupRenew = parentObject instanceof Opportunity ? (Boolean) parentObject.get('Tech_IsCreatedFromGroupRenew__c') : false;
                                                Id oppGroupRenewalAdminId = isCreatedFromGroupRenew ? (Id) parentObject.get('Group_Renewal_Retail_Admin__c') : NULL;
                                                
                                                if(doCreateTask(parentObject, taskTemplate)){
                                                    if(oppGroupRenewalAdminId != NULL){
                                                        newTaskList.add(
                                                            createTaskFromTemplate(
                                                                isCreatedFromGroupRenew, parentObject.Id, taskRecordTypeId, taskTemplate, taskOwnerWrap, ownerOriginId, account, property, space, oppGroupRenewalAdminId
                                                            )
                                                        );  
                                                    }else{
                                                        newTaskList.add(
                                                            createTaskFromTemplate(
                                                                isCreatedFromGroupRenew, parentObject.Id, taskRecordTypeId, taskTemplate, taskOwnerWrap, ownerOriginId, account, property, space, null
                                                            )
                                                        );
                                                    }
                                                }
                                            }
                                            
                                            system.debug('newTaskList : ' + newTaskList);
                                            system.debug('taskTemplateList : ' + taskTemplateList);
                                            
                                            return newTaskList;
                                        }
    
    private static Boolean doCreateTask(SObject parentObject, TaskTemplateAndCondition__c taskTemplate){
        Boolean doCreate = true;
        Opportunity opp;
        
        if(parentObject instanceof Opportunity){
            Decimal calcTemp;
            Decimal lessorWorks;
            Decimal totalDCCostTemp;
            
            opp = (Opportunity) parentObject;
            
            if(opp.TotalFitoutContribution__c <= 0 && Constants.OBLIGATIONS_RECEIVED_TASK_API.equalsIgnoreCase(taskTemplate.TaskType__c)){
                doCreate = false;
            }
            
            totalDCCostTemp = opp.TotalDCCost__c != null ? opp.TotalDCCost__c : 0;
            lessorWorks = opp.TotalLessorWorksCost__c != null ? opp.TotalLessorWorksCost__c : 0;
            calcTemp = totalDCCostTemp + lessorWorks;
            
            /*if(Constants.UPDATE_COSE_ESTIMATE.equalsIgnoreCase(taskTemplate.TaskType__c) && !opp.TECH_UpdateCostEstimateRequired__c){
doCreate = false;
}*/ 
            
            if(doCreate){
                doCreate = doCreateOppTask(opp, null, opp.RecordType.Name, taskTemplate, false);
            }
        } else if(parentObject instanceof Case){
            
            doCreate = checkForCovidCases(parentObject, taskTemplate);
            
            
        }
        
        return doCreate;
    }
    
    private static Task createTaskFromTemplate(Boolean isCreatedFromGroupRenew, Id recordId, Id taskRecordTypeId, TaskTemplateAndCondition__c templateRecord, 
                                               TaskOwnerWrapper taskOwnerWrap, Id ownerOriginId, Account account, Property__c oppProperty, Space__c oppSpace, Id oppGroupRenewalAdminId)
    {
        System.debug('Chen debug ' + templateRecord.TaskName__c);
        Id taskOwner = UserInfo.getUserId();
        Date dueDate = System.Today();
        Boolean isAssignedToAccountTeam = false;
        Boolean isAssignedToProjectTeam = false;
        Task newTaskRecord = new Task();
        PropertyTeam__c propTeamTemp;
        OpportunityTeamMember oppTeamMemberTemp;
        Map<String, SObject> roleTeamMemberMap;
        
        newTaskRecord.WhatId = recordId;
        newTaskRecord.RecordTypeId = taskRecordTypeId;
        newTaskRecord.IsReminderSet=true;
        newTaskRecord.ReminderDateTime=System.Now();
        newTaskRecord.Subject = templateRecord.TaskName__c;
        newTaskRecord.TaskType__c = templateRecord.TaskType__c;
        newTaskRecord.Description = templateRecord.TaskDescription__c;     
        newTaskRecord.KPI__c = templateRecord.DueDate__c; 
        newTaskRecord.CreatedfromTaskTemplate__c = true;
        newTaskRecord.TECHTaskTemplateId__c = templateRecord.Id;
        
        if(oppProperty != null && !oppProperty.DexusProperty__c
           && Constants.GENERATE_OWNER_PACK_SUBMIT_JV_APPROVAL.equalsIgnoreCase(templateRecord.TaskType__c)){
               newTaskRecord.Description = null;
           }
        
        if(recordId.getSObjectType() == Schema.Opportunity.SObjectType){
            newTaskRecord.Opportunity__c = recordId;
        }else if(recordId.getSObjectType() == Schema.Case.SObjectType){
            newTaskRecord.Case__c = recordId;
        }
        
        if(!Constants.OPPORTUNITY_OWNER.equalsIgnoreCase(templateRecord.AssigneesTeam__c) && !Constants.CASE_OWNER.equalsIgnoreCase(templateRecord.AssigneesTeam__c)){
            if(account!= null && templateRecord.AccountTeamRole__c != null){
                if(taskOwnerWrap.accountTeamMemberMap.containsKey(account.ParentId)){
                    roleTeamMemberMap = taskOwnerWrap.accountTeamMemberMap.get(account.ParentId);
                } else if(taskOwnerWrap.accountTeamMemberMap.containsKey(account.Parent.ParentId)){
                    roleTeamMemberMap = taskOwnerWrap.accountTeamMemberMap.get(account.Parent.ParentId);
                }
                
                if(roleTeamMemberMap != null && roleTeamMemberMap.containsKey(Constants.TEAM_ROLE_RDAM)){
                    taskOwner = ((AccountTeamMember) roleTeamMemberMap.get(Constants.TEAM_ROLE_RDAM)).UserId;
                    isAssignedToAccountTeam = true;
                }
            }
            
            system.debug('oppSpace : ' + oppSpace);
            system.debug('oppProperty : ' + oppProperty);
            system.debug('isAssignedToAccountTeam : ' + isAssignedToAccountTeam);
            //system.debug('Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(oppSpace.Status__c)  : ' + Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(oppSpace.Status__c) );
            
            if(!isAssignedToAccountTeam && oppSpace != null && Constants.SPACE_STATUS_PROJECT.equalsIgnoreCase(oppSpace.Status__c) 
               && oppProperty != null){
                   roleTeamMemberMap = taskOwnerWrap.propertyTeamMemberMap.get(oppProperty.Id);
                   system.debug('templateRecord.ProjectTeamRole__c : ' + templateRecord.ProjectTeamRole__c);
                   //system.debug('roleTeamMemberMap.containsKey(templateRecord.ProjectTeamRole__c) : ' + roleTeamMemberMap.containsKey(templateRecord.ProjectTeamRole__c));
                   
                   if(roleTeamMemberMap != null && roleTeamMemberMap.containsKey(templateRecord.ProjectTeamRole__c)){
                       propTeamTemp = (PropertyTeam__c) roleTeamMemberMap.get(templateRecord.ProjectTeamRole__c);
                       taskOwner = propTeamTemp.TeamMember__c;
                       isAssignedToProjectTeam = true;
                   }
               }
            
            if(!isAssignedToAccountTeam && !isAssignedToProjectTeam){
                if(Constants.OPPORTUNITY_TEAM.equalsIgnoreCase(templateRecord.AssigneesTeam__c)){
                    roleTeamMemberMap = taskOwnerWrap.oppTeamMemberMap.get(ownerOriginId);
                } else if(Constants.PROPERTY_TEAM.equalsIgnoreCase(templateRecord.AssigneesTeam__c)){
                    roleTeamMemberMap = taskOwnerWrap.propertyTeamMemberMap.get(ownerOriginId);
                }
                
                if(roleTeamMemberMap != null && roleTeamMemberMap.containsKey(templateRecord.AssignTo__c)){
                    if(roleTeamMemberMap.get(templateRecord.AssignTo__c) instanceof PropertyTeam__c){
                        propTeamTemp = (PropertyTeam__c) roleTeamMemberMap.get(templateRecord.AssignTo__c);
                        system.debug('propTeamTemp : ' + propTeamTemp);
                        taskOwner = propTeamTemp.TeamMember__c;
                    } else if(roleTeamMemberMap.get(templateRecord.AssignTo__c) instanceof OpportunityTeamMember){
                        oppTeamMemberTemp = (OpportunityTeamMember) roleTeamMemberMap.get(templateRecord.AssignTo__c);
                        system.debug('oppTeamMemberTemp : ' + oppTeamMemberTemp);
                        taskOwner = oppTeamMemberTemp.UserId;
                    }
                }
            }
        } else {
            taskOwner = ownerOriginId;
        }
        
        
        /*   //RPP-10737 changes start
if (isCreatedFromGroupRenew == true && templateRecord.TaskName__c == 'Generate Owner’s Pack and Submit for JV Approval'){
roleTeamMemberMap = taskOwnerWrap.propertyTeamMemberMap.get(oppProperty.Id);
if(roleTeamMemberMap != null && roleTeamMemberMap.containsKey(Constants.TEAM_ROLE_LEAS_EXEC)){
propTeamTemp = (PropertyTeam__c) roleTeamMemberMap.get(Constants.TEAM_ROLE_LEAS_EXEC);
taskOwner = propTeamTemp.TeamMember__c;
}
}
//RPP=10737 changes end
if (isCreatedFromGroupRenew == true) {
roleTeamMemberMap = taskOwnerWrap.propertyTeamMemberMap.get(oppProperty.Id);
if(roleTeamMemberMap != null && roleTeamMemberMap.containsKey(templateRecord.GroupRenewalRole__c)){
propTeamTemp = (PropertyTeam__c) roleTeamMemberMap.get(templateRecord.GroupRenewalRole__c);
taskOwner = propTeamTemp.TeamMember__c;
}
} */ // this is merged below
        
        
        //Above 2 merged for RPP-10737
        if (isCreatedFromGroupRenew == true) {
            roleTeamMemberMap = taskOwnerWrap.propertyTeamMemberMap.get(oppProperty.Id);
            if(templateRecord.TaskName__c == 'Generate Owner’s Pack and Submit for JV Approval' && roleTeamMemberMap != null && roleTeamMemberMap.containsKey(Constants.TEAM_ROLE_LEAS_EXEC)){
                propTeamTemp = (PropertyTeam__c) roleTeamMemberMap.get(Constants.TEAM_ROLE_LEAS_EXEC);
                taskOwner = propTeamTemp.TeamMember__c;
            }else{
                if(roleTeamMemberMap != null && roleTeamMemberMap.containsKey(templateRecord.GroupRenewalRole__c)){
                    propTeamTemp = (PropertyTeam__c) roleTeamMemberMap.get(templateRecord.GroupRenewalRole__c);
                    if(oppGroupRenewalAdminId != NULL)
                        taskOwner = oppGroupRenewalAdminId;
                    else
                        taskOwner = propTeamTemp.TeamMember__c;
                }
            }
        } 
        //end RPP-10737
        
        
        system.debug('taskOwner: ' + taskOwner);
        newTaskRecord.OwnerId = taskOwner;
        
        if(templateRecord.DueDate__c != 0 && templateRecord.DueDate__c != null && templateRecord.SkipWeekends__c == true){
            System.debug('Chen debug ' + templateRecord.TaskType__c);
            //dueDate = Date.today().addDays(Integer.valueOf(templateRecord.DueDate__c));
            dueDate = getDueDate(Date.today(), Integer.valueOf(templateRecord.DueDate__c));
            System.debug('Chen debug 2 ' + dueDate);
            //System.debug('Skip Weeknds' + templateRecord.Skip_Weekends__c);
        } else if (templateRecord.DueDate__c != 0 && templateRecord.DueDate__c != null) {
            dueDate = Date.today().addDays(Integer.valueOf(templateRecord.DueDate__c));
        }
        
        newTaskRecord.ActivityDate = dueDate;
        System.debug('Chen newTaskRecord ' + newTaskRecord);
        return newTaskRecord;
    }
    
    public static Date getDueDate (Date startDate, Integer workingDays){
        
        if (startDate == null || workingDays == null) {
            throw new MethodParameterValueException('Invalid parameter values. Start date and Working Days should not be NULL');
        }        
        
        Date monday   = Date.newInstance(1900, 1, 1);
        Date thisDate   = startDate;
        
        Integer wholeWorkWeeks   = Math.floor(workingDays/5).intValue();
        Integer remainder     = Math.mod(workingDays, 5);
        
        thisDate = thisDate.addDays(7*wholeWorkWeeks);
        
        while(remainder > 0){
            
            thisDate = thisDate.addDays(1);
            Integer dayOfWeek = Math.mod(monday.daysBetween(thisDate), 7); 
            
            if(dayOfWeek < 5){
                remainder--;
            }
            
        }
        return thisDate;
    }
    
    public static Boolean checkForCovidCases(SObject parentObject, TaskTemplateAndCondition__c taskTemplate){
        Case cas = (Case) parentObject;
        
        if(cas.SubType__c != Constants.CASE_SUBTYPE_COVID_RENT_REQUEST)
            return TRUE;
        
        
        if(taskTemplate.TaskType__c != Constants.TASKTEMPLATE_RETAIL_ADMINISTRATOR_REVIEW && taskTemplate.TaskType__c != Constants.TASKTEMPLATE_ACCEPT_OFFER_LETTER)
            return TRUE;
        
        Boolean isLeasevariationRequired = (cas.Is_Lease_Variation_Required__c == 'No' || String.isEmpty(cas.Is_Lease_Variation_Required__c)) ? FALSE : TRUE;
        
        System.debug('isLeasevariationRequired: '+isLeasevariationRequired);
        System.debug('taskTemplate.TaskType__c: '+taskTemplate.TaskType__c);
        System.debug('cas.TECH_RetailAdministratorReviewCompleted__c: '+cas.TECH_RetailAdministratorReviewCompleted__c);
        
        if(taskTemplate.TaskType__c == Constants.TASKTEMPLATE_RETAIL_ADMINISTRATOR_REVIEW){
            if(!isLeasevariationRequired){
                return FALSE;
            }else{
                return TRUE;
            }
        }else if(taskTemplate.TaskType__c == Constants.TASKTEMPLATE_ACCEPT_OFFER_LETTER && !isLeasevariationRequired){
            return TRUE;
        }else if(taskTemplate.TaskType__c == Constants.TASKTEMPLATE_ACCEPT_OFFER_LETTER && isLeasevariationRequired && taskTemplate.DependentTask__r.TaskType__c == Constants.TASKTEMPLATE_RETAIL_ADMINISTRATOR_REVIEW){
            return TRUE;
        }
        
        return FALSE;
    }
    
    public class MethodParameterValueException extends Exception {}
}