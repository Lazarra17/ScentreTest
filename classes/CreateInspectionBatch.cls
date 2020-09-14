global class  CreateInspectionBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        if(Test.isRunningTest()){
            return Database.getQueryLocator([SELECT Id,CurrentLease__c from Space__c where CurrentLease__c!=null]);
        }
        
        return Database.getQueryLocator([SELECT Id,CurrentLease__c,
                                         //added below filter to implement RPP-10876
                                         (SELECT Id, CreatedDate
                                          FROM Cases__r
                                          WHERE RecordType.Name =: Constants.CASE_RECORDTYPE_INSPECTIONREPORT 
                                          AND CreatedDate != LAST_N_DAYS:60 )
                                         FROM Space__c 
                                         WHERE CurrentLease__c != NULL 
                                         AND CreateInspectionReport__c = true
                                         //added below filter to implement RPP-10999
                                         AND CurrentLease__r.LeaseType__c !=: Constants.CON_LEASE_TYPE_MAJOR]);
        
        //return Database.getQueryLocator([SELECT Id,CurrentLease__c from Space__c where CurrentLease__c!=null and CreateInspectionReport__c = true and property__c = 'a0a2O0000004dBOQAY']);
    }
    
    global void execute(SchedulableContext sc){
        CreateInspectionBatch schedulableBatch = new CreateInspectionBatch();
        Database.executeBatch(schedulableBatch);
    }
    
    global void execute(Database.BatchableContext BC, List<Space__c> spaceList){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(CreateInspectionBatch.class.getName());
        
        List<Case> createInspectionList=new List<Case>();
        TriggerHandler.bypass('CaseTriggerHandler');
        Set<Id> contractIdSet=new Set<Id>();
        
        if(spaceList.size()>0&&!spaceList.isEmpty()){
            for(Space__c spaceRecord: spaceList){
                contractIdSet.add(spaceRecord.CurrentLease__c);
            }
        }
        
        List<Contract__c> contractList = new List<Contract__c>();
        Map<Id,Contract__c> contractMap = new Map<Id,Contract__c>([SELECT Id, Property__c, Name,Property__r.Name, Space__c,
                                                                   Space__r.Name, Space__r.CurrentLease__c, Account__r.Name,
                                                                   LeaseEndDate__c, Account__c, Account__r.ParentId, Opportunity__c 
                                                                   FROM Contract__c 
                                                                   WHERE Id IN: contractIdSet 
                                                                   AND AutoInspectionReportCreated__c = FALSE]);
        contractList.addAll(contractMap.Values());
        
        if(contractList.size()>0&&!contractList.isEmpty()){
            createInspectionList = CaseBL.CreateInspectionforContract(ContractList);
            List<Contract__c> contractsToupdateList = new List<Contract__c>();
            
            if(createInspectionList.size() > 0 && !createInspectionList.isEmpty()){
                List<Database.SaveResult> saveResultList = Database.Insert(createInspectionList, false); 
                system.debug('saveResultList ' + createInspectionList );  //added
                Integer counter = 0;
                
                for(Database.SaveResult saveResult : saveResultList){
                    system.debug('saveResultList ' + saveResult ); //added
                    
                    if(saveResult.isSuccess()){
                        system.debug('----  inside the if to make autoInsRepCr =true ---- ' );  //added
                        
                        Contract__c contracttoupdate = new Contract__c();
                        //contracttoupdate.AutoInspectionReportCreated__c=true;
                        contracttoupdate.Id = createInspectionList[counter].Contract__c;
                        contracttoupdate.AutoInspectionReportCreated__c = true;
                        
                        system.debug('AutoInspectionReportCreated__c >>>> '+contracttoupdate.AutoInspectionReportCreated__c); //added
                        
                        if(!contractsToupdateList.contains(contracttoupdate)){
                            contractsToupdateList.add(contracttoupdate);
                        }
                        system.debug('contractsToupdateList >>> '+contractsToupdateList);
                    }
                    for(Database.Error err : saveResult.getErrors()) {
                        errorHandler.createError(err, createInspectionList[counter].Id);
                        System.debug('ERROR IN CreateInspectionBatch: '+ err);
                    }
                    
                    counter++;
                }                
                errorHandler.save();
                
                if(contractsToupdateList.size() > 0 && !contractsToupdateList.isEmpty()){
                    system.debug(' UPDATE here '); //added
                    update contractsToupdateList;
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}