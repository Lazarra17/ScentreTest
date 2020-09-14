/**
** Comments: This utility class contains reusable methods to get objects recordTypes
** Date Provided: 13-04-2018
** Owner: Accenture PLC
** Confidential. This document incorporates information that is proprietary to Accenture. 
** The Accenture information in this document is supplied in confidence and, except for any purposes agreed by the parties, 
** should not be disclosed, duplicated or otherwise revealed in whole or in part without the prior written consent of Accenture
**/
public with sharing class RecordTypeUtil {
    
    public with sharing class UnsupportedRecordTypeException extends Exception {}
    
    private static Map<String, Map<Id, Schema.RecordTypeInfo>> objectNameRecordTypeByIdMap = new Map<String, Map<Id, Schema.RecordTypeInfo>>();
    private static Map<String, Map<String, Schema.RecordTypeInfo>> objectNameRecordTypeByNameMap = new Map<String, Map<String, Schema.RecordTypeInfo>>();
    private static Map<String, Map<String, Schema.RecordTypeInfo>> objectNameRecordTypeByDeveloperNameMap = new Map<String, Map<String, Schema.RecordTypeInfo>>();
    /**
*  @description : This method describe recordType info based on objectType
*  @param  : String     Object API Name (ObjectType)
*  @return : Map        Map of recordtype name and recordTypeInfo     
**/
    public static Map<String,Schema.RecordTypeInfo> getAllRecordTypesByName(String objectType){
        Map<String, Schema.RecordTypeInfo> recordTypeByNameMap;
        Schema.DescribeSobjectResult[] results;
        
        if(objectNameRecordTypeByNameMap.containsKey(objectType)){
            recordTypeByNameMap = objectNameRecordTypeByNameMap.get(objectType);
        } else {
            try{
                results = Schema.describeSObjects(new List<String>{objectType});
                recordTypeByNameMap = results[0].getRecordTypeInfosByName();
                objectNameRecordTypeByNameMap.put(objectType, recordTypeByNameMap);
            } catch(Exception e){
                recordTypeByNameMap = null;
            }
        }
        
        return recordTypeByNameMap;
    }
    
    /**
*  @description : This method describe recordType info based on objectType 
*  @param  : String     Object API Name (ObjectType)
*  @return : Map        Map of recordtype Id and recordTypeInfo     
**/
    public static Map<Id,Schema.RecordTypeInfo> getAllRecordTypesById(String objectType){
        Map<Id, Schema.RecordTypeInfo> recordTypeByIdMap;
        Schema.DescribeSobjectResult[] results;
        
        if(objectNameRecordTypeByIdMap.containsKey(objectType)){
            recordTypeByIdMap = objectNameRecordTypeByIdMap.get(objectType);
        } else {
            try{
                results = Schema.describeSObjects(new List<String>{objectType});
                recordTypeByIdMap = results[0].getRecordTypeInfosById();
                objectNameRecordTypeByIdMap.put(objectType, recordTypeByIdMap);
            } catch(Exception e){
                recordTypeByIdMap = null;
            }
        }
        
        return recordTypeByIdMap;
    }
        /**
*  @description : This method describe recordType info based on objectType 
*  @param  : String     Object API Name (ObjectType)
*  @return : Map        Map of recordtype String and recordTypeInfo     
**/
    public static Map<String,Schema.RecordTypeInfo> getAllRecordTypesByDeveloperName(String objectType){
        Map<String, Schema.RecordTypeInfo> recordTypeBydeveloperNameMap;
        Schema.DescribeSobjectResult[] results;
        
        if(objectNameRecordTypeByDeveloperNameMap.containsKey(objectType)){
            recordTypeBydeveloperNameMap = objectNameRecordTypeByDeveloperNameMap.get(objectType);
        } else {
            try{
                results = Schema.describeSObjects(new List<String>{objectType});
                recordTypeBydeveloperNameMap = results[0].getRecordTypeInfosByDeveloperName();
                objectNameRecordTypeByDeveloperNameMap.put(objectType, recordTypeBydeveloperNameMap);
            } catch(Exception e){
                recordTypeBydeveloperNameMap = null;
            }
        }
        return recordTypeBydeveloperNameMap;
    }
}