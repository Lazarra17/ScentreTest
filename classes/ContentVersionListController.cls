public without sharing  class ContentVersionListController {
    public class ContentVersionDetailWrapper{
        public Date lastModifiedDate;
        public ContentVersion contentVersion;
        public List<String> docTypePicklistValue = new List<String>();
    }
    
    public class ContentVersionWrapper{
        @AuraEnabled public List<String> documentCategoryList = new List<String>();
        @AuraEnabled public List<ContentVersionDetailWrapper> contentVersionList = new List<ContentVersionDetailWrapper>();
        @AuraEnabled public Map<String, List<String>> documentTypeListMap = new Map<String, List<String>>();
    }
    
    @AuraEnabled
    public static LightningResponse getallfiles(String recordId){
        ContentVersionDetailWrapper cVersionDetailWrapTemp;
        LightningResponse responseObject = new LightningResponse();
        ContentVersionWrapper conVerWrapper = new ContentVersionWrapper();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ContentVersionListController.class.getName());
        Set<Id> documentIdSet = new Set<Id>();
        Set<Id> linkedEntityIdSet = new Set<Id>{
        	recordId
        };
        List<ContentDocumentLink> contentDocumentList;
        List<ContentVersionDependentPicklist__mdt> docTypePicklist;
        List<ContentVersion> cVersionList = new List<ContentVersion>();
        
        Schema.DescribeFieldResult fieldResult = ContentVersion.DocumentCategory__c.getDescribe();
        for(Schema.PicklistEntry f : fieldResult.getPicklistValues()){
            conVerWrapper.documentCategoryList.add(f.getValue());
        }
        
        for(ContentVersionDependentPicklist__mdt cVersionDepPicklist : [SELECT Id, MasterLabel, DependentValues__c 
                                                                        FROM ContentVersionDependentPicklist__mdt]){
            conVerWrapper.documentTypeListMap.put(cVersionDepPicklist.MasterLabel, cVersionDepPicklist.DependentValues__c.split(';'));
        }
        
        if(String.isNotBlank(recordId)){
            try{
                contentDocumentList = DatabaseSOQLBank.getContentDocumentLink(linkedEntityIdSet);
            } catch(Exception e){
                responseObject.status = Constants.FAILED;
                responseObject.message = Constants.NO_PRODUCTS_AVAILABLE;
                errorHandler.createError(e);
            }
            
            if(contentDocumentList != null && contentDocumentList.size() > 0){
                for(ContentDocumentLink contentDocumentLinkRecord: contentDocumentList){
                    documentIdSet.add(contentDocumentLinkRecord.ContentDocumentId);
                }
                
                system.debug('documentIdSet ' + documentIdSet);
                
                try{
                    cVersionList = DatabaseSOQLBank.getContentVersion(documentIdSet);
                } catch(Exception e){
                    responseObject.status = Constants.FAILED;
                    responseObject.message = Constants.NO_PRODUCTS_AVAILABLE;
                    errorHandler.createError(e);
                }
                
                for(ContentVersion cVersion : cVersionList){
                    cVersionDetailWrapTemp = new ContentVersionDetailWrapper();
                    
                    cVersionDetailWrapTemp.contentVersion = cVersion;
                    cVersionDetailWrapTemp.lastModifiedDate = cVersion.LastModifiedDate.date();
                    
                    if(String.isNotBlank(cVersion.DocumentCategory__c) && conVerWrapper.documentTypeListMap.containsKey(cVersion.DocumentCategory__c)){
                        cVersionDetailWrapTemp.docTypePicklistValue = conVerWrapper.documentTypeListMap.get(cVersion.DocumentCategory__c);
                    }
                    
                    conVerWrapper.contentVersionList.add(cVersionDetailWrapTemp);
                }
                
                system.debug('conVerWrapper.contentVersionList : ' + conVerWrapper.contentVersionList);
            }
            
            system.debug('conVerWrapper : ' + conVerWrapper);
            
            if(conVerWrapper != null && conVerWrapper.contentVersionList.size() > 0){
                responseObject.returnValue = JSON.serialize(conVerWrapper);
            } else{
                responseObject.status = Constants.FAILED;
                responseObject.message = Constants.NO_PRODUCTS_AVAILABLE;
            }
        }
        
        system.debug('&&responseObject* ' + responseObject);
        
        errorHandler.save();
        
        return responseObject;
    }
    
    @AuraEnabled
    public static LightningResponse updateContentVersion(String recordId, String contentVersionJSON){
        LightningResponse res = new LightningResponse();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ContentVersionListController.class.getName());
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<ContentVersion> contentVersionList = (List<ContentVersion>) JSON.deserialize(contentVersionJSON, List<ContentVersion>.class);
        
        system.debug('contentVersionList : ' + contentVersionList);
        
        if(contentVersionList != null && contentVersionList.size() > 0){
            try{
                Database.update(contentVersionList);
                List<Id> contentVersionIds = new List<Id>();
                List<Id> docIds = new List<Id>();
                List<Id> oppoIds = new List<Id>();
                for (ContentVersion contentVersionRecord : contentVersionList) {
                    contentVersionIds.add(contentVersionRecord.Id);
                }
                List<ContentVersion> getAllDocIds = [select id, contentdocumentid from contentversion where id in :contentVersionIds];
                for (ContentVersion docId : getAllDocIds) {
                    docIds.add(docId.contentdocumentid);
                }
                System.debug('contentVersionIds ' + contentVersionIds);
                if (contentVersionIds.size() > 0) {
                	List<ContentDocumentLink> contentDocumentLinks = [Select LinkedEntityId from ContentDocumentLink where ContentDocumentId IN :docIds];   
                	System.debug('contentDocumentLinks ' + contentDocumentLinks);
                    // Check id type
                    for (ContentDocumentLink link : contentDocumentLinks) {
                        String sobjectType = link.LinkedEntityId.getSObjectType().getDescribe().getName();
                        if (sobjectType == Constants.OPPORTUNITY) {
                     		// Get all the to oppportunity from content version
                     		oppoIds.add(link.LinkedEntityId);       
                        }
                    }
                	// Update opportunity checkbox
                	List<Opportunity> updateOppos = new List<Opportunity>();
                	List<Opportunity> oppoToBeUpdate = [Select Id, TechRecordsManaged__c From Opportunity Where Id in :oppoIds];
                    for (Opportunity oppo : oppoToBeUpdate) {
                        oppo.TechRecordsManaged__c = TRUE;
                        updateOppos.add(oppo);
                    }
                    if (updateOppos.size() > 0) {
                        List<Opportunity> lockedOppos = new List<Opportunity>();
                        List<Opportunity> unlockedOppos = new List<Opportunity>();
                        Map<Id, boolean> recordList = Approval.isLocked(updateOppos);
                        System.debug('recordList ' + recordList);
                        for (Opportunity oppo : updateOppos) {
                            if (recordList.get(oppo.Id) != null && recordList.get(oppo.Id)) {
                                lockedOppos.add(oppo);
                            } else {
                                unlockedOppos.add(oppo);
                            }
                        } 
                        if (lockedOppos.size() > 0){
                        	Approval.unlock(lockedOppos);
                            Database.update(lockedOppos);
                            Approval.lock(lockedOppos);      
                        }
                        if (unlockedOppos.size() > 0) {
                            Database.update(unlockedOppos);
                        } 
                    }
                }
            } catch(Exception e){
                res.status = Constants.FAILED;
                res.message = e.getMessage();
                System.debug('e.getMessage() ' + e.getMessage());
                errorHandler.createError(e);
            }
        }
        
        if(!Constants.FAILED.equalsIgnoreCase(res.status)){
        	res = getallfiles(recordId);
        }
        
        errorHandler.save();
        
        return res;
    }
}