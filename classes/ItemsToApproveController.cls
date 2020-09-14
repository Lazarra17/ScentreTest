/* 
 * This class is a controller for two lightning components i.e. 1.ItemsToApproveList and 2.CustomApproveReject
 * Author: Shrikant Hase (Sauce Consulting)
*/

public class ItemsToApproveController {
        
    //wrapper class to collect data in a single object
    public class ItemToApproveWrapper{
        @auraEnabled public String objectName;
        @auraEnabled public String recordId;
        @auraEnabled public String retailer;
        @auraEnabled public String shopNumber;
        @auraEnabled public String property;
        @auraEnabled public String name;
        @auraEnabled public String caseType;
        @auraEnabled public String caseSubtype;
        @auraEnabled public String submittedBy;
        @auraEnabled public String workItemId;
        
        //wrapper constructor
        public ItemToApproveWrapper(String objectName, String recordId, String retailer, String shopNumber, String property, String name, String caseType, 
                                    String caseSubtype, String submittedBy, String workItemId){
                                        this.objectName = objectName;
                                        this.recordId = recordId;
                                        this.retailer = retailer;
                                        this.shopNumber = shopNumber;
                                        this.property = property;
                                        this.name = name;
                                        this.casetype = caseType;
                                        this.caseSubtype = caseSubtype;
                                        this.submittedBy = submittedBy;
                                        this.workItemId = workItemId;
                                    }
    }
    
    //This method is responsible to collect all the approval request and its releted record`s necessary data
    @auraEnabled
    public static List<ItemToApproveWrapper> getItemsToApprove(){
        List<ItemToApproveWrapper> itemsToApproveWrapperList = new List<ItemToApproveWrapper>();
        String relatedRecordId = null;
        set<Id> caseIds = new set<Id>();
        set<Id> oppIds = new set<Id>();
        Map<Id, Case> idVsCaseMap;
        Map<Id, Opportunity> idVsOppMap;
        String loggedInUserId = UserInfo.getUserId();
        
        List<ProcessInstanceWorkitem> itemsToApproveList = new List<ProcessInstanceWorkitem>();
        
        //Search for all approval requests assigned to the logged in user
        itemsToApproveList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.SubmittedBy.Name
                              FROM ProcessInstanceWorkitem
                              WHERE ActorId =: loggedInUserId 
                              OR OriginalActorId =: loggedInUserId];
        System.debug('itemsToApproveList === '+itemsToApproveList);
        
        //collect the related record ids
        for(ProcessInstanceWorkitem itemToApprove : itemsToApproveList){
            
            relatedRecordId = (String)itemToApprove.ProcessInstance.TargetObjectId;
            if(relatedRecordId.startsWith('500')){
                caseIds.add(relatedRecordId);
            }else if(relatedRecordId.startsWith('006')){
                oppIds.add(relatedRecordId);
            }
        }
        
        //Query the related records with required information and store it in a map
        if(!caseIds.isEmpty()){
            idVsCaseMap = new Map<Id, Case>([SELECT Id, Subject, Type, SubType__c, Space__r.Name, Property__c,
                                             Space__r.CurrentRetailer__r.Name 
                                             FROM Case 
                                             WHERE Id IN: caseIds]);
        }
        System.debug('idVsCaseMap === '+idVsCaseMap);
        if(!oppIds.isEmpty()){
            idVsOppMap = new Map<Id, Opportunity>([SELECT Id, Name, Type, Space__r.Name, Property__r.Name, Space__r.CurrentRetailer__r.Name 
                                                   FROM Opportunity 
                                                   WHERE Id IN: oppIds]);
        }
        System.debug('idVsOppMap === '+idVsOppMap);
        
        //construct a wrapper for each approval request to display the details on page
        for(ProcessInstanceWorkitem itemToApprove : itemsToApproveList){
            relatedRecordId = (String)itemToApprove.ProcessInstance.TargetObjectId;
            
            Case cs;
            if(idVsCaseMap != NULL && idVsCaseMap.containsKey(relatedRecordId)){
                cs = idVsCaseMap.get(relatedRecordId);
                itemsToApproveWrapperList.add(
                    new ItemToApproveWrapper(Constants.OBJECT_CASE, cs.Id, cs.Space__r.CurrentRetailer__r.Name, cs.Space__r.Name, cs.Property__c, cs.Subject,
                                             cs.Type, cs.SubType__c, itemToApprove.ProcessInstance.SubmittedBy.Name, itemToApprove.Id)
                );
            }
            System.debug('itemsToApproveWrapperList cases === '+itemsToApproveWrapperList);
            
            Opportunity opp;
            if(idVsOppMap != NULL && idVsOppMap.containsKey(relatedRecordId)){
                opp = idVsOppMap.get(relatedRecordId);
                itemsToApproveWrapperList.add(
                    new ItemToApproveWrapper(Constants.OPPORTUNITY, opp.Id, opp.Space__r.CurrentRetailer__r.Name, opp.Space__r.Name, opp.Property__r.Name, opp.Name,
                                             opp.Type, null, itemToApprove.ProcessInstance.SubmittedBy.Name, itemToApprove.Id)
                );
            }
            System.debug('itemsToApproveWrapperList opps === '+itemsToApproveWrapperList);
        }
        system.debug('itemsToApproveWrapperList === '+itemsToApproveWrapperList);
        return itemsToApproveWrapperList;
    }
    
    //This method is responsible for changing the status of request to approve/reject or reassign the request
    //This method is called from CustomApproveReject lightning component
    @AuraEnabled
    public static void saveItemToApprove(String workItemId, String updatedStatus, String comments, String newAssignedUser){
        //if action type is Reassign then change the actor of approval request
        if(updatedStatus == 'Reassign'){
            if(!String.isBlank(workItemId) && !String.isBlank(newAssignedUser)){
                ProcessInstanceWorkitem workItem = [SELECT Id, OriginalActorId, ActorId 
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE Id =: workItemId];
                workItem.ActorId = newAssignedUser;
                update workItem;
            }
            
        //approve or reject the request
        }else{
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItemId);
            req.setAction(updatedStatus);
            req.setComments(comments);
            requests.add(req);
            Approval.ProcessResult[] processResults = Approval.process(requests);
        }
        
    }
}