public class TypeaheadController {
	@AuraEnabled(Cacheable = true)
    public static String searchDB(String objectName, String fld_API_Text, String fld_API_Val, Integer lim, String fld_API_Search, String searchText, String conditionStr, Boolean allowToCreateNew){
        
        searchText = '\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\''; 
        System.debug('searchText === '+searchText);

        String query;
        if(conditionStr != ''){
        	query = 'SELECT ' + fld_API_Text + ' ,' + fld_API_Val + 
                        ' FROM ' + objectName +
                        ' WHERE '+ conditionStr + ' AND ' + fld_API_Search +' LIKE '+searchText + ' Order BY ' + fld_API_Search +  
                        ' LIMIT '+lim;
        }else{
            query = 'SELECT ' + fld_API_Text + ' ,' + fld_API_Val + 
                        ' FROM ' + objectName +
                        ' WHERE ' + fld_API_Search +' LIKE '+searchText + ' Order BY ' + fld_API_Search + 
                        ' LIMIT '+lim;
        }
        
        system.debug('=query==' + query);
        List<sObject> sobjList = Database.query(query);
        List<ResultWrapper> lstRet = new List<ResultWrapper>();
        
        if(allowToCreateNew){
            ResultWrapper wrap = new ResultWrapper();
            wrap.objName = objectName;
            wrap.text = ('Create New '+wrap.objName);
            wrap.val = ('');
            lstRet.add(wrap);
        }
        
        
        for(SObject s : sobjList){
            ResultWrapper obj = new ResultWrapper();
            
            obj.objName = objectName;
            obj.text = String.valueOf(s.get(fld_API_Text));
            obj.val = String.valueOf(s.get(fld_API_Val));
            
            lstRet.add(obj);
        } 
         System.debug('lstRet === '+lstRet);
         return JSON.serialize(lstRet) ;
    }
    
    public class ResultWrapper{
        public String objName {get; set;}
        public String text {get; set;}
        public String val {get; set;}
    }
}