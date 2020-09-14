global class PlatformEventCleanUpBatch implements Schedulable, Database.batchable<SObject>{ 
   global void execute(SchedulableContext SC) {
        PlatformEventCleanUpBatch batch = new PlatformEventCleanUpBatch();
        database.executebatch(batch, 100);
   }
    
   global Iterable<Sobject> start(Database.batchableContext info){ 
       Iterable<SObject> myIter = (Iterable<SObject>) new CustomIterable();
       system.debug('Iter-->' + myIter);
       return myIter; 
   }     
   
   global void execute(Database.batchableContext info, List<SObject> scope){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PlatformEventCleanUpBatch.class.getName());
        // Get the space records that we need to send platform event
        // Step 1: Add two list, one object list, one Id list
        List<Space__c> spaces = new List<Space__c>();
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Opportunity> oppos = new List<Opportunity>();
        List<Case> cases = new List<Case>();
        List<Task> tasks = new List<Task>();
        List<Id> spaceIds = new List<Id>();
       	List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        List<Id> oppoIds = new List<Id>();
        List<Id> caseIds = new List<Id>();
        List<Id> taskIds = new List<Id>();
       	Map<Id, Id> recordIdToRecordTypeId = new Map<Id, Id>();
        for (SObject record : scope) {
            // Step 2 : According to the object type, put into two lists created from step 1
            if (String.ValueOf(record.getsObjectType()) == Constants.SPACE) {
                Space__c space = (Space__c) record;
                spaces.add(space);
                spaceIds.add(space.Id);
            } else if (String.ValueOf(record.getsObjectType()) == Constants.ACCOUNT) {
                Account account = (Account) record;
                accounts.add(account);
                accountIds.add(account.Id);
            } else if (String.ValueOf(record.getsObjectType()) == Constants.CONTACT) {
                Contact contact = (Contact) record;
                contacts.add(contact);
                contactIds.add(contact.Id);
            } else if (String.ValueOf(record.getsObjectType()) == Constants.OPPORTUNITY) {
                Opportunity oppo = (Opportunity) record;
                oppos.add(oppo);
                oppoIds.add(oppo.Id);
            } else if (String.ValueOf(record.getsObjectType()) == Constants.OBJECT_CASE) {
                Case caseRecord = (Case) record;
                cases.add(caseRecord);
                caseIds.add(caseRecord.Id);
                recordIdToRecordTypeId.put(caseRecord.Id, caseRecord.RecordTypeId);
            } else if (String.ValueOf(record.getsObjectType()) == Constants.TASK) {
                Task taskRecord = (Task) record;
                tasks.add(taskRecord);
                taskIds.add(taskRecord.Id);
            }
        }
       // Generate platform events
       /**** Special for contact address book event****/
       ContactBL.ContactWithFinalizedOppoWrapper conW = ContactBL.constructBaseStructureFromContact(contactIds);
       List<AccountContactEvent__e> successfullpublishAddressBook=new List<AccountContactEvent__e>(); 
       if (conW.sendEvent) {
            List<AccountContactEvent__e> addressBookEvents = ContactBL.constructPE(conW);
            List<Database.SaveResult> resultsAddressBook = EventBus.publish(addressBookEvents);
            for(integer i=0; i<resultsAddressBook.size(); i++){
               if(resultsAddressBook[i].isSuccess()){
                   successfullpublishAddressBook.add(addressBookEvents[i]);
               }
           	}
           if (successfullpublishAddressBook.size() > 0) {
            	ContactBL.updateContactWhenAddressBookEventSentSuccess(successfullpublishAddressBook);   
           }
        }
       /****End contact address book event****/
       // Step 3 : According to the object type, get apiname list from custom meta data
       List<PlatformEventPayloadSelection__mdt > payloadSelections = [SELECT ObjectApiName__c, Content__c FROM PlatformEventPayloadSelection__mdt LIMIT 10000];
       List<String> spaceApiNames = new List<String>();
       List<String> accountApiNames = new List<String>();
       List<String> oppoApiNames = new List<String>();
       List<String> caseApiNames = new List<String>();
       List<String> taskApiNames = new List<String>();
       for (PlatformEventPayloadSelection__mdt selection : payloadSelections) {
           if (selection.ObjectApiName__c == Constants.SPACE) {
               spaceApiNames = PlatformEventUtils.constructApiNames(selection.Content__c);
           } else if (selection.ObjectApiName__c == Constants.ACCOUNT) {
               accountApiNames = PlatformEventUtils.constructApiNames(selection.Content__c);
           } else if (selection.ObjectApiName__c == Constants.OBJECT_CASE) {
               caseApiNames = PlatformEventUtils.constructApiNames(selection.Content__c);
           } else if (selection.ObjectApiName__c == Constants.OPPORTUNITY) {
               oppoApiNames = PlatformEventUtils.constructApiNames(selection.Content__c);
           } else if (selection.ObjectApiName__c == Constants.TASK) {
               taskApiNames = PlatformEventUtils.constructApiNames(selection.Content__c);
           }
       }
       // Step 4 : According to the object type, generate JSON payload
       List<String> jsonPayloadSpace = PlatformEventUtils.getRecordsJsonPayload(spaceIds, spaceApiNames);
       List<String> jsonPayloadAccount = PlatformEventUtils.getRecordsJsonPayload(accountIds, accountApiNames);
       List<String> jsonPayloadOppo = PlatformEventUtils.getRecordsJsonPayload(oppoIds, oppoApiNames);
       Map<Id, String> jsonPayloadCase = PlatformEventUtils.getRecordsJsonPayloadMap(caseIds, caseApiNames);
       List<String> jsonPayloadTask = PlatformEventUtils.getRecordsJsonPayload(taskIds, taskApiNames);
       
       List<SpaceEvent__e> spaceEvents = SpaceBL.generateSpaceEvents(jsonPayloadSpace);
       List<AccountEvent__e> accountEvents = AccountBL.generateAccountEvents(jsonPayloadAccount);
       List<OpportunityEvent__e> oppoEvents = OpportunityBL.generateOppoEvents(jsonPayloadOppo);
       List<CaseEvent__e> caseEvents = CaseBL.generateCaseEventsByMap(jsonPayloadCase, recordIdToRecordTypeId);
       List<TaskEvent__e> taskEvents = TaskBL.generateTaskEvents(jsonPayloadTask);
       // Send platform events
       // Step 5 : According to the event type, send event
       List<SpaceEvent__e> successfullpublish=new List<SpaceEvent__e>();
       List<AccountEvent__e> successfullpublishAccount=new List<AccountEvent__e>();
       List<OpportunityEvent__e> successfullpublishOppo=new List<OpportunityEvent__e>();
       List<CaseEvent__e> successfullpublishCase=new List<CaseEvent__e>();
       List<TaskEvent__e> successfullpublishTask=new List<TaskEvent__e>();
       List<Database.SaveResult> results = EventBus.publish(spaceEvents);
       List<Database.SaveResult> resultsAccount = EventBus.publish(accountEvents);
       List<Database.SaveResult> resultsOppo = EventBus.publish(oppoEvents);
       List<Database.SaveResult> resultsCase = EventBus.publish(caseEvents);
       List<Database.SaveResult> resultsTask = EventBus.publish(taskEvents);
       for(integer i=0; i<results.size(); i++){
           if(results[i].isSuccess()){
               successfullpublish.add(spaceEvents[i]);
           }
       }
       for(integer i=0; i<resultsAccount.size(); i++){
           if(resultsAccount[i].isSuccess()){
               successfullpublishAccount.add(accountEvents[i]);
           }
       }
       for(integer i=0; i<resultsOppo.size(); i++){
           if(resultsOppo[i].isSuccess()){
               successfullpublishOppo.add(oppoEvents[i]);
           }
       }
       for(integer i=0; i<resultsCase.size(); i++){
           if(resultsCase[i].isSuccess()){
               successfullpublishCase.add(caseEvents[i]);
           }
       }
       for(integer i=0; i<resultsTask.size(); i++){
           if(resultsTask[i].isSuccess()){
               successfullpublishTask.add(taskEvents[i]);
           }
       }
       // Step 6 : According to the event type, update dispatchversion and dispatch time stamp
       try {
       		SpaceBL.updateSpaceWhenSpaceEventSentSuccess(successfullpublish);
       } catch(Exception e) {
           errorHandler.createError(e);
       }
       try {
       		AccountBL.updateAccountWhenAccountEventSentSuccess(successfullpublishAccount);
       } catch(Exception e) {
           errorHandler.createError(e);
       }
       try {
       		OpportunityBL.updateOppoWhenOppoEventSentSuccess(successfullpublishOppo);
       } catch(Exception e) {
           errorHandler.createError(e);
       }
       try {
       		CaseBL.updateCaseWhenCaseEventSentSuccess(successfullpublishCase);
       } catch(Exception e) {
           errorHandler.createError(e);
       }
       try {
       		TaskBL.updateTaskWhenTaskEventSentSuccess(successfullpublishTask);
       } catch(Exception e) {
           errorHandler.createError(e);
       }
       errorHandler.save();
   }     
   
   global void finish(Database.batchableContext info){     
   
   } 
}