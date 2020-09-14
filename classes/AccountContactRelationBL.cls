/*------------------------------------------------------------------------------------
Author:      Aakash Soor
Company:     Arxxus Technology Partners
Description: This class will have all the business logic for AccountContactRelation sobject
Test Class:  ACRTriggerHandler
History
Date            Author             Comments
--------------------------------------------------------------------------------------
27-11-2019      Aakash Soor        Initial Release
--------------------------------------------------------------------------------------*/
public without sharing class AccountContactRelationBL {
    
    private static Set<String> applicableRoles = new Set<String>(Label.Applicable_RDI_Contact_Roles.split(','));

    public static Map<Id,Account> updateRDIApplicableContactCount(Map<Id,AccountContactRelation> oldACTMap, Map<Id,AccountContactRelation> newACTMap){
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        if(applicableRoles.size() > 0){
            for(AccountContactRelation newAct : newACTMap.values()){
                Set<String> roleSet = new Set<String>();
                
                if(newAct.Roles != null) roleSet = new Set<String>(newAct.Roles.split(';'));

                if(oldACTMap == null){
                    if(newAct.Roles != null
                        && checkIntersectionOfSets(roleSet,applicableRoles))
                        accountIdSet.add(newAct.AccountId);
                }else{
                    Set<String> oldRoleSet = oldACTMap.get(newAct.Id).Roles != null 
                                            ? new Set<String>(oldACTMap.get(newAct.Id).Roles.split(';'))
                                            : new Set<String>();
                    if(oldACTMap.get(newAct.Id).Roles != newAct.Roles
                        && (checkIntersectionOfSets(roleSet,applicableRoles)
                            || checkIntersectionOfSets(oldRoleSet,applicableRoles))){
                        accountIdSet.add(newAct.AccountId);
                    }
                }
            }
        }
        system.debug('accountIdSet------'+accountIdSet);
        if(accountIdSet.isEmpty()) return accountMap;

        String query = 'SELECT Id, No_of_RDI_Applicable_Contact_Relation__c,'
                            +'(SELECT Id '
                            +'FROM AccountContactRelations '
                            +'WHERE isActive = true '
                            +'AND Roles INCLUDES (';
        for(String val : Label.Applicable_RDI_Contact_Roles.split(',')){
            val = val.trim();
            query = query + '\''+val+'\',';
        }
        query = query.removeEnd(',') + ')) FROM Account '
                                        +'WHERE Id IN: accountIdSet';
                
        for(Account acc : Database.query(query)){
            acc.No_of_RDI_Applicable_Contact_Relation__c = acc.AccountContactRelations.size();
            accountMap.put(acc.Id, acc);
        }

        return accountMap;
    }

    private static Boolean checkIntersectionOfSets(Set<String> compareWithSet, Set<String> compareToSet){
        Set<String> mergedSet = new Set<String>(compareWithSet);
        mergedSet.retainAll(compareToSet);
        if(mergedSet.size() > 0) return true;
        return false;
    }
}