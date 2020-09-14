/**
* Class RelatedOpportunityTriggerHandler
*
* Trigger Handler for the Related Opportunity SObject. This class implements the ITrigger
* interface to help ensure the trigger code is bulkified and all in one place.
*/
public class RelatedOpportunityTriggerHandler extends TriggerHandler implements ITrigger{
    
    public List<Opportunity> updateOppos = new List<Opportunity>();
    public List<RelatedOpportunity__c> newRos = new List<RelatedOpportunity__c>();
	/**
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    public void bulkBefore(){
        if(Trigger.isInsert || Trigger.isUpdate) {
            List<RelatedOpportunity__c> ros = (List<RelatedOpportunity__c>) Trigger.new;
            List<Id> oppoIds = new List<Id>();
            for (RelatedOpportunity__c ro : ros) {
                oppoIds.add(ro.PrimaryOpportunity__c);
                oppoIds.add(ro.AssociatedOpportunity__c);
            }
            //Get all the spaces
            List<Opportunity> oppos = [Select Id, Space__c, TechSpaceIdSummary__c From Opportunity Where Id in: oppoIds];
            //Construct spaceToOppo Map and space ids
            List<Id> spaceIds = new List<Id>();
            for (Opportunity oppo : oppos) {
                spaceIds.add(oppo.Space__c);
            }
            // Check space recordtype
            Map<Id, String> spaceIdToTechValue = new Map<Id, String>();
            List<Space__c> spaces = [Select Id, RecordType.Name, RecordTypeId From Space__c where Id in: spaceIds];
            List<Id> proposedSpace = new List<Id>();
            for (Space__c space : spaces) {
                if (space.RecordTypeId != null && space.RecordType.Name == Constants.PROSPECTIVE_SPACE ) {
                    proposedSpace.add(space.Id);
                } else {
                    spaceIdToTechValue.put(space.Id, '\'' + space.Id + '\'');
                }
            }
            //Now deal with nonProposeSpace, construct tech fields
            List<SpaceGroup__c> spgs = [select id, ParentSpace__c, ChildSpace__c From SpaceGroup__c where ChildSpace__c in :proposedSpace];
            System.debug('spgs ' + spgs);
            for (SpaceGroup__c spg : spgs) {
                if (spaceIdToTechValue.get(spg.ChildSpace__c) != null) {
                    String value = spaceIdToTechValue.get(spg.ChildSpace__c);
                    value = value + '|' + '\'' + spg.ParentSpace__c + '\'';
                    spaceIdToTechValue.put(spg.ChildSpace__c, value);
                } else {
                    spaceIdToTechValue.put(spg.ChildSpace__c, '\'' + spg.ParentSpace__c + '\'');        
                }
            }
            //opportunity update list
			updateOppos = new List<Opportunity>();
            if (spaceIdToTechValue.size() > 0) {
                for (Opportunity oppo : oppos) {
                    if (spaceIdToTechValue.get(oppo.Space__c) != null) {
                        oppo.TechSpaceIdSummary__c = spaceIdToTechValue.get(oppo.Space__c);
                        updateOppos.add(oppo);
                    }
                }   
            }
        }
    }

    /**
    * This method is called prior to execution of a AFTER trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    public void bulkAfter(){
        if(Trigger.isInsert || Trigger.isUpdate) {
            List<RelatedOpportunity__c> ros = (List<RelatedOpportunity__c>) Trigger.new;
            Set<String> puzzles = new Set<String>();
            Set<Id> queryIds = new Set<Id>();
            for (RelatedOpportunity__c rOppo : ros) {
                queryIds.add(rOppo.AssociatedOpportunity__c);
                queryIds.add(rOppo.PrimaryOpportunity__c);
            }
            List<RelatedOpportunity__c> partialRos = [Select Id, AssociatedOpportunity__c, PrimaryOpportunity__c From RelatedOpportunity__c Where AssociatedOpportunity__c in:queryIds or PrimaryOpportunity__c in:queryIds];
        	//Build puzzle now
        	for (RelatedOpportunity__c rOppo : partialRos) {
                puzzles.add(rOppo.AssociatedOpportunity__c);
                puzzles.add(rOppo.PrimaryOpportunity__c);
            }
            List<RelatedOpportunity__c> wholeRos = [Select Id, AssociatedOpportunity__c, PrimaryOpportunity__c From RelatedOpportunity__c Where AssociatedOpportunity__c in:puzzles or PrimaryOpportunity__c in:puzzles];
        	List<OpportunityPair.OppoPair> pairs = OpportunityPair.produceKeyPairs(puzzles);
            List<OpportunityPair.OppoPair> pairsN = new List<OpportunityPair.OppoPair>();
            List<OpportunityPair.OppoPair> pairsToCreated = new List<OpportunityPair.OppoPair>();
            System.debug('Whole Pairs size ' + pairs.size());
            System.debug('Whole Pairs ' + pairs);
            System.debug('wholeRos size ' + wholeRos.size());
            for (Integer i=0; i<pairs.size(); i++) {
                boolean isSame = false;
                for (RelatedOpportunity__c relatedOppo : wholeRos) {
                    if (pairs.get(i).primaryOppoId == relatedOppo.PrimaryOpportunity__c &&  pairs.get(i).secondOppoId == relatedOppo.AssociatedOpportunity__c) {
                       //|| (pairs.get(i).primaryOppoId == relatedOppo.AssociatedOpportunity__c &&  pairs.get(i).secondOppoId == relatedOppo.PrimaryOpportunity__c)) {
                        System.debug(i);
                        //pairs.remove(i);
                        isSame = true;
                    }
                }
                if (!isSame) {
                    pairsN.add(pairs.get(i));
                }
            }
            Map<ID, Opportunity> m = new Map<ID, Opportunity>([SELECT Id, Space__c FROM Opportunity Where Id in:puzzles]);
            System.debug('m size ' + m.size());
            System.debug('pairsN.size() ' + pairs.size());
            System.debug('pairsN ' + pairs);
            for (OpportunityPair.OppoPair pair : pairsN) {
                RelatedOpportunity__c ro = new RelatedOpportunity__c();
                ro.PrimaryOpportunity__c = pair.primaryOppoId;
                ro.AssociatedOpportunity__c = pair.secondOppoId;
                System.debug('m.get(pair.secondOppoId) ' + m.get(pair.secondOppoId));
                if (m.get(pair.secondOppoId) != null && m.get(pair.secondOppoId).Space__c != null) {
                    ro.ExistingSpace__c = m.get(pair.secondOppoId).Space__c;
                }
                newRos.add(ro);
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
        
    }

    /**
    * This method is called iteratively for each record to be updated during a AFTER
    * trigger.
    * This or other methods to be called here must not contain DML statements or queries.
    */
    public void afterUpdate(SObject oldSo, SObject so){
        
    }

    /**
    * This method is called iteratively for each record to be updated during a AFTER
    * trigger.
    * This or other methods to be called here must not contain DML statements or queries.
    */
    public void afterDelete(SObject so){
        
    }

    public void andFinally(){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(RelatedOpportunityTriggerHandler.class.getName());
        System.debug('updateOppos ' + updateOppos);
        if(updateOppos != null && updateOppos.size() > 0){
            try{
                Database.update(updateOppos);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        if(newRos.size() > 0){
            try{
                Database.insert(newRos);
            } catch(Exception e){
                errorHandler.createError(e);
            }
        }
        errorHandler.save();
    }
}