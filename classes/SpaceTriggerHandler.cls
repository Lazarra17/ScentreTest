/** 
* Class SpaceTriggerHandler
*
* Trigger Handler for the Opportunity SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public class SpaceTriggerHandler extends TriggerHandler implements ITrigger{
    
    List<SpaceAuditHistory__c> histories = new List<SpaceAuditHistory__c>();
    List<SpaceEvent__e> spaceeventstoPublish=new List<SpaceEvent__e>();
    Map<Id,Space__c> dbSpacedataMap;
    Map<Id,Space__c> dbSpacedataMaptopublish=new Map<Id,Space__c>();
    List<Opportunity> forecastOpptysToCreate = new List<Opportunity>();
    Map<Id, List<Account>> propertyIdVsAccount = new Map<Id, List<Account>>();
    Map<Id, List<Opportunity>> spaceVsForecastOpptys = new Map<Id, List<Opportunity>>();
    List<User> migrationUser = new List<User>();

    // Constructor
    public SpaceTriggerHandler(){
        
    }
    /**
* This method is called prior to execution of a AFTER trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    Map<Id,Space__c> beforetriggerMap=new Map<Id,Space__c>();
    ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceTriggerHandler.class.getName());
    
    public void bulkBefore(){
        Map<Id, Space__c> dbspaceRecordsMap = new Map<Id, Space__c>();
        if(Trigger.IsInsert||Trigger.IsUpdate){
            Set<Id> spaceidset=new Set<id>();
            if(Trigger.IsUpdate){
                spaceidset.addall(Trigger.newmap.keyset());
                //call the function: apex validation ticket 10446
                validateForRentableUsableArea(spaceidset);
            }
            
            try{
              beforetriggerMap= SpaceOccupancyUpdateHelper.updateOccupancyStatus(spaceidset,Trigger.new,DatabaseSOQLBank.getSpaceRecords(spaceidset));
            }
            catch(Exception e){
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
    /**
* This method is called prior to execution of a BEFORE trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    public void bulkAfter(){
        
        if(Trigger.IsUpdate){
            HistoryTrackingUtil.HistoryTrackingWrapper historyTracker =  new HistoryTrackingUtil.HistoryTrackingWrapper();
            historyTracker.newMap = Trigger.newMap;
            historyTracker.oldMap = Trigger.oldMap;
            historyTracker.objectAPIName = Constants.SPACE;
            historyTracker.FieldSetAPIName = Constants.FIELD_SET_API_NAME;
            historyTracker.historyobjectAPIname = Constants.HISTORY_TRACKING_SPACE;
            histories = (List<SpaceAuditHistory__c>) HistoryTrackingUtil.historyTracking(historyTracker);

            dbSpacedataMap=new Map<Id,Space__c>([Select id, LatestAchievedOpportunity__c, LatestAchievedOpportunity__r.StageName, LatestAchievedOpportunity__r.JDESentStatus__c from Space__c where id IN :Trigger.newMap.keySet()]);
            for(Space__c spaceRecord: dbSpacedataMap.values()){
                System.debug(spaceRecord+'**OPPTYSTAGENAME**'+spaceRecord.LatestAchievedOpportunity__r.JDESentStatus__c);
                if(spaceRecord.LatestAchievedOpportunity__c!=null&&spaceRecord.LatestAchievedOpportunity__r.JDESentStatus__c != ''){
                    dbSpacedataMaptopublish.put(spaceRecord.id,spaceRecord);
                }
            }
        }

        if(Trigger.isInsert){
            //Start: RPP-10631
            List<Space__c> newList = (List<Space__c>) Trigger.new;
            migrationUser = DatabaseSOQLBank.getdataMigrationUser();

            Set<Id> propertyId = new Set<Id>();
            Set<Id> spaceIds = new Set<Id>();

            for(Space__c spc : newList){
                spaceIds.add(spc.Id);
                propertyId.add(spc.Property__c);                
            }
            
            /*for(Opportunity forecastOppty : DatabaseSOQLBank.getForecastOpptyForSpace(spaceIds)){
                if(spaceVsForecastOpptys.containsKey(forecastOppty.Space__c)){
                    spaceVsForecastOpptys.get(forecastOppty.Space__c).add(forecastOppty);
                }else{
                    spaceVsForecastOpptys.put(forecastOppty.Space__c, new List<Opportunity>());
                }
            }*/

            for(Account forecastPropertyAccs : DatabaseSOQLBank.getForecastAccountForProperty(propertyId)){
                if(propertyIdVsAccount.containsKey(forecastPropertyAccs.Property__c)){
                    propertyIdVsAccount.get(forecastPropertyAccs.Property__c).add(forecastPropertyAccs);
                }else{
                    propertyIdVsAccount.put(forecastPropertyAccs.Property__c, new List<Account>());
                    propertyIdVsAccount.get(forecastPropertyAccs.Property__c).add(forecastPropertyAccs);
                }
            }
            System.debug('propertyIdVsAccount: '+propertyIdVsAccount);
            //End: RPP-10631

        }
        
        System.debug('**BULKBEFORE**'+dbSpacedataMaptopublish);
        EventpublishHelper.Eventpublishwrapper spacewrapper=new EventpublishHelper.Eventpublishwrapper();
        if(Trigger.isupdate&&EventpublishHelper.isValidpublish()&&dbSpacedataMaptopublish!=null&&dbSpacedataMaptopublish.size()>0){
            spacewrapper=EventpublishHelper.SpacefieldChangepublishHelper(Trigger.oldMap,Trigger.newMap,dbSpacedataMaptopublish);
            spaceeventstoPublish.addAll((List<SpaceEvent__e>)spacewrapper.eventsobjectList);
        }
    }
    /**
* This method is called iteratively for each record to be inserted during a BEFORE
* trigger.
* This or other This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeInsert(SObject so){
        Space__c beforeinsertspacerecordnew = (Space__c)so;
    }
    /**
* This method is called iteratively for each record to be updated during a BEFORE
* trigger.
* This or other methods to be called here must not contain DML statements or queries.
*/
    public void beforeUpdate(SObject oldSo, SObject so){
        Space__c space = (Space__c)so;
        Space__c oldSpace = (Space__c)oldSo;
        
        // Add space checking in here
        if ((oldSpace.Status__c != 'Inactive' && space.Status__c == 'Inactive' && oldSpace.Status__c != space.Status__c) ||
           (oldSpace.Status__c == 'Inactive' && oldSpace.Status__c != space.Status__c)) {
               space.StatusChangedDate__c = Date.today();
               space.Relationship__c = NULL;
        }
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
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceTriggerHandler.class.getName());
        Space__c newSpace = (Space__c) so;

        Id oppCommId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Commercial Leasing').getRecordTypeId();
        Id oppRetId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Retail Leasing').getRecordTypeId();
        
        if(newSpace.Status__c == Constants.SPACE_STATUS_INACTIVE || newSpace.Status__c == Constants.SPACE_STATUS_HELD){
            return;
        }else if(newSpace.Type__c != '1' && newSpace.Type__c != '2' && newSpace.Type__c != '3'){
            return;
        }else{
            Id accountId;
            System.debug('propertyIdVsAccount: '+propertyIdVsAccount);
            if(propertyIdVsAccount.size() == 0 || propertyIdVsAccount.get(newSpace.Property__c).size() == 0)
                return;

            if(propertyIdVsAccount.get(newSpace.Property__c).size() == 1){
                accountId = propertyIdVsAccount.get(newSpace.Property__c)[0].Id;
            }else if(propertyIdVsAccount.get(newSpace.Property__c).size() > 1){
                for(Account acc : propertyIdVsAccount.get(newSpace.Property__c)){
                    if(acc.Property__r.PropertyOwnershipType__c == Constants.MANAGED)
                        accountId = acc.Id;
                }
            }

            Opportunity newForecastOppty = new Opportunity();
            newForecastOppty.Name = 'Test 1';
            newForecastOppty.Space__c = newSpace.Id;
            newForecastOppty.Property__c = newSpace.Property__c;
            newForecastOppty.AccountId = accountId;
            newForecastOppty.StageName = Constants.UNDERSTAND_NEGOTIATE;
            newForecastOppty.DealType__c = Constants.DEALTYPE_SEMI_GROSS;
            newForecastOppty.BestBet__c = FALSE;
            newForecastOppty.CloseDate = Date.newInstance(Date.today().year(), 12, 31);
            newForecastOppty.ProposedHandoverDate__c = Date.newInstance(Date.today().year(), 12, 31);
            newForecastOppty.OwnerId = migrationUser[0].Id;
            newForecastOppty.Created_from_Space_Creation__c = TRUE;

            if(newSpace.Type__c == '1' || newSpace.Type__c == '2')
                newForecastOppty.RecordTypeId = oppRetId;
            else if(newSpace.Type__c == '3')
                newForecastOppty.RecordTypeId = oppCommId;

            forecastOpptysToCreate.add(newForecastOppty);

        }
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
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(SpaceTriggerHandler.class.getName());
        Database.SaveResult[] sr;
        if(forecastOpptysToCreate.size() > 0)
            sr = Database.insert(forecastOpptysToCreate, FALSE);
        
        System.debug('SaveResult: '+sr);

        if(!histories.isEmpty()&&histories.size()>0){
            try{
                Database.insert(histories);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        
        Set<Id> spaceidstoudpatedispatchdetails=new Set<Id>();
        List<SpaceEvent__e> successfullpublish=new List<SpaceEvent__e>();
        System.debug('**FINALLY TO PUBLISH**'+spaceeventstoPublish);
        // publish the event for any changes in field values (field are maintainced in metadata)
        if(spaceeventstoPublish.size()>0 && !spaceeventstoPublish.isEmpty()){
            List<Database.SaveResult> publishresults = EventBus.publish(spaceeventstoPublish);
            // Inspect publishing result for each event
            for(integer i=0;i<publishresults.size();i++){
                if(publishresults[i].isSuccess()){
                    successfullpublish.add(spaceeventstoPublish[i]);
                }
            } 
        }
        List<Space__c> spacetoupdatedispatchdetailsList=new List<Space__c>(); 
        if(!successfullpublish.isEmpty()&&successfullpublish.size()>0){
            for(SpaceEvent__e publishedevent: successfullpublish){
                // get values from pubished event payload to update parent records
                Map<String, Object> publishedspaceevents;
                try {
                    publishedspaceevents=(Map<String, Object>)JSON.deserializeUntyped(publishedevent.JSONPayload__c);
                } catch (Exception e) {
                    publishedspaceevents = NULL;
                }
                if(publishedspaceevents != NULL && !publishedspaceevents.isEmpty()) {
                    System.debug('**DISPATCHEEVENT**'+publishedspaceevents);
                    Space__c spacetoupdatedispatchdetails=new Space__c();
                    spacetoupdatedispatchdetails.id=(id)publishedspaceevents.get(Constants.DML_ID.toUpperCase());
                    String dispatchtimestampstr=(String)publishedspaceevents.get(Constants.TECH_DISPATCHTIMESTAMP.toUpperCase());
                    spacetoupdatedispatchdetails.TechDispatchedTimeStamp__c =DateTime.valueOf(dispatchtimestampstr);
                    String dispatchversionstr=(String)publishedspaceevents.get(Constants.TECH_DISPATCHVERSION.toUpperCase());
                    spacetoupdatedispatchdetails.TechDispatchedVersion__c=Decimal.valueOf(dispatchversionstr);
                    spacetoupdatedispatchdetailsList.add(spacetoupdatedispatchdetails);
                }
            }
        }
        System.debug('**FORUPDATE**'+spacetoupdatedispatchdetailsList);
        if(!spacetoupdatedispatchdetailsList.isEmpty()&&spacetoupdatedispatchdetailsList.size()>0){
            
            try{
                Database.update(spacetoupdatedispatchdetailsList);
            } catch(Exception e) {
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
    
    //changes for ticket 10446_29May2019
    public void validateForRentableUsableArea(Set<Id> spaceIds){
        
        //Set<Id> spaceIds; //value from trigger 

      Boolean isTrueOpp = False;
      Boolean isTrueCon = False;
      Boolean isTrueSpcType = False;
      Boolean isRequiredUser = False;
      
      Id OppCommId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Commercial Leasing').getRecordTypeId();
      Id OppRetId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Retail Leasing').getRecordTypeId();
      Id OppStrRId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Storeroom Leasing').getRecordTypeId();
   
      User u = [SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Id =: userInfo.getUserId()]; 

      if(u.Profile.Name == 'System Administrator' || u.Profile.Name =='SCG-SysAdm' || u.Profile.Name =='SCG-Sys DataMigration' || u.Profile.Name =='SCG-Sys Integration'){
          return;
      }
        
        for(Space__c spc : (List<Space__c>) Trigger.newMap.values()){
            Space__c oldSpace = (Space__c) Trigger.oldMap.get(spc.Id);
            if(spc.RentableArea__c != oldSpace.RentableArea__c || spc.UsableArea__c != oldSpace.UsableArea__c){
                    if(u.Profile.Name == 'SCG-Retail Finance' && spc.Status__c == 'Project'){
                        return;
                    }else if(u.Profile.Name == 'SCG-Retail Finance' && spc.Status__c != 'Project'){
                		Trigger.newMap.get(spc.Id).addError('Rentable and Usable Area cannot be modified.'); return;
                    }else if(u.Profile.Name != 'SCG-Retail Finance' && u.Profile.Name != 'SCG-Retail CentreMgt'){      //&& replaced with OR 
                        Trigger.newMap.get(spc.Id).addError('Rentable and Usable Area cannot be modified.'); return;
                    }
                
            }
        }

     
     if(u.Profile.Name != 'SCG-Retail CentreMgt' && u.UserRole.Name != 'Retail CRM')
       	  isRequiredUser = TRUE;
	
     for(Space__c spc : [SELECT Id,Type__c, (SELECT Id, StageName, ApprovalStatus__c,RecordTypeId FROM Opportunities__r), (SELECT Id,LeaseStatus__c FROM Leases__r) FROM Space__c WHERE ID In : spaceIds]){
         Space__c oldSpace = (Space__c) Trigger.oldMap.get(spc.Id);
         Space__c newSpace = (Space__c) Trigger.newMap.get(spc.Id);
         if((oldSpace.RentableArea__c != newSpace.RentableArea__c) || (oldSpace.UsableArea__c != newSpace.UsableArea__c)){
             //if(spc.Type__c =='Store Room' &&  spc.Type__c =='Seating' && spc.Type__c =='Garage / Parking' && spc.Type__c =='Sundry'){  //api names
             if(spc.Type__c !='4' &&  spc.Type__c !='5' && spc.Type__c !='8' && spc.Type__c !='9')//{
                 isTrueSpcType = TRUE;
         
                for(Opportunity opp : spc.Opportunities__r){
                  if(opp.RecordTypeId == OppCommId || opp.RecordTypeId == OppRetId){
	                  System.debug('opp.ApprovalStatus__c: '+opp.ApprovalStatus__c);
                      if(opp.ApprovalStatus__c == 'Pending Initial Approval' || opp.ApprovalStatus__c == 'Pending Risk Approval' || opp.ApprovalStatus__c == 'Pending Final Approval' || opp.ApprovalStatus__c == 'Pending Licence Approval'){
		                 isTrueOpp = TRUE;
                          System.debug('Approval status');
		              }
	               }
	              else if(opp.RecordTypeId == OppStrRId){
                      System.debug('opp.ApprovalStatus__c: '+opp.ApprovalStatus__c);
	                 if(opp.ApprovalStatus__c == 'Pending Licence Approval'){
		                 isTrueOpp = TRUE;
                         System.debug('App status');

		             }
	              }
               }
   
               for(Contract__c cont : spc.Leases__r){
                   System.debug('cont.LeaseStatus__c: '+cont.LeaseStatus__c);
                  if(cont.LeaseStatus__c != 'E'){
	                     isTrueCon = TRUE;
                         System.debug('Contracts');

	                }
               }
             
             if(isRequiredUser == TRUE){
                Trigger.newMap.get(spc.Id).addError('Can not update Rentable or Usable Area.');
             }
            else{
               if(isTrueSpcType == TRUE || (isTrueSpcType != TRUE && (isTrueOpp  == TRUE || isTrueCon == TRUE))){
                   Trigger.newMap.get(spc.Id).addError('Can not update Rentable or Usable Area');
                 }
             }
             
            
         }//end of rentable/usable area check
         
      }       //end of for loop
     
   }          // end of function validateForRentableUsableArea
//changes for ticket 10446_29May2019
}