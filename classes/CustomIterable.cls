global class CustomIterable implements Iterable<SObject>, Iterator<SObject>{ 
   
   public Iterator<SObject> iterator() { return this; }
   
   List<SObject> sobjs {get; set;} 
   Integer i {get; set;} 
   public CustomIterable(){ 
       sobjs = new List<SObject>();
       //Add space
       List<Space__c> spaces = [SELECT Id, TechDispatchedVersion__c, TechDispatchedTimeStamp__c FROM Space__c WHERE TechEventVersionSame__c = FALSE ORDER BY Property__c Limit 10000]; 
       if (spaces.size() > 0) {
           for( Space__c space : spaces ) {
               sobjs.add(space);
           }   
       }
       //Add accounts
       List<Account> accounts = [SELECT Id, TechDispatchedVersion__c, TechDispatchedTimeStamp__c FROM Account WHERE TechEventVersionSame__c = FALSE Limit 10000];
       if (accounts.size() > 0) {
           for( Account account : accounts ) {
               sobjs.add(account);
           }   
       }
       //Add contact
       List<Contact> contacts = [SELECT Id, TechDispatchedVersion__c, TechDispatchedTimeStamp__c FROM Contact WHERE TechEventVersionSame__c = FALSE Limit 10000];
       if (contacts.size() > 0) {
       		for( Contact contact : contacts ) {
           		sobjs.add(contact);
       		}    
       }
       
       //Add opportunity TechEventVersionSame__c 
       List<Opportunity> oppos = [SELECT Id, TechDispatchedVersion__c, TechDispatchedTimeStamp__c FROM Opportunity WHERE TechEventVersionSame__c = FALSE Limit 10000];
       if (oppos.size() > 0) {
           for( Opportunity oppo : oppos ) {
               sobjs.add(oppo);
           }   
       }
       //Add case
       List<Case> cases = [SELECT Id, RecordTypeId, Status, TechDispatchedVersion__c, TechDispatchedTimeStamp__c, JDESentStatus__c FROM Case WHERE TechEventVersionSame__c = FALSE Limit 10000];
       List<Case> validCases = CaseBL.caseEventCriteriaCheck(cases);
       if (validCases.size() > 0) {
       	   for( Case caseRecord : validCases ) {
               sobjs.add(caseRecord);
           }   
       }
       //Add task
       List<Task> tasks = [SELECT Id, taskType__c, Status, TechDispatchedVersion__c, TechDispatchedTimeStamp__c, WhatId FROM Task WHERE TechEventVersionSame__c = FALSE Limit 10000];
       if (tasks.size() > 0) {
           for( Task task : tasks ) {
               sobjs.add(task);
           }
       }
       i = 0; 
   }   
   global boolean hasNext(){ 
       if(i >= sobjs.size()) 
           return false; 
       else 
           return true; 
   }    
   global SObject next(){ 
       if(i == sobjs.size()){ i++; return null;} 
       i=i+1; 
       return sobjs[i-1]; 
   } 
}