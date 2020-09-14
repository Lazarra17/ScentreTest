/**
 ** Comments: Utility for Error logging.
 ** Date Provided: 13-04-2018
 ** Owner: Accenture PLC
 ** Confidential. This document incorporates information that is proprietary to Accenture. 
 ** The Accenture information in this document is supplied in confidence and, except for any purposes agreed by the parties, 
 ** should not be disclosed, duplicated or otherwise revealed in whole or in part without the prior written consent of Accenture
 **/
public class ErrorHandlerUtil {
    
    private List<Error__c> errorList;
    private String className;
    
    public ErrorHandlerUtil(String className) {
        this.className = className;
        this.errorList = new List<Error__c>();
    }
    
    /**
     ** @description Create Error record for caught Exceptions
     ** @param e - Exception caught during failed transaction
     ** @return void
     **/
    public void createError(Exception e) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();        
        error.ErrorType__c = e.getTypeName();
        error.FullMessage__c = e.getMessage();
        error.StackTrace__c = e.getStackTraceString();
        error.ObjectType__c = this.className;
        
        this.errorList.add(error);
    }
    
    /**
     ** @description Create Error record for caught Exceptions
     ** @param e - Exception caught during failed transaction
     ** @param failedRecordId - The id of the record the transaction was performed on.
     ** @return void
     **/
    public void createError(Exception e, Id failedRecordId) {
        String recordURL = getRecordURL(failedRecordId, null);
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.ErrorType__c = e.getTypeName();
        error.FullMessage__c = e.getMessage();
        error.StackTrace__c = e.getStackTraceString();
        error.ObjectType__c = this.className;
        error.RecordURL__c = (recordURL != null)? recordURL : null;
        
        this.errorList.add(error);
    }
    
    /**
     ** @description Create Error record for Database results
     ** @param result - Database result object
     ** @param objId - The id of the record the DML operation was performed on.
     ** @return void
     **/
    public void createError(Object result, Id objId) {
        Error__c error;
        String recordURL = CONSTANTS.EMPTY;
        List<Database.Error> errorList = new List<Database.Error>();
        
        if(result instanceof Database.SaveResult) {
            Database.SaveResult saveResult = (Database.SaveResult) result;
            recordURL = getRecordURL(saveResult.getId(), objId);
            errorList = saveResult.getErrors();
        } else if(result instanceof Database.DeleteResult) {
            Database.DeleteResult deleteResult = (Database.DeleteResult) result;
            recordURL = getRecordURL(deleteResult.getId(), objId);
            errorList = deleteResult.getErrors();
        } else if(result instanceof Database.UndeleteResult) {
            Database.UndeleteResult undeleteResult = (Database.UndeleteResult) result;
            recordURL = getRecordURL(undeleteResult.getId(), objId);
            errorList = undeleteResult.getErrors();
        } else if(result instanceof Database.UpsertResult){
            Database.UpsertResult upsertResult = (Database.UpsertResult) result;
            recordURL = getRecordURL(upsertResult.getId(), objId);
            errorList = upsertResult.getErrors();
        }

        for(Database.Error err : errorList){
            error = new Error__c();
            error.Datetime__c = System.now();
            error.RecordURL__c = (recordURL != null)? recordURL : null;
            error.ObjectType__c = this.className;
            error.ErrorType__c = String.valueOf(err.getStatusCode());
            error.FullMessage__c = err.getMessage();
            
            this.errorList.add(error);
        }
    }
    
    /**
     ** @description Create Error record with dynamic error message 
     ** @param message - Error message
     ** @return void
     **/
    public void createError(String message) {
        Error__c error = new Error__c();
        error.ObjectType__c = this.className;
        error.FullMessage__c = message;
        
        this.errorList.add(error);
    }
    
    /**
     ** @description Create Error record with dynamic error message 
     ** @param message - Error message
     ** @param failedRecordId - The id of the record the transaction was performed on.
     ** @return void
     **/
    public void createError(String message, String failedRecordId) {
        Error__c error = new Error__c();
        error.ObjectType__c = className;
        error.FullMessage__c = message;
        error.RecordURL__c = getRecordURL(failedRecordId, null);
        
        this.errorList.add(error);
    }

    /**
     ** @description Create Error record with dynamic error message and errorType
     ** @param message - Error message
     ** @param failedRecordId - The id of the record the transaction was performed on.
     ** @param errorType - Error type
     ** @return void
     **/
    public void createError(String message, String failedRecordId, String errorType) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.ObjectType__c = className;
        error.ErrorType__c = errorType;
        error.FullMessage__c = message;
        error.RecordURL__c = getRecordURL(failedRecordId, null);
        
        this.errorList.add(error);
    }
    
    /**
     ** @description Save error records
     ** @return void
     **/
    public void save(){
        system.debug('errorList : ' + errorList);

        if(this.errorList.size() > 0){
            insert errorList;
            //Database.insert(errorList, false);
        }
    }
    
    /*******************************************************************************************************
    * @description Returns the URL of a record, if available.
    * @param saveResultId The id result ing from a DML operation of the Database class.
    * @param objId The id of the record the DML operation was performed on.
    * @return The URL of the record. Warning: it may not necessarily be valid.
    */
    private static String getRecordURL(Id saveResultId, Id objId) {
        String recordURL = URL.getSalesforceBaseUrl().toExternalForm() + CONSTANTS.SLASH;
        if (saveResultId != null){
            recordURL += saveResultId;
        } else {
            recordURL += objId;
        }        
        
        return recordURL;
    }
}