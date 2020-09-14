/*
 * @author:         Clark Garde
 * @description:    contains business logic of PropertyTriggerHandler class
*/
public class PropertyBL {
    
    /*
    * @author:         Clark Garde
    * @description:    queries account of properties inserted
    */
    public static Map<Id, List<Account>> getAccount(List<Property__c> propertyList, Set<Id> propertyIds){
        // Start -- RPP-2127 Clark Garde 4/20/18
        Map<Id, List<Account>> propertyAccountListMapTemp = new Map<Id, List<Account>>();
        if(Trigger.isInsert || Trigger.isUpdate){
            List<Account> accountList = new List<Account>();
            accountList = (DatabaseSOQLBank.getAccount(propertyIds)); 
            for(Account accVar: accountList){
                if(propertyAccountListMapTemp.containsKey(accVar.Property__c)) {
                    List<Account> accountTemp = propertyAccountListMapTemp.get(accVar.Property__c);
                    accountTemp.add(accVar);
                    propertyAccountListMapTemp.put(accVar.Property__c, accountTemp);
                } else {
                    propertyAccountListMapTemp.put(accVar.Property__c, new List<Account> { accVar });
                }
            }
         
        }
        return propertyAccountListMapTemp;
        // End -- RPP-2127
    }
    
    /*
    * @author:         Clark Garde
    * @description:    renames account if property short name is changed
    */
    public static List<Account> renameAccount(Property__c oldProperty, Property__c newProperty,List<Account> accountToUpdateListTemp, Map<Id, List<Account>> propertyAccountListMapTemp){
        // Start -- RPP-2127 Clark Garde 4/20/18
        if(oldProperty.PropertyShortName__c != newProperty.PropertyShortName__c){
            for(Account accVar : propertyAccountListMapTemp.get(newProperty.Id)){
                   accountToUpdateListTemp.add( AccountBL.renameAccount(accVar,newProperty.PropertyShortName__c));
            }
        }
        return accountToUpdateListTemp;
         // End -- RPP-2127
    }
    
}