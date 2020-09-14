/*------------------------------------------------------------------------------------
Author:      Ashwini Makhija
Company:     Sauce Consulting
Description: This batch class is responsible for updating all the covid cases for which Rental Assistance Period 
             picklist value has been edited from field definition 
Test Class:  
History
Date                  Author             Comments
--------------------------------------------------------------------------------------
11 June 2020      Ashwini Makhija        RPP-11100
--------------------------------------------------------------------------------------*/
global without sharing class RentalAsstDateManagementBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public List<Covid_Case_Rental_Assistan__mdt> covidRentalAsstMetadataList = New List<Covid_Case_Rental_Assistan__mdt>();
    public String caseSubType = Constants.CASE_SUBTYPE_COVID_RENT_REQUEST;
    public integer totalCasesToUpdate=0;
    public Set<Id> passedCaseIds = New Set<Id>();
    public Set<Id> failedCaseIds = New Set<Id>();
    public Map<Id,String> errorMap = New Map<Id,String>();
    public List<String> userEmailIds = New List<String>();
    
    global RentalAsstDateManagementBatch(){
        covidRentalAsstMetadataList = [SELECT MasterLabel, Start_Date__c, End_Date__c, Batch_Update__c 
                                       FROM Covid_Case_Rental_Assistan__mdt
                                       WHERE Batch_Update__c = TRUE];
        
        String Email_Ids = System.Label.Email_Ids_Rental_Asst_Batch;
        userEmailIds = Email_Ids.split(', ');
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Subject, SubType__c, Type , Rental_Assistance_Period__c, Rental_Assistance_Start_Date__c, Rental_Assistance_End_Date__c 
                                         FROM Case
                                         WHERE SubType__c =: caseSubType 
                                         AND Type = 'LV18 - Miscellaneous'
                                         AND Rental_Assistance_Period__c != '']);   
    }
    
    global void execute(Database.BatchableContext BC, List<Case> caseList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RentalAsstDateManagementBatch.class.getName());
        List<Case> casesToUpdate = New List<Case>();
        List<Database.SaveResult> saveResults = New List<Database.SaveResult>();
        
        try{
            
            if(covidRentalAsstMetadataList.size() > 0){
                
                for(Covid_Case_Rental_Assistan__mdt covidRentalAsstMetadata : covidRentalAsstMetadataList){
                    for(Case updateCase : caseList){
                        if(updateCase.Rental_Assistance_Period__c == covidRentalAsstMetadata.MasterLabel){
                            if(updateCase.Rental_Assistance_Start_Date__c != covidRentalAsstMetadata.Start_Date__c){
                                updateCase.Rental_Assistance_Start_Date__c = covidRentalAsstMetadata.Start_Date__c;
                            }
                            if(updateCase.Rental_Assistance_End_Date__c != covidRentalAsstMetadata.End_Date__c){
                                updateCase.Rental_Assistance_End_Date__c = covidRentalAsstMetadata.End_Date__c;
                            }

                            casesToUpdate.add(updateCase);
                        }
                    }
                }
                
                if(casesToUpdate.size() > 0){
                    totalCasesToUpdate = casesToUpdate.size();
                    TriggerHandler.bypass('CaseTriggerHandler');
                    saveResults = Database.update(casesToUpdate,false);
                }
                
                if(saveResults.size() > 0){
                    Integer count = 0;
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()){
                            String errMsg = saveResult.getErrors()[0].getMessage();
                            errorMap.put(casesToUpdate[count].Id, errMsg);
                            failedCaseIds.add(casesToUpdate[count].Id);
                        }
                        else{
                            passedCaseIds.add(casesToUpdate[count].Id);
                        }
                        count++;
                    }
                }
                 
            }
        }catch(Exception e){
            system.debug('Exception------'+e.getLineNumber()+'--------'+e.getStackTraceString());
            errorHandler.createError(e);
        }

        errorHandler.save();
        
    }
    
    global void finish(Database.BatchableContext BC){
        User currentUser = [SELECT Id, FirstName, LastName, UserName FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RentalAsstDateManagementBatch.class.getName());
        AsyncApexJob a = [SELECT id, ApexClassId, JobItemsProcessed, TotalJobItems,NumberOfErrors
                              FROM AsyncApexJob
                              WHERE id = :BC.getJobId()];
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
        String emailBody = 'The batch is executed by ' + currentUser.FirstName + ' ' + currentUser.LastName + '. \n'
                         + 'The batch job '+ 'RentalAsstDateManagementBatch '+ 'has finished. \n\n';
        String emailSubject = 'Job Id : ' + BC.getJobId()  + ' Case - Apex Batch Result';
        
        Messaging.EmailFileAttachment efaSuccess = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment efaError = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment mdtRecords = new Messaging.EmailFileAttachment();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        try{
            if(covidRentalAsstMetadataList.size() > 0){
                //Creating the CSV for Used Metadata Records
                String mdtfinalstr = 'Id, MasterLabel, Batch_Update__c \n';
                String mdtAttName = 'Metadata Records.csv';
                for(Covid_Case_Rental_Assistan__mdt covidRentalAsstMetadata : covidRentalAsstMetadataList){
                    string record = '"'+covidRentalAsstMetadata.Id+'","'+covidRentalAsstMetadata.MasterLabel+'","'+covidRentalAsstMetadata.Batch_Update__c+'"\n';
                    mdtfinalstr = mdtfinalstr + record;
                }
                
                mdtRecords.setFileName(mdtAttName);
                mdtRecords.setBody(Blob.valueOf(mdtfinalstr));
                
                attachments.add(mdtRecords);
                
            }
            
            if(!passedCaseIds.isEmpty() || Test.isRunningTest()){
                emailbody = emailbody + passedCaseIds.size() + ' cases updated successfully. \n';
                
                // Creating the success file
                String successfinalstr = 'Id \n';
                String successAttName = 'Batch Success File.csv';
                for(Id caseId  : passedCaseIds){
                    string recordId = '"'+caseId+'"\n';
                    successfinalstr = successfinalstr + recordId;
                } 
     
                efaSuccess.setFileName(successAttName);
                efaSuccess.setBody(Blob.valueOf(successfinalstr));
                
                attachments.add(efaSuccess);
            }
            
            if(!failedCaseIds.isEmpty() || Test.isRunningTest()){
                emailbody = emailbody + failedCaseIds.size() + ' cases failed to update. \n';
                
                // Creating the error file 
                String errfinalstr = 'Id, Error \n';
                String errorAttName = 'Batch Error File.csv';
                for(Id caseId  : errorMap.keySet()){
                    string err = errorMap.get(caseId);
                    string recordId = '"'+caseId+'","'+err+'"\n';
                    errfinalstr = errfinalstr + recordId;
                } 
     
                efaError.setFileName(errorAttName);
                efaError.setBody(Blob.valueOf(errfinalstr));
                
                attachments.add(efaError);
            }
            
            if(attachments.size() > 0){
                emailbody = emailbody + '\nPlease find attached files - ';
                email.setFileAttachments( attachments );
            }
            // Sets the paramaters of the email
            email.setSubject( emailSubject );
            email.setToAddresses( userEmailIds );
            email.setPlainTextBody( emailBody );
 
            // Sends the email
            Messaging.SendEmailResult[] ser = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
                
        }catch(Exception e){
            system.debug('Exception------'+e.getLineNumber()+'--------'+e.getStackTraceString());
            errorHandler.createError(e);
        }

        errorHandler.save();
    }

}