/**
*  @description : BL class to for all schema describe calls
*  @author      : pkumarlg 
*  @since       : 
*  @release     : 
**/
public class SchemaDescribeBL {
    
    // variable decleration
    public static Map<String,Set<String>> fieldSetandfieldAPIname;
    public static Map<String,Schema.SObjectType> globalDescribeMap;
    
    public void SchemaDescribeBL(){
        
    }
    /************************************************************************************
* Method to include fields for custom field history tracking
* Create field set to using same name for all the object
* ex: HistoryTracking, use parmeter if you are using different nameing convention. 
*************************************************************************************/
    
    public static Map<String,Set<String>> describefieldnamefromFS(String objectapiname, String fieldsetapiname) {
        Map <String,Schema.FieldSet> fieldSetMap;
        if (globalDescribeMap == null) {
            globalDescribeMap = Schema.getGlobalDescribe();
        }
        if (fieldSetMap == null) {
            fieldSetMap = new Map <String,Schema.FieldSet>();
        }
        if (fieldSetandfieldAPIname == null) {
            fieldSetandfieldAPIname = new Map <String,Set<String>>();
        }
        
        Set<String> fieldAPInameSet = new Set<String>();
        // check if sobject have any field set.
        if (fieldSetandfieldAPIname.get(fieldsetapiname) == null) {
            // Make describe call only if there are no values in the map.
            if (String.isNotBlank(fieldsetapiname)){
                if (!fieldSetMap.containsKey(fieldsetapiname)) {
                    fieldSetMap = globalDescribeMap.get(objectapiname).getDescribe().fieldSets.getMap();
                }
            } else {
                fieldSetMap = globalDescribeMap.get(objectapiname).getDescribe().fieldSets.getMap();
            }
            
            if (fieldSetMap.containsKey(fieldsetapiname)){
                if (fieldSetMap.get(fieldsetapiname) != null) {
                    for (Schema.FieldSetMember fieldattribute: fieldSetMap.get(fieldsetapiname).getFields()) {
                        fieldAPInameSet.add(fieldattribute.getFieldPath());
                    }
                    fieldSetandfieldAPIname.put(fieldsetapiname, fieldAPInameSet);
                }
            }
        }
        // final set of fields for history tracking.
        System.debug('objectapiname ' + objectapiname);
        System.debug('fieldSetandfieldAPIname in Schema ' + fieldSetandfieldAPIname);
        return fieldSetandfieldAPIname;
    }
}