/**
* Description: Utility class for chatter post notification.
*/
public with sharing class ChatterPostUtil {
    
    public class chatterNotificationWrapper{
        public Id subjectId {get;set;}
        public Set<Id> mentionedUsers {get;set;} 
        public String body {get;set;}
        public String linkedEntityId {get;set;}
    }
    //mdc start 6.25.18 Start
    public static chatterNotificationWrapper ChatterPostToApprovedOpp(Opportunity opp){
        chatterNotificationWrapper chatterItem = new chatterNotificationWrapper();
        List<chatterNotificationWrapper> chatterLst = new List<chatterNotificationWrapper>();
        Set<Id> mentionUsers = new Set<Id>();
        //List<Opportunity> oppLst = [select id,GMLARS__c,RMLARS__c,GMRetailAdmin__c,DirectorLARSNZDevelopment__c,CorporateLegal__c,COO__c from Opportunity where id =: opp.id];
        chatterItem.subjectId = opp.id;
        if(opp.GMLARS__c != null){
            mentionUsers.add(opp.GMLARS__c);
        }
        if(opp.RMLARS__c != null){
            mentionUsers.add(opp.RMLARS__c);
        }
        if(opp.GMRetailAdmin__c != null){
            mentionUsers.add(opp.GMRetailAdmin__c);
        }
        if(opp.DirectorLARSNZDevelopment__c != null){
            mentionUsers.add(opp.DirectorLARSNZDevelopment__c);
        }
        if(opp.CorporateLegal__c != null){
            mentionUsers.add(opp.CorporateLegal__c);
        }
        if(opp.Development_Executive__c != null){
            mentionUsers.add(opp.Development_Executive__c);
        }
        if(opp.COO__c != null){
            mentionUsers.add(opp.COO__c);
        }
        
        List<String> parameters = new List<String>();
        
        if(String.isNotBlank(opp.name)){
            parameters.add(opp.name);
        }
        
        String chatterBody = Label.RMRiskApprovalChatterMsg;
        String paramChatterBody = String.format(chatterBody, parameters);
        chatterItem.mentionedUsers = mentionUsers;      
        chatterItem.body = paramChatterBody;
        return chatterItem;
    }
    //mdc start 6.25.18 End 
    
    //mdc start 6.25.18 Start
    public static chatterNotificationWrapper ChatterPostToOppRisk(List<Id> userLstToChatter,Opportunity opp){
        chatterNotificationWrapper chatterItem = new chatterNotificationWrapper();
        List<chatterNotificationWrapper> chatterLst = new List<chatterNotificationWrapper>();
        Set<Id> mentionUsers = new Set<Id>(userLstToChatter);
        chatterItem.subjectId = opp.id;
        
        List<String> parameters = new List<String>();
        
        if(String.isNotBlank(opp.name)){
            parameters.add(opp.name);
        }
        
        String chatterBody = Label.RiskApprovalChatterMsg;
        String paramChatterBody = String.format(chatterBody, parameters);
        chatterItem.mentionedUsers = mentionUsers;      
        chatterItem.body = paramChatterBody;
        return chatterItem;
    }
    //mdc start 6.25.18 End 
    
    //SG 6.26.18
    public static chatterNotificationWrapper ChatterPostToCaseRecord(Case caseRec, Map<Id,List<Id>> caseIDUsersToNotifLstMap){
        chatterNotificationWrapper chatterItem = new chatterNotificationWrapper();
        List<chatterNotificationWrapper> chatterLst = new List<chatterNotificationWrapper>();
        List<String> parameters = new List<String>();
        Set<Id> mentionUsers = new Set<Id>();
        String paramChatterBody;
        chatterItem.subjectId = caseRec.id;
        String chatterBody;
        
        //Update SG 10-5-2018
        //all case record types will have a uniform chatter body for chatter notification
        parameters.add(caseRec.Type != null ? caseRec.Type : '');
        parameters.add(caseRec.SubType__c != null ? caseRec.SubType__c : '');
        parameters.add(caseRec.Contract__c != null ? caseRec.Contract__r.Name : '');
        parameters.add((caseRec.Accountid != null && caseRec.Account.TradingName__c != null) ? caseRec.Account.TradingName__c : '');
        parameters.add((caseRec.Accountid != null && caseRec.Account.LesseeName__c != null) ? caseRec.Account.LesseeName__c : '');
        parameters.add(caseRec.space__c != null ? caseRec.space__r.Name : '');
        parameters.add(caseRec.space__c != null ? caseRec.Space__r.property__r.Name : '');
        parameters.add(caseRec.createdBy.Name != null ? caseRec.createdBy.Name : '');
        
        chatterBody = Label.PostChatterToAllCaseRecordType;
            
        
        System.debug('chatterBody ' + chatterBody);
        System.debug('parameters' + parameters);
        paramChatterBody = String.format(chatterBody, parameters);
        
        if(caseIDUsersToNotifLstMap.containskey(caseRec.id)){
            mentionUsers.addall(caseIDUsersToNotifLstMap.get(caseRec.id));
            System.debug('mentioned Users' + mentionUsers);
        }
        
        chatterItem.mentionedUsers = mentionUsers;      
        chatterItem.body = paramChatterBody;
        //system.assertnotequals(chatterItem,chatterItem);
        return chatterItem;
    }
    
    public static List<chatterNotificationWrapper> ChatterPostRiskApprovedOpp(List<Id> oppIds) {
        
        List<chatterNotificationWrapper> chatterLst = new List<chatterNotificationWrapper>();
        List<Opportunity> oppList = DatabaseSOQLBank.getOpportunityList(new Set<Id>(oppIds));
        
        for (Opportunity opp : oppList) {
            
            // Post to Record
            chatterNotificationWrapper chatterItem = new chatterNotificationWrapper();
            chatterItem.subjectId = opp.Id;
            chatterItem.mentionedUsers = new Set<Id>();
            chatterItem.body = String.format(Label.ChatterPostRiskApprovedOpp, new List<String>{opp.Name});
            
            chatterLst.add(chatterItem);
            
            // Post to Chatter group
            chatterItem = new chatterNotificationWrapper();
            chatterItem.subjectId = Label.RiskApprovedOppChatterGroup;
            chatterItem.mentionedUsers = new Set<Id>();
            chatterItem.body = String.format(Label.ChatterPostRiskApprovedOpp, new List<String>{''});
            chatterItem.linkedEntityId = opp.Id;
            
            chatterLst.add(chatterItem);
            
        }
		
        return chatterLst;
    }
    
    
    // Prince RPP-10222 4/17/19
    public static chatterNotificationWrapper ChatterPostToRevenueAssurance(Opportunity opp, Set<Id> revAdmins) {
 
        List<String> parameters = new List<String>();
        chatterNotificationWrapper chatterItem = new chatterNotificationWrapper();
        
        parameters.add(opp.Contracts__r != null && opp.Contracts__r.size() > 0 ? opp.Contracts__r[0].Name : '');
        parameters.add((opp.AccountId != null && opp.Account.TradingName__c != null) ? opp.Account.TradingName__c : '');
        parameters.add(opp.Property__r.Name != null ? opp.Property__r.Name : '');
        parameters.add(opp.Space__r.Name != null ? opp.Space__r.Name : '');
        
        chatterItem.subjectId = opp.Id;
        chatterItem.mentionedUsers = revAdmins;
        chatterItem.body = String.format(Label.ChatterCancelledOppRevAssurance + ' ', parameters);
        chatterItem.linkedEntityId = opp.Id;
        
        return chatterItem;
    }
    // ---

    // RPP-9340 START LF
    public static chatterNotificationWrapper ChatterPostGeneric(String bodyTemplate, Id subjectId, List<String> bodyParamsList, Set<Id> mentionedUsers, Id linkedEntityId) {
        chatterNotificationWrapper chatterItem = new chatterNotificationWrapper();
        
        chatterItem.body = bodyParamsList != null ? String.format(CONSTANTS.ENDLINE + bodyTemplate + CONSTANTS.ENDLINE, bodyParamsList) : bodyTemplate;
        chatterItem.subjectId = subjectId;
		chatterItem.mentionedUsers = mentionedUsers != null ? mentionedUsers : new Set<Id>();
        chatterItem.linkedEntityId = linkedEntityId != null ? linkedEntityId : null;
        return chatterItem;        
    }
    // RPP-9340 END LF
    
    
    /*
* Parameter accepts list of chatterNotificationWrapper consist of subjectId (recordId), mentionedUsers (users mentioned in the chatter post), body (text in the body)
* Return type is list of ConnectApi.BatchInput, needs to post batch feeds. To bulk post feeds, use below:
* ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
*/
    public static List<ConnectApi.BatchInput> chatterPostNotificationHelper(List<chatterNotificationWrapper> chatterNotificationWrapperList){
        List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();
        for(chatterNotificationWrapper cnWrapper: chatterNotificationWrapperList){
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            for(Id userId: cnWrapper.mentionedUsers){
                ConnectApi.MentionSegmentInput inputMention = new ConnectApi.MentionSegmentInput();
                
                inputMention.id = userId;
                messageBodyInput.messageSegments.add(inputMention);
                
                ConnectApi.TextSegmentInput inputSpace = new ConnectApi.TextSegmentInput();
                inputSpace.text =  CONSTANTS.EMPTY;
                messageBodyInput.messageSegments.add(inputSpace);
            }
            
            ConnectApi.TextSegmentInput inputText = new ConnectApi.TextSegmentInput();
            inputText.text =  CONSTANTS.ENDLINE + cnWrapper.body;
            messageBodyInput.messageSegments.add(inputText);
            
            // START LF RPP-9959
            if (cnWrapper.linkedEntityId != null) {
                ConnectApi.EntityLinkSegmentInput inputLink = new ConnectApi.EntityLinkSegmentInput();
                inputLink.entityId = cnWrapper.linkedEntityId;
                messageBodyInput.messageSegments.add(inputLink);
            }
            // END LF RPP-9959
            
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = cnWrapper.subjectId;
            
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
            batchInputList.add(batchInput);
        }
        return batchInputList;
    }
    /******************************************************************************************
* This method can be used to make chatter post for any sobject record in the org.
* parameter: List<ChatterPostUtil.chatterNotifWrapperList>
******************************************************************************************/
    public static void chatterpostBulk(List<ChatterPostUtil.chatterNotificationWrapper> chatterNotificationWrapperList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ChatterPostUtil.class.getName());
        
        if(chatterNotificationWrapperList.size()>0 &&!chatterNotificationWrapperList.isEmpty()){
            List<ConnectApi.BatchInput> batchInputs = ChatterPostUtil.chatterPostNotificationHelper(chatterNotificationWrapperList);
            // Label.DisableChatterNotification controlles org level custom chatter post.
            if(batchInputs.size() > 0 && Constants.BOOLEAN_FALSE.equalsIgnoreCase(Label.DisableChatterNotification)){
                try{
                    System.debug('** FINAL POST** '+batchInputs);
                    ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
                }
                catch(Exception e){
                    errorHandler.createError(e);
                    System.debug('Exception on  ChatterPostUtil.ChatterPostBulkNonFuture '+e.getMessage());
                }
            }
        }
        
        errorHandler.save();
    }
}