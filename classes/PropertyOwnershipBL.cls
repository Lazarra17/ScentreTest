public class PropertyOwnershipBL {
    
    /*
     *  @author:        Kyle Tan
     *  @parameters:    propertyIdSet       - contains the property of the property ownership records
     *  @description:   This method populates the Tech_ConcatenatedHoldingCompanyName__c and Tech_ConcatenatedAccountACN__c
     *                  of the property.It would contain the concatenated HoldingCompanyName__c and Accounts ACN of all of its 
     *                  property ownership that has the type as 'Bank Guarantee Entity'.
     */
    public static Map<Id, Property__c> buildPropertyToUpdateMap(Set<Id> propertyIdSet){
        System.debug('propertyIdSet' + propertyIdSet.size());
        Map<Id, List<PropertyOwnership__c>> propertyChildMap = new Map<Id, List<PropertyOwnership__c>>();
        Map<Id, Property__c> propertyToUpdateMap = new Map<Id, Property__c>();
        Integer propertyOwnershipSize = 0;
        Integer counter = 0;
        String conHoldingCompanyName='';
        String conAccountACN;
        
        propertyToUpdateMap = new Map<Id, Property__c>(DatabaseSOQLBank.getProperty(propertyIdSet));
        
        for(PropertyOwnership__c propertyOwnershipRec : DatabaseSOQLBank.getPropertyOwnership(propertyIdSet)) {
            if(propertyChildMap.containsKey(propertyOwnershipRec.Property__c)) {
                propertyChildMap.get(propertyOwnershipRec.Property__c).add(propertyOwnershipRec);
            } else {
                propertyChildMap.put(propertyOwnershipRec.Property__c, new List<PropertyOwnership__c>{propertyOwnershipRec});
            }
        }
        
        for(Id propertyChildMapId : propertyChildMap.keySet()) {
            propertyOwnershipSize = propertyChildMap.get(propertyChildMapId).size();
            for(PropertyOwnership__c propertyOwnershipRec : propertyChildMap.get(propertyChildMapId)) {
                counter++;
                if(String.isNotBlank(propertyOwnershipRec.HoldingCompanyName__c)) {
                    if(String.isEmpty(conHoldingCompanyName)) {
                        conHoldingCompanyName = propertyOwnershipRec.HoldingCompanyName__c;
                    } else if(counter == propertyOwnershipSize) {
                        conHoldingCompanyName = conHoldingCompanyName + Constants.BLANK_SPACE + Constants.CONCATENATE_AND +  propertyOwnershipRec.HoldingCompanyName__c;
                    } else {
                        conHoldingCompanyName = conHoldingCompanyName + Constants.COMMA + propertyOwnershipRec.HoldingCompanyName__c;
                    }
                }
                if(String.isNotBlank(propertyOwnershipRec.Account__r.ACN__c)) {
                    if(propertyOwnershipRec.Type__c == CONSTANTS.BANK_GUARANTEE_ENTITY){
                        if(String.isEmpty(conAccountACN)) {
                            conAccountACN = propertyOwnershipRec.Account__r.Name + Constants.DASH + propertyOwnershipRec.Account__r.ACN__c;
                        } else if(counter == propertyOwnershipSize) {
                            conAccountACN = conAccountACN + Constants.BLANK_SPACE + Constants.CONCATENATE_AND + propertyOwnershipRec.Account__r.Name + Constants.DASH + propertyOwnershipRec.Account__r.ACN__c;
                        } else {
                            conAccountACN = conAccountACN + Constants.COMMA + propertyOwnershipRec.Account__r.Name + Constants.DASH + propertyOwnershipRec.Account__r.ACN__c;
                        }
                    }
                }
            }
            propertyToUpdateMap.get(propertyChildMapId).Tech_ConcatenatedHoldingCompanyName__c = conHoldingCompanyName;
			propertyToUpdateMap.get(propertyChildMapId).HoldingCompaniesName__c = conHoldingCompanyName;
            propertyToUpdateMap.get(propertyChildMapId).Tech_ConcatenatedAccountACN__c = conAccountACN;
            conHoldingCompanyName = '';
        }
        
        return propertyToUpdateMap;
    }
}