/*************************************************
 * Generic util class for custom history tracking.
 * Use this call creat custom history records
***************************************************/
public class HistoryTrackingUtil {
    public class HistoryTrackingWrapper {
        public Map<Id, SObject> newMap {get; set;}
        public Map<Id, SObject> oldMap {get; set;} 
        public String objectAPIName {get; set;}
        public String FieldSetAPIName {get; set;}
        public String historyobjectAPIname {get; set;}
    }
    
    public static Map<String, Schema.SObjectType> globalDescribeMap=Schema.getGlobalDescribe();
    public static Map<String,Schema.DescribeFieldResult> describedFieldMap=new Map<String,Schema.DescribeFieldResult>();
/************************************************************************************
* Method to include fields for custom field history tracking
* Create field set to using same name for all the object
* ex: HistoryTracking, use parmeter if you are using different nameing convention. 
*************************************************************************************/
    public static Set<String> IncludeFieldsforTracking(String objectAPIName,String FieldSetAPIName){
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(HistoryTrackingUtil.class.getName());
        Set<String> fieldAPInameSet=new Set<String>();
        Map<String, Schema.FieldSet> fieldSetMap = new Map<String, Schema.FieldSet>();
        // ASSUMPTION: All fieldset for history tracking follow same name, hence default.
        if(String.isBlank(FieldSetAPIName)){
            FieldSetAPIName=CONSTANTS.FIELD_SET_API_NAME;
        }
        try{
            fieldSetMap=globalDescribeMap.get(objectAPIName).getDescribe().fieldSets.getMap();
            
        }catch(Exception e) {
            errorHandler.createError(e);
        }
        // check if sobject have any field set.
        if(fieldSetMap.containsKey(FieldSetAPIName)){
            if(fieldSetMap.get(FieldSetAPIName)!=null){
                for(Schema.FieldSetMember fieldattribute :fieldSetMap.get(FieldSetAPIName).getFields()){
                    fieldAPInameSet.add(fieldattribute.getFieldPath());
                }
            }
        }
        //System.debug('Field API Name set ' + fieldAPInameSet);
        errorHandler.save();
        // final set of fields for history tracking.
        return fieldAPInameSet; 
    }
/***********************************************************
* Method used to create custom historytracking records
* Mappings are maintained in custom metadata 
******************************************************/
    public static List<Sobject> historyTracking(HistoryTrackingWrapper historyTrackingWrapper){
        
        List<Sobject> historyTrackingrecordList=new List<Sobject>();
        Set<String> fieldsforhistorytracking=new Set<String>();
        Map<String,Set<Id>> objectTypeandIdsMap=new Map<String,Set<Id>>();
        
        if(historyTrackingWrapper.newMap!=null && historyTrackingWrapper.newMap.size()>0 && historyTrackingWrapper.oldMap!=null && historyTrackingWrapper.oldMap.size()>0){
            fieldsforhistorytracking=IncludeFieldsforTracking(historyTrackingWrapper.objectAPIName, historyTrackingWrapper.FieldSetAPIName);
            Map<String, Schema.SObjectField> fields = globalDescribeMap.get(historyTrackingWrapper.objectAPIName).getDescribe().fields.getMap();
            Schema.SObjectType historyObjectType = Schema.getGlobalDescribe().get(historyTrackingWrapper.historyobjectAPIname);
            for(String field : fields.keyset()){
                if(fields.containsKey(field)&& field !='iqscore'){
                    Schema.DescribeFieldResult describeresult = fields.get(field).getDescribe();
                    describedFieldMap.put(field.toLowerCase(),describeresult);
                }
            }
            
            for(SObject newRecordvalue: historyTrackingWrapper.newMap.values()){
                for(String fieldapiName: fieldsforhistorytracking){
                    fieldapiName=fieldapiName.toLowerCase();
                    System.debug('FIELD API VALUE ' + fieldapiName);
                    Schema.DescribeFieldResult describedFieldresult=describedFieldMap.get(fieldapiName);
                    if(!describedFieldresult.isCalculated()&&!describedFieldresult.isAutoNumber()){
                        String newValue = null;
                        String previousValue = null;
                        if(describedFieldresult.getType()== Schema.DisplayType.Reference){
                            previousValue=historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName) !=null?(string)historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName):null;
                            newValue=newRecordvalue.get(fieldapiName) !=null?(string)newRecordvalue.get(fieldapiName):null;
                            
                            if(previousValue!=newValue){
                                Id referencerecordId=null;
                                Set<Id> referenceRecordIdset=new Set<Id>();
                                if(newRecordvalue.get(fieldapiName)!=null){
                                    referencerecordId=(id)newRecordvalue.get(fieldapiName);
                                    referenceRecordIdset.add((id)newRecordvalue.get(fieldapiName));
                                }
                                
                                if(historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName)!=null){
                                    referencerecordId=(id)newRecordvalue.get(fieldapiName);
                                    referenceRecordIdset.add((id)newRecordvalue.get(fieldapiName));
                                }  
                                if(referenceRecordIdset!=null&&referenceRecordIdset.size()>0&&referencerecordId!=null){
                                    if(objectTypeandIdsMap.containsKey(referencerecordId.getSObjectType().getDescribe().getName())){
                                        objectTypeandIdsMap.get(referencerecordId.getSObjectType().getDescribe().getName()).addAll(referenceRecordIdset);
                                    }else{
                                        objectTypeandIdsMap.put(referencerecordId.getSObjectType().getDescribe().getName(),referenceRecordIdset);
                                    }
                                }
                            }
                        }else if(describedFieldresult.getType()==Schema.DisplayType.DateTime){
                            newValue = newRecordvalue.get(fieldapiName) != null ? String.valueOf(((DateTime)newRecordvalue.get(fieldapiName)).format()) : CONSTANTS.EMPTY;
                            previousValue = historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName) !=null ? String.valueOf(((DateTime)historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName)).format()) : CONSTANTS.EMPTY;                           
                        }else if(describedFieldresult.getType()==Schema.DisplayType.Date){
                            newValue = newRecordvalue.get(fieldapiName) != null ? String.valueOf(((Date)newRecordvalue.get(fieldapiName)).format()) : CONSTANTS.EMPTY;
                            previousValue = historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName) !=null ? String.valueOf(((Date)historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName)).format()) : CONSTANTS.EMPTY;                           
                        }else{
                            newValue = newRecordvalue.get(fieldapiName) != null ? String.valueOf(newRecordvalue.get(fieldapiName)) : CONSTANTS.EMPTY;
                            previousValue = historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName) != null ? String.valueOf(historyTrackingWrapper.oldMap.get(newRecordvalue.Id).get(fieldapiName)) : CONSTANTS.EMPTY;
                            
                        }
                        if(newValue!=previousValue){
                            Sobject historytracking=historyObjectType.newSobject();
                            if (historyTrackingWrapper.objectAPIName == Constants.SPACE && (fieldapiName == Constants.SPACE_AREA || fieldapiName == Constants.SPACE_USABLE_AREA) ) {
                                Decimal newValueD = String.isBlank(newValue) ? 0: decimal.valueOf(newValue);
                                Decimal previousValueD = String.isBlank(previousValue) ? 0: decimal.valueOf(previousValue);
                                historytracking.put(CONSTANTS.API_DATE_EFFECTIVE, Date.today());
                                historytracking.put(CONSTANTS.API_CHANGE_BY, Userinfo.getUserId());
                                historytracking.put(CONSTANTS.API_NEW_AREA, newValueD);
                                historytracking.put(CONSTANTS.API_AREA, previousValueD);
                                historytracking.put(CONSTANTS.SPACE, newRecordvalue.get(CONSTANTS.DML_ID));
                                historyTrackingrecordList.add(historytracking);
                            } else if (historyTrackingWrapper.objectAPIName == Constants.OPPORTUNITY) {
                                historytracking.put(CONSTANTS.API_CHANGE_BY, Userinfo.getUserId());
                                historytracking.put(CONSTANTS.API_DATE_EFFECTIVE, System.now());
                                historytracking.put(CONSTANTS.API_MODIFIED_FIELD_LABEL, describedFieldresult.getLabel());
                                historytracking.put(CONSTANTS.API_MODIFIED_FIELD_NAME, describedFieldresult.getName());
                                historytracking.put(CONSTANTS.API_NEW_VALUE, newValue);
                                historytracking.put(CONSTANTS.API_PREVIOUS_VALUE,previousValue);
                                historytracking.put('OpportunityApprovalStatus__c', newRecordvalue.get('ApprovalStatus__c'));
                                historytracking.put(CONSTANTS.OPPORTUNITYWITHC,newRecordvalue.get(CONSTANTS.DML_ID));
                                historyTrackingrecordList.add(historytracking);
                            }
                        }
                    }
                }
            }
        }
        
        
        // Below logic is to convert lookup field id's to Name 
        Map<Id, sObject> lookupRecordsMap = new Map<Id, sObject>();
        if(objectTypeandIdsMap.size()>0&&!objectTypeandIdsMap.isEmpty()){
            for(String objectnameforquery: objectTypeandIdsMap.keySet()){
                // no of quries equals to number of lookup field used for tracking.
                Set<Id> RecordIds=objectTypeandIdsMap.get(objectnameforquery);
                lookupRecordsMap.putAll(Database.query(Constants.DML_SELECT + Constants.DML_ID + Constants.COMMA + Constants.DML_NAME + Constants.DML_FROM + objectnameforquery + Constants.DML_WHERE + Constants.ID_IN_RECORDS));
            }
        }
        if(lookupRecordsMap.size()>0&&!lookupRecordsMap.isEmpty()){
            System.debug('history tracking === ' + historyTrackingrecordList);
            for(Sobject finalListtocreatehistory:historyTrackingrecordList){
                if(finalListtocreatehistory.get(CONSTANTS.API_NEW_VALUE)!=null){
                    String newvalue=(string)finalListtocreatehistory.get(CONSTANTS.API_NEW_VALUE);
                    if(newvalue.length()==18&&lookupRecordsMap.containsKey((id)newvalue)){
                        finalListtocreatehistory.put(CONSTANTS.API_NEW_VALUE, lookupRecordsMap.get((id)newvalue).get(CONSTANTS.DML_NAME));
                    }
                }
                
                if(finalListtocreatehistory.get(CONSTANTS.API_PREVIOUS_VALUE)!=null){
                    String newvalue=(string)finalListtocreatehistory.get(CONSTANTS.API_PREVIOUS_VALUE);
                    if(newvalue.length()==18&&lookupRecordsMap.containsKey((id)newvalue)){
                        finalListtocreatehistory.put(Constants.API_PREVIOUS_VALUE, lookupRecordsMap.get((id)newvalue).get(CONSTANTS.DML_NAME));
                    }
                }
            }
        }
        
        //System.debug(Constants.FINAL_HISTORY_RECODS_TO_INSET+historyTrackingrecordList);
        return historyTrackingrecordList;
    }
}