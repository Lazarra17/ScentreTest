global class UpdateOpptyTargetBreached implements 
Database.Batchable<sObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Target_Breached__c,StageName FROM Opportunity WHERE (StageName = \'Register Lease\' OR StageName = \'Closed - Completed\' OR StageName = \'Issue Lease\') AND SpecialityLeaseType__c = \'\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Opportunity> scope){
        // process each batch of records
        List<Opportunity> oppsKPI1 = new List<Opportunity>();
        List<Opportunity> oppsKPI2NonJV = new List<Opportunity>();
        List<Opportunity> oppsKPI2JV = new List<Opportunity>();
        
        Integer KPIRule1 = 0;
        Integer KPIRule2NonJV = 0;
        Integer KPIRule2JV = 0;
        Boolean KPI1 = false;
        Boolean KPI2NonJV = false;
        Boolean KPI2JV = false;
        
        Integer index = 0;
        
        Set<Id> oppSetKPI1 = new Set<Id>();
        Set<Id> oppSetKPI2 = new Set<Id>();
        
        Set<String> updatedOppIds = new Set<String>();
        
        for(Opportunity opp : scope){
            
            if(opp.StageName == 'Issue Lease'){
                oppSetKPI1.add(opp.id);
            }
            
            if(opp.StageName == 'Register Lease' || opp.StageName == 'Closed - Completed')
                oppSetKPI2.add(opp.id);
            
        }
        
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([SELECT Id, Target_Breached__c from Opportunity where ID IN : oppSetKPI1 OR ID IN: oppSetKPI2]);
        
        Opportunity opp;
        
        AggregateResult[] KPIRule2NonJVSummation = [SELECT  WhatId,SUM(ActivityDuration__c) from Task where (WHATID IN: oppSetKPI1 OR WhatID IN: oppSetKPI2) AND Status = 'Completed' AND (TaskType__c = '25 - Send Executed Lease to Solicitor' OR TaskType__c = '23 - Send Documents for Execution' OR TaskType__c = '28 - RM Retail Admin Execute Documents' OR TaskType__c = '20 - RM Leasing Execute Documents' OR TaskType__c = '03 - Certify Lease' OR TaskType__c = '19 - Receive Certified Lease' OR TaskType__c = '17 - Register Lease') GROUP BY whatid];
        
        for (AggregateResult ar : KPIRule2NonJVSummation)  {
            System.debug('Opp ID' + ar.get('WhatId'));
            System.debug('Sum=> ' + ar.get('expr0'));
            
            if(ar.get('expr0') != null){
                
                if(Integer.ValueOf(ar.get('expr0')) > 59){
                    opp = new Opportunity();
                    if(ar.get('WhatId') != null){
                        
                        opp.id = String.valueOf(ar.get('WhatId'));
                        updatedOppIds.add(String.valueOf(ar.get('WhatId')));
                    }
                    //RPP-10769 - start
                    String str = '';
                    if(opportunityMap.containsKey(String.valueOf(ar.get('WhatId')))){
                        str = opportunityMap.get(String.valueOf(ar.get('WhatId'))).Target_Breached__c;
                        if(str != NULL && (!str.containsIgnoreCase('Documents Execution'))){
                            str = str + ';Documents Execution';
                        }else if(str == NULL){
                            str = 'Documents Execution';
                        }
                        system.debug('str******67: '+str);
                    }
                    opp.Target_Breached__c = str;
                    //RPP-10769 - end
                    
                    
                    // opp.Target_Breached__c = 'Documents Execution';
                    //if(!oppsKPI2NonJV.contains(opp))
                    oppsKPI2NonJV.add(opp);
                    System.debug('Each oppsKPI2NonJV=> '+ oppsKPI2NonJV);
                }
            }
            
        }
        ////////////////////////////////
        
        AggregateResult[] KPIRule2JVSummation = [SELECT  WhatId,SUM(ActivityDuration__c) from Task where (WHATID IN: oppSetKPI1 OR WhatID IN: oppSetKPI2) AND Status = 'Completed' AND (TaskType__c = '25 - Send Executed Lease to Solicitor' OR TaskType__c = '23 - Send Documents for Execution' OR TaskType__c = '28 - RM Retail Admin Execute Documents' OR TaskType__c = '20 - RM Leasing Execute Documents' OR TaskType__c = '03 - Certify Lease' OR TaskType__c = '19 - Receive Certified Lease' OR TaskType__c = '17 - Register Lease' OR TaskType__c = '24 - Send Documents to JV for Execution') GROUP BY whatid];
        
        for (AggregateResult ar : KPIRule2JVSummation)  {
            System.debug('Opp ID' + ar.get('WhatId'));
            System.debug('Sum=> ' + ar.get('expr0'));
            
            if(ar.get('expr0') != null) 
                if(Integer.valueOf(ar.get('expr0')) > 59 && oppSetKPI2.contains(String.ValueOf(ar.get('WhatId')))){
                   /* if(updatedOppIds.contains(String.ValueOf(ar.get('WhatId'))))
                        if(!Test.isRunningTest())
                        continue;
                    */
                    opp = new Opportunity();
                    opp.id = String.ValueOf(ar.get('WhatId'));
                    //RPP-10769 - start
                    String str = '';
                    if(opportunityMap.containsKey(String.valueOf(ar.get('WhatId')))){
                        str = opportunityMap.get(String.valueOf(ar.get('WhatId'))).Target_Breached__c;
                        if(str != NULL && (!str.containsIgnoreCase('Documents Execution'))){
                            str = str + ';Documents Execution';
                        }else if(str == NULL){
                            str = 'Documents Execution';
                        }
                        system.debug('str******108: '+str);
                    }
                    
                    opp.Target_Breached__c = str;
                    //RPP-10769 - end
                    //opp.Target_Breached__c = 'Documents Execution';
                    //if(!oppsKPI2JV.contains(opp)) 
                    oppsKPI2JV.add(opp);
                    System.debug('Each oppsKPI2JV=> '+ oppsKPI2JV);
                    updatedOppIds.add(String.valueOf(ar.get('WhatId')));
                }
            
            
        }  
        
        ///////////////////////////////
        
        
        
        AggregateResult[] KPIRule1Summation = [SELECT  WhatId,SUM(Activity_BD_Duration__c) from Task where (WHATID IN: oppSetKPI1 OR WhatID IN: oppSetKPI2) AND Status = 'Completed' AND (TaskType__c = '07 - Generate Acceptance (w/ Modifications)' OR TaskType__c = '40 - Send Acceptance (w/ Modifications)' OR
                                                                                                                                                                                          TaskType__c = '39 - Instruct Solicitor' OR TaskType__c = '13 - Issue Lease Documents') GROUP BY whatid];
        
        for (AggregateResult ar : KPIRule1Summation)  {
            System.debug('Opp ID' + ar.get('WhatId'));
            System.debug('Sum=> ' + ar.get('expr0'));
            
            
            if(ar.get('expr0') != null){
                if(Integer.valueOf(ar.get('expr0')) > 5 && oppSetKPI1.contains(String.valueOf(ar.get('WhatId')))){
                   /* if(updatedOppIds.contains(String.ValueOf(ar.get('WhatId'))))
                        continue;
                    */
                    opp = new Opportunity();
                    opp.id = String.ValueOf(ar.get('WhatId'));
                    //RPP-10769 - start
                    String str = '';
                    if(opportunityMap.containsKey(String.valueOf(ar.get('WhatId')))){
                        str = opportunityMap.get(String.valueOf(ar.get('WhatId'))).Target_Breached__c;
                        if(str != NULL && (!str.containsIgnoreCase('Acceptance to Issue Lease'))){
                            str = str + ';Acceptance to Issue Lease';
                        }else if(str == NULL){
                            str = 'Acceptance to Issue Lease';
                        }
                        system.debug('str******149: '+str);
                    }
                    opp.Target_Breached__c = str;
                    //RPP-10769 - end
                    //opp.Target_Breached__c = 'Acceptance to Issue Lease';
                    KPI1 = true;
                    //if(!oppsKPI1.contains(opp)) 
                    oppsKPI1.add(opp);
                    System.debug('Each oppsKPI1=> '+ oppsKPI1);
                    updatedOppIds.add(String.valueOf(ar.get('WhatId')));
                }
            }
        }             
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////
        
        System.debug('Each KPIRule1=> '+ KPIRule1);
        System.debug('Each KPIRule2NonJV=> '+ KPIRule2NonJV);
        System.debug('Each KPIRule2JV=> '+ KPIRule2JV);
        
        
        try{
            if(oppsKPI1.size() > 0){
                Database.update(oppsKPI1,false);
            }
            
            if(oppsKPI2NonJV.size() > 0){
                Database.update(oppsKPI2NonJV,false);
            }
            
            if(oppsKPI2JV.size() > 0){
               Database.update(oppsKPI2JV,false);
            }
        }
        catch(Exception ex){
            System.debug('Error: '+ex.getLineNumber());
            System.debug('Error: '+ex.getMessage());
            System.debug('Error: '+ex.getStackTraceString());
        } 
        
    }    
    global void finish(Database.BatchableContext bc){
        
    }    
}