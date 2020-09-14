public class PlatformEventUtils {
    
    public class PlatformEventUtilsWrapper {
        public List<String> jsonPayloads {get; set;}
        public List<SObject> records {get; set;}
    }
    
    public static Map<String, DescribeSObjectResult> descriptionResultMap= new Map<String, DescribeSObjectResult>();
    public static Map<String,Set<String>> objectandfieldapinameforpublish;
    /**
* @Author : Chen Chen
* @Paramater : objectId, the record Id that needs to send event
*              
* @Purpose : Using object id to get describe result
*/
    private static DescribeSObjectResult getDescribeResult(Id objectId) {
        DescribeSObjectResult describeResult;
        if (objectId != null) {
            SObjectType objectType = objectId.getSObjectType();
            String objectString = String.valueOf(objectType);
            // Register Description Result in static map in transaction
            if (descriptionResultMap.get(objectString) != null) {
                describeResult = descriptionResultMap.get(objectString);
            } else {
                SObjectType objToken = Schema.getGlobalDescribe().get(objectString);
                describeResult = objToken.getDescribe();
                descriptionResultMap.put(objectString, describeResult);
            }
        }
        return describeResult;
    }
    
    
    /**
* @Author : Chen Chen
* @Paramater : describeResult : if apiNames is empty, get all the fields from the object
*              apiNames, List of attributes we need to achieve from the record to put into the payload
* @Purpose : Get SOQL selection portion
*/
    private static List<String> getSOQLSelectionToString(List<String> apiNames, DescribeSObjectResult describeResult) {
        List<String> fieldNames = new List<String>();
        if (apiNames.size() > 0) {
            fieldNames = apiNames;
        } else {
            if (describeResult != null) {
                fieldNames = new List<String>( describeResult.fields.getMap().keySet() );   
            }
        }
        //System.debug('PlatformEventUtils fieldNames ' + fieldNames);
        return fieldNames;
    }
    
    
    /**
* @Author : Chen Chen
* @Paramater : objectId, the record Id that needs to send event
*              apiNames, List of attributes we need to achieve from the record to put into the payload
* @Purpose : Generate json payload from any give record with or without user selected attributes.
*            If apiNames contains any value, those will be contained in the json payload, otherwise, we
*            will send the full json payload 
*/
    public static String getRecordJsonPayload(Id objectId, List<String> apiNames) {
        DescribeSObjectResult describeResult = getDescribeResult(objectId);
        // Determine if it is partial payload or full payload
        List<String> fieldNames = getSOQLSelectionToString(apiNames, describeResult);
        //System.debug('getRecordJsonPayload fieldNames ' + fieldNames);
        String soqlQuery = ' SELECT ' + String.escapeSingleQuotes(String.join(fieldNames, ',')) + ' FROM ' + describeResult.getName() + ' Where Id =: objectId' + ' LIMIT 1 ';
        SObject record;
        try {
            record = Database.query(soqlQuery);
        }
        catch (Exception ex) {
            record = null;
        }
        //System.debug('record ' + record);
        String jsonPayload = '';
        if (record != null) {
            Map<String, String> result = new Map<String, String>();
            for (String apiName : apiNames) {
                String value = getFieldValue(record, apiName);
                result.put(apiName, value);
                //System.debug('recordDetails ' + apiName + ' ' +  value);
            }
            try {
            	jsonPayload = JSON.serialize(result);    
            } catch (Exception e) {
                jsonPayload = NULL;
            }
            
        }
        //System.debug('jsonPayload ' + jsonPayload);
        return jsonPayload;
    }
    
    /**
    * @Author : Chen Chen
    * @Paramater : objectIds, a list of same record type records that needs to send event
    *              apiNames, List of attributes we need to achieve from the record to put into the payload
    * @Purpose : Generate a list of json payloads from records with or without user selected attributes.
    *            If apiNames contains any value, those will be contained in the json payload, otherwise, we
    *            will send the full json payload 
    */
    public static List<String> getRecordsJsonPayload(List<Id> objectIds, List<String> apiNames) {
        List<String> jsonPayloads = new List<String>();
        //System.debug('In getRecordsJsonPayload objectIds ' + objectIds);
        if (objectIds.size() > 0) {
            DescribeSObjectResult describeResult = getDescribeResult(objectIds.get(0));
            // Determine if it is partial payload or full payload
            List<String> fieldNames = getSOQLSelectionToString(apiNames, describeResult);
            //System.debug('getRecordsJsonPayload fieldNames ' + fieldNames);
            String soqlQuery = ' SELECT ' + String.escapeSingleQuotes(String.join(fieldNames, ',')) + ' FROM ' + describeResult.getName() + ' Where Id in: objectIds' + ' LIMIT 10000 ';
            List<SObject> records;
            try {
                records = Database.query(soqlQuery);
                //System.debug('getRecordsJsonPayload records ' + records);
            }
            catch (Exception ex) {
                records = new List<SObject>();
                //System.debug('Exception in PlatformEventUtils.getRecordsJsonPayload: '+ex.getMessage());
            }
            if (records.size() > 0) {
                for (SObject record : records) {
                    //System.debug('getRecordsJsonPayload in record loop ' + record);
                    //System.debug('getRecordsJsonPayload apiNames ' + apiNames.size() + ' ' + apiNames);
                    Map<String, String> result = new Map<String, String>();
                    for (String apiName : fieldNames) {
                        //System.debug('getRecordsJsonPayload apiName ' + apiName);
                        apiName=apiName.toUpperCase();
                        String value = getFieldValue(record, apiName);
                        result.put(apiName, value);
                        //System.debug('getRecordsJsonPayload ' + 'apiName ' + apiName + ' value ' + value);
                    }
                    String jsonPayload;
                    try {
                        jsonPayload = JSON.serialize(result);    
                    } catch (Exception e) {
                        jsonPayload = NULL;
                    }
                    //System.debug('getRecordsJsonPayload jsonPayload ' + jsonPayload);
                    jsonPayloads.add(jsonPayload);
                }
            }
        }
        return jsonPayloads;
    }
    
    // Special Method just for Contact, ACR JSON Payload, Must Having Id in apiNames
    public static Map<Id, String> getRecordsJsonPayloadMap(List<Id> objectIds, List<String> apiNames) {
        Map<Id, String> jsonPayloads = new Map<Id, String>();
        if (objectIds.size() > 0) {
            DescribeSObjectResult describeResult = getDescribeResult(objectIds.get(0));
            // Determine if it is partial payload or full payload
            List<String> fieldNames = getSOQLSelectionToString(apiNames, describeResult);
            String soqlQuery = ' SELECT ' + String.escapeSingleQuotes(String.join(fieldNames, ',')) + ' FROM ' + describeResult.getName() + ' Where Id in: objectIds' + ' LIMIT 10000 ';
            List<SObject> records;
            try {
                records = Database.query(soqlQuery);   
            }
            catch (Exception ex) {
                records = new List<SObject>();
                //System.debug('Exception in PlatformEventUtils.getRecordsJsonPayload: '+ex.getMessage());
            }
            if (records.size() > 0) {
                for (SObject record : records) {
                    Map<String, String> result = new Map<String, String>();
                    for (String apiName : apiNames) {
                        //System.debug('apiName ' + apiName);
                        apiName=apiName.toUpperCase();
                        String value = getFieldValue(record, apiName);
                        result.put(apiName, value);
                        //System.debug('apiName ' + apiName + ' value ' + value);
                    }
                    
                    String jsonPayload;
                    try {
                        jsonPayload = JSON.serialize(result);
                    } catch (Exception e) {
                        jsonPayload = NULL;
                    }
                    jsonPayloads.put(record.Id, jsonPayload);
                }
            }
        }
        return jsonPayloads;
    }
    
    
    public static Map<String,Set<String>> getfieldlistforintegration(String objectapiname){
        
        if(objectandfieldapinameforpublish==null){
            objectandfieldapinameforpublish=new Map<String,Set<String>>();
        }
        Set<String> fieldapiNames = new Set<String>();
        if(!objectandfieldapinameforpublish.containsKey(objectapiname)){
            List<PlatformEventPayloadSelection__mdt> payloadSelection = [SELECT ObjectApiName__c, Content__c FROM PlatformEventPayloadSelection__mdt WHERE ObjectApiName__c =: objectapiname LIMIT 1];
            if(payloadSelection!=null){
                String content = payloadSelection[0].Content__c;
                for (String apiName : content.split(',')) {
                    apiName = apiName.trim();
                    fieldapiNames.add(apiName);
                    objectandfieldapinameforpublish.put(objectapiname, fieldapiNames);
                }
            }
        }
        return objectandfieldapinameforpublish;
    }
    
    private static String getFieldValue(SObject passinObject, String passInString) {
        String result = '';
        if (passInString.contains('.')) {
            Boolean keepGoing = true;
            sObject tempSobject = passinObject; 
            List<String> fieldNames = passInString.split('\\.');
            // Check size : counting how many objects, the last one is always field
            if((fieldNames.size() - 1) > 0) {
                for (Integer i=0; i < fieldNames.size() - 1; i ++) {
                    tempSobject = tempSobject.getSobject(fieldNames[i]);
                    if (tempSobject == null) {
                        // assign value here
                        keepGoing = false;
                        break;
                    }
                }
            }
            if (keepGoing) {
                result = tempSobject.get(fieldNames[fieldNames.size() - 1]) == null ? '' : tempSobject.get(fieldNames[fieldNames.size() - 1]) + '';
            }
        } else {
            result = passinObject.get(passInString) == null ? '' : passinObject.get(passInString) + '';
        }
        // assign values to despatch details, these filed api names remain same across objects
        if(passInString.equalsIgnoreCase(Constants.TECH_DISPATCHVERSION)){
            Decimal dispatchversion=(Decimal)passinObject.get(passInString);
            if(dispatchversion!=null&&dispatchversion!=0){
                dispatchversion=dispatchversion+1;
            }else{
                dispatchversion=1;
            }
            result=String.valueOf(dispatchversion);
        }
        if(passInString.equalsIgnoreCase(Constants.TECH_DISPATCHTIMESTAMP)){
            result=String.valueOf(System.now());
            //result=System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }
        return result;
    }
    
    public static DateTime getUTCDateTime(DateTime dt){
    	Datetime GMTDate = Datetime.newInstanceGmt(
                            dt.year(),
                            dt.month(),
                            dt.day(),
                            dt.hour(),
                            dt.minute(),
                            dt.second());
    return GMTDate;
	}
    
    public static List<String> constructApiNames(String content) {
        List<String> splitString = content.split(',');
        List<String> apiNames = new List<String>();
        for (String apiName : splitString) {
            apiName = apiName.trim();
            apiNames.add(apiName);
        }
        return apiNames;
    }
}