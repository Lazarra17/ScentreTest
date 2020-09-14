/**
* Class ContentVersionTriggerHandler
*
* Trigger Handler for the content version SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public class ContentVersionTriggerHandler extends TriggerHandler implements ITrigger{
	List<id> cvs = new list<id>();
    List<ContentDocumentLink> newlinks = new List<ContentDocumentLink>(); 
    // Constructor
    public ContentVersionTriggerHandler(){
        
    }
    /**
* This method is called prior to execution of a AFTER trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ContentVersionTriggerHandler.class.getName());
    public void bulkBefore(){
        
    }
    /**
* This method is called prior to execution of a BEFORE trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    public void bulkAfter(){
        for(SObject cvo : Trigger.new) {
            ContentVersion cv = (ContentVersion) cvo;
            cvs.add(cv.id);
        }
        
        Id groupId = Label.SketchLeasePlanUserGroup; 
        
        Set<Id> cdUniqueIds = new Set<Id>();
        
        
        for (ContentVersion cv : (List<ContentVersion>) Trigger.new) {
            if(Constants.SKETCH_PLAN_DOC.equals(cv.DocumentType__c) || Constants.LEASE_PLAN_DOC.equals(cv.DocumentType__c)) {
                cdUniqueIds.add(cv.ContentDocumentid);
            }
        }
        
        Set<Id> unlinkedCds = new Set<Id>(cdUniqueIds);
        
        // Get Documents already linked to GroupId
        List<ContentDocumentLink> linkedCds = DatabaseSOQLBank.getContentDocumentLink(cdUniqueIds, new Set<Id>{groupId});
        
        // Remove already linked documents to list of new Documents to link
        for(ContentDocumentLink docLink : linkedCds) {
            unlinkedCds.remove(docLink.ContentDocumentId);
        }
        
        system.debug('Is Insert -- ' + Trigger.isInsert);
        system.debug('Is Update -- ' + Trigger.isUpdate);
        system.debug('Unlinked CD --' + unlinkedCds);
        if(Trigger.isInsert || Trigger.isUpdate){
            if (unlinkedCds.size() > 0) {
            	for (Id cd : unlinkedCds) {
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentid = cd;
                    link.LinkedEntityId = groupId;
                    link.ShareType = 'C';
                    link.Visibility = 'AllUsers';
                    newlinks.add(link);
                }   
            }
        }        
        
    }
    /**
* This method is called iteratively for each record to be inserted during a BEFORE
* trigger.
* This or other This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeInsert(SObject so){
		
    }
    /**
* This method is called iteratively for each record to be updated during a BEFORE
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeUpdate(SObject oldSo, SObject so){
        
    }
    /**
* This method is called iteratively for each record to be deleted during a BEFORE
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeDelete(SObject so){
        
    }
    /**
* This method is called iteratively for each record to be inserted during a AFTER
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void afterInsert(SObject so){
        //ContentVersion cv = (ContentVersion) so;
        //cv.TechMetaDataKey__c ='';
    }
    /**
* This method is called iteratively for each record to be updated during a AFTER
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void afterUpdate(SObject oldSo, SObject so){
        
    }
    public void afterDelete(SObject so){
    }
    public void andFinally(){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ContentVersionTriggerHandler.class.getName());        
        list<ContentVersion> convs = [select id, TechMetaDataKey__c, origin from ContentVersion where id in: cvs and origin != 'C'];
        for (ContentVersion cv : convs) {
            cv.TechMetaDataKey__c = '';
        }
        try{
            database.update(convs);
        } catch(Exception e){
            errorHandler.createError(e);
        }
        
        errorHandler = new ErrorHandlerUtil(ContentVersionTriggerHandler.class.getName());
        system.debug('New Links --' + newlinks);
        if(newlinks.size() > 0){
            try{
                Database.insert(newlinks);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        errorHandler.save();        
    }
}