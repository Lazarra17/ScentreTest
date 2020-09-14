/**
 *  @author:        Kyle Tan
 *  @description:   Contains business logic from PropertyMapsTriggerHandler
 **/
public without sharing class PropertyMapsBL {
    
    /**
     * @author:			Kyle tan
     * @desc:			update the FloorPlanURL__c field of the spaces of the property
     **/
    public static List<Space__c> updateSpaceFloorPlanURL(Map<Id, List<Space__c>> propertySpaceMap, PropertyMaps__c propMapRecord) {
        List<Space__c> spaceList = new List<Space__c>();
        String tempURL = null;
        if(propertySpaceMap.containsKey(propMapRecord.Property__c)) {
            for(Space__c spaceRec :propertySpaceMap.get(propMapRecord.Property__c)) {
                if(spaceRec.MainFloor__c != null && propMapRecord.Floor__c != null 
                   && spaceRec.MainFloor__c.equalsIgnoreCase(propMapRecord.Floor__c)) {
                       if(String.isNotEmpty(propMapRecord.URL__c) && propMapRecord.URL__c.contains(Constants.SVG)) {
                           system.debug('hey-->' + spaceRec.MainFloor__c + '-' + propMapRecord.Floor__c);
                           tempURL = propMapRecord.URL__c.replace(Constants.SVG, Constants.PNG);
                           spaceRec.FloorPlanURL__c = tempURL;
                           spaceList.add(spaceRec);
                       }
                   }
            }
        }
        return spaceList;
    }

}