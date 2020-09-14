/**
 * @author:					Kyle Tan
 * @desc:					creates usage clause to the parent account created from lead convertion
 **/
public class CreateUsageClauseInvocable {

    @InvocableMethod
    public static void createUsageClause(List<Account> parentAccountList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityTriggerHandler.class.getName());
        if(parentAccountList != null && parentAccountList.size() > 0) {
            Set<String> convertedLeadSet = new Set<String>();
            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            for(Account accountRecord :parentAccountList) {
                convertedLeadSet.add(accountRecord.TechConvertedLeadId__c);
            }
            if(convertedLeadSet != null && convertedLeadSet.size() > 0) {
                try {
                    leadMap = new Map<Id, Lead>([SELECT Id, Usage__c FROM Lead]);
                } catch(Exception e) {
                    leadMap = null;
                }
                if(leadMap != null && leadMap.size() > 0) {
                    List<PrecedentClause__c> precClauseList = new List<PrecedentClause__c>();
                    PrecedentClause__c precClauseRec = new PrecedentClause__c();
                    Map<String, Schema.RecordTypeInfo> precedentClauseRecordTypeMapByName  = RecordTypeUtil.getAllRecordTypesByName(Constants.PRECEDENT_CLAUSE_API);
                    for(Account accountRecord :parentAccountList) {
                        if(leadMap.containsKey(accountRecord.TechConvertedLeadId__c) &&
                           String.isNotBlank(leadMap.get(accountRecord.TechConvertedLeadId__c).Usage__c)) {
                            precClauseRec.Name = Constants.PERMITTED_USE;
                            precClauseRec.Account__c = accountRecord.Id;
                            precClauseRec.Type__c = Constants.USAGE;
                            precClauseRec.Status__c = Constants.ACTIVE;
                            precClauseRec.Description__c = leadMap.get(accountRecord.TechConvertedLeadId__c).Usage__c;
                            precClauseRec.RecordTypeId = precedentClauseRecordTypeMapByName.get(Constants.NATIONAL_PRECEDENT_CLAUSES).getRecordTypeId();
                            precClauseList.add(precClauseRec);
                        }
                    }
                    if(precClauseList != null && precClauseList.size() > 0) {
                        try {
                            database.insert(precClauseList);
                        } catch (Exception e) {
                            errorHandler.createError(e);
                        }
                        errorHandler.save();                        
                    }
                }
            }
        }
    }
}