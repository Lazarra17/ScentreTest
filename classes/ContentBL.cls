public class ContentBL {
    
    public Static List<ContentDocumentLink> createContentDocumentLink(List<Sobject> sobjectRecordList, String ObjectType){
        List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink>();
        if(sobjectRecordList.size() > 0 && !sobjectRecordList.isEmpty()){
            if(ObjectType.equalsIgnoreCase('Opportunity')){
                Set<Id> spaceIdSet = new Set<Id>();
                Map<Id,List<Opportunity>> spaceIdOpportunityMap = new Map<Id,List<Opportunity>>();
                                
                for(Sobject sobjectRecord: sobjectRecordList){
                    Opportunity opptyRecrod = (Opportunity)sobjectRecord;
                    
                    //RPP-11003 - Stop auto-adding Space's Lease Plan to New Lease Opportunities on creation
                    if(opptyRecrod.Type == Constants.OPP_TYPE_NEW_LEASE){
                        continue;
                    }
                    
                    if(String.isNotBlank(opptyRecrod.Space__c)){
                        
                        spaceIdSet.add(opptyRecrod.Space__c);
                        if(spaceIdOpportunityMap.containskey(opptyRecrod.Space__c)){
                            spaceIdOpportunityMap.get(opptyRecrod.Space__c).add(opptyRecrod);
                        }else{
                            spaceIdOpportunityMap.put(opptyRecrod.Space__c,new List<Opportunity>{opptyRecrod});
                        }
                        
                    }
                }
                if(spaceIdSet.size()>0&&!spaceIdSet.isEmpty()){
                    Set<Id> contentDocumentIdSet=new Set<Id>();
                    Map<Id,ContentDocumentLink> spaceIdDocumentLinkMap=new Map<Id,ContentDocumentLink>();
                    for(ContentDocumentLink contentDocumentLinkRecord: [Select id,ContentDocumentId,LinkedEntityId,Visibility,ShareType from ContentDocumentLink where LinkedEntityId IN: spaceIdSet]){
                        contentDocumentIdSet.add(contentDocumentLinkRecord.ContentDocumentId);
                        spaceIdDocumentLinkMap.put(contentDocumentLinkRecord.ContentDocumentId,contentDocumentLinkRecord);
                    }
                    for(ContentVersion contentVersionRecord: [select id, ContentDocumentId from ContentVersion where DocumentType__c=:Constants.LEASE_PLAN AND ContentDocumentId IN: contentDocumentIdSet]){
                        ContentDocumentLink linkrecord=new ContentDocumentLink();
                        ContentDocumentLink linkfromspace=spaceIdDocumentLinkMap.get(contentVersionRecord.ContentDocumentId);
                        linkrecord.ContentDocumentId=contentVersionRecord.ContentDocumentId;
                        linkrecord.Visibility=linkfromspace.Visibility;
                        linkrecord.ShareType=linkfromspace.ShareType;
                        for(Opportunity opptyRecord: spaceIdOpportunityMap.get(linkfromspace.LinkedEntityId)){
                            linkrecord.LinkedEntityId=opptyRecord.Id;
                        }
                        ContentDocumentLinkList.add(linkrecord);
                    }
                }
            }
        }
        system.debug('** FINAL '+ ContentDocumentLinkList);
        return ContentDocumentLinkList;
    }
}