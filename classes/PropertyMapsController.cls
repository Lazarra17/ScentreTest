public class PropertyMapsController {
	
    public class PropertyMapsBLWrapper {
        public String imageUrl;
        public List<Space__c> spaces;
        List<PropertyMaps__c> propertyMaps;
        public String level;
    }
    /**
     * @Author: Chen Chen
     * @Parameter: propertyId, current property Id
     * @Description: Get all the property maps belonging to this property
	 */
    @TestVisible 
    private static List<PropertyMaps__c> getPropertyMapsByProperty(Id propertyId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyMapsController.class.getName());
        List<PropertyMaps__c> propertyMaps = new List<PropertyMaps__c>();
        try{
            propertyMaps = [Select Id, Name, Floor__c, URL__c, URI__c From PropertyMaps__c Where Property__c =: propertyId ORDER BY Floor__c ASC];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        
        errorHandler.save();
        return propertyMaps;
    }
    
    /**
     * @Author: Chen Chen
     * @Parameter: level current request level of the property, propertyId current property Id
     * @Description: Get image url by level and property Id
	 */
    public static String getImageByPropertyAndLevel(String level, Id propertyId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyMapsController.class.getName());
        String imageUrl = '';
        System.debug('level ' + level + ' propertyId ' + propertyId);
        List<PropertyMaps__c> propertyMaps = new List<PropertyMaps__c>();
        try{
            propertyMaps = [Select Id, Floor__c, URL__c, URI__c From PropertyMaps__c Where Property__c =: propertyId And Floor__c =: level];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        if (propertyMaps.size() > 0 && propertyMaps.size() == 1) {
            System.debug('imageUrl ' + imageUrl);
            imageUrl = propertyMaps.get(0).URL__c;
        }
        errorHandler.save();
        return imageUrl;
    }
    
    /**
     * @Author: Chen Chen
     * @Parameter: level current request level of the property, spaceId current space Id
     * @Description: Get image url by level and space Id
	 */
    @TestVisible 
    private static String getImageSpaceIdAndLevel(String level, Id spaceId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyMapsController.class.getName());
        String imageUrl = '';
        List<Space__c> space = new List<Space__c>();
        try{
            space = [Select Id, Property__c From Space__c Where Id =: spaceId];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        if (space.size() == 1) {
            imageUrl = getImageByPropertyAndLevel(level, space.get(0).Property__c);
        }
        errorHandler.save();
        return imageUrl;
    }
    
    /**
     * @Author: Chen Chen
     * @Parameter: level current request level of the property, spaceId current property Id
     * @Description: Get PropertyMapsBLWrapper by level and property Id
	 */
    
    @AuraEnabled
    public static String getSpacesAndImageByProperty(String level, Id propertyId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyMapsController.class.getName());
        String imageUrl;
        List<PropertyMaps__c> getFloor = [Select id, Floor__c From PropertyMaps__c where Property__c  = :propertyId limit 1];
        if (getFloor.size() > 0 && level == 'initial') {
            level = getFloor.get(0).Floor__c; 
        }
        List<PropertyMaps__c> propertyMaps = new List<PropertyMaps__c>();
        List<Space__c> spaces = new List<Space__c>();
        try {
            imageUrl = getImageByPropertyAndLevel(level, propertyId);
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        try{
            propertyMaps = getPropertyMapsByProperty(propertyId);
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        try {
            spaces = [Select Id, Name, UnitNo__c, CurrentRetailer__c, CurrentRetailer__r.Name, CurrentRent__c, CurrentLeaseRiskApplied__c, RentableArea__c, UsableArea__c, Property__r.JDEPropertyNumber__c From Space__c Where MainFloor__c =: level And Property__c = :propertyId];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        PropertyMapsBLWrapper pmWrapper = new PropertyMapsBLWrapper();
        pmWrapper.imageUrl = imageUrl;
        pmWrapper.spaces = spaces;
        pmWrapper.propertyMaps = propertyMaps;
        pmWrapper.level = level;
        System.debug('pmWrapper ' + pmWrapper);
        errorHandler.save();
        return JSON.serialize(pmWrapper);
    }
    
    @AuraEnabled
    public static String getPropertyMapBySpace(Id spaceId) {
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(PropertyMapsController.class.getName());
        String imageUrl = '';
        List<Space__c> spaces = new List<Space__c>();
        List<PropertyMaps__c> maps = new List<PropertyMaps__c>();
        try{
            spaces = [Select Id, Property__c, MainFloor__c From Space__c Where Id =: spaceId];
        } catch(Exception e) {
            errorHandler.createError(e);
        }
        if (spaces.size() == 1) {
            String propertyId = spaces.get(0).Property__c;
            String level = spaces.get(0).MainFloor__c;
            try{
                maps = [Select Id, URI__c, URL__c From PropertyMaps__c Where Floor__c =: level and Property__c =: propertyId];
            } catch(Exception e) {
                errorHandler.createError(e);
            }
            if (maps.size() == 1) {
                imageUrl = maps.get(0).URL__c;
            }
        }
        errorHandler.save();
        return imageUrl;
    }
}