public without sharing class Utils {
    /**
     * @Author: Chen Chen 
     * @Parameter: 
	 */
    public static String getCreatableFieldsSOQL(String objectName, String whereClause, List<Id> ids, String fieldSetName) {
        SObjectType r = ((SObject)(Type.forName('Schema.' + objectName).newInstance())).getSObjectType();
        // Get field set values
        Schema.FieldSet fieldSetObj = r.getDescribe().FieldSets.getMap().get(fieldSetName);
        Map<String, Schema.SObjectField> fMap = r.getDescribe().Fields.getMap();
        List<Schema.FieldSetMember> fieldSetsF = new List<Schema.FieldSetMember>();
        List<String> porbidenFields = new List<String>();
        if (fieldSetObj != null) {
            fieldSetsF = fieldSetObj.getFields();
            if (fieldSetsF.size() > 0) {
                for (Schema.FieldSetMember m : fieldSetsF) {
                	porbidenFields.add(m.getFieldPath());   
                }
            }
        }
        list<string> selectFields = new list<string>();
        String selects = '';
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                System.debug('fd.getName()' + fd.getName());
                if (fd.isCreateable() && !porbidenFields.contains(fd.getName())){ // field is creatable
                    selectFields.add(fd.getName());
                    System.debug('put into list' + fd.getName());
                }
            }
        }
        
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            System.debug('selects ' + selects);
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
            System.debug('selects after' + selects);
        }
        System.debug('SELECTchen ' + selects);
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
    }
}