/**
 * @author:					Kyle Tan
 * @desc:					class called in account flow to update child account of newly converted lead
 **/
public class UpdateChildAccountInvocable {

    @InvocableMethod
    public static void updateChildAccount(List<Account> parentAccountList) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityTriggerHandler.class.getName());
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMapByName = RecordTypeUtil.getAllRecordTypesByName(Constants.ACCOUNT);
        List<Account> childAccountList = new List<Account>();
        Map<Id, Lead> convertedLeadMap = new Map<Id, Lead>();
        Map<Id, Account> accountMapByLeadKey = new Map<Id, Account>();
        Set<String> convertedLeadSet = new Set<String>();
        if(parentAccountList != null && parentAccountList.size() > 0) {
            for(Account accountRecord :parentAccountList) {
                convertedLeadSet.add(accountRecord.TechConvertedLeadId__c);
            }
            if(convertedLeadSet != null && convertedLeadSet.size() > 0) {
                try {
                    childAccountList = new List<Account>([SELECT Id, TechConvertedLeadId__c, ParentId, LesseeName__c  FROM Account WHERE RecordTypeId = :accountRecordTypeMapByName.get(Constants.PROPERTY_BASED).getRecordTypeId() AND TechConvertedLeadId__c IN :convertedLeadSet]);
                } catch(Exception e) {
                    childAccountList= null;
                }
                try {
                    convertedLeadMap = new Map<Id, Lead>([SELECT Id, Company FROM Lead WHERE Id IN :convertedLeadSet]);
                } catch(Exception e) {
                    convertedLeadMap = null;
                }
            }
            if(childAccountList != null && childAccountList.size() > 0 && convertedLeadMap != null && convertedLeadMap.size() > 0) {
                for(Account accountRecord :childAccountList) {
                    accountMapByLeadKey.put(accountRecord.TechConvertedLeadId__c, accountRecord);
                }
                childAccountList.clear();
                for(Account accountRecord :parentAccountList) {
                    if(accountMapByLeadKey.containsKey(accountRecord.TechConvertedLeadId__c)) {
                        accountMapByLeadKey.get(accountRecord.TechConvertedLeadId__c).ParentId = accountRecord.Id;
                        if(convertedLeadMap.containsKey(accountRecord.TechConvertedLeadId__c)) {
                            //accountMapByLeadKey.get(accountRecord.TechConvertedLeadId__c).LesseeName__c = convertedLeadMap.get(accountRecord.TechConvertedLeadId__c).Company;
                        }
                        childAccountList.add(accountMapByLeadKey.get(accountRecord.TechConvertedLeadId__c));
                    }
                }
            }
            if(childAccountList != null && childAccountList.size() > 0) {
                try {
                    database.update(childAccountList);
                } catch(Exception e) {
                    errorHandler.createError(e);
                }
            }
            errorHandler.save();
        }
    }
}