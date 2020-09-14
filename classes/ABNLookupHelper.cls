/**
* @author:              Kyle Tan
* @desc:                contains methods to verify ABN/ACN of an account
**/
public class ABNLookupHelper {
    public class ABNsearchResultWrapper{
        public String abn;
        public String abnStatus;
        public String addressDate;
        public String addressPostCode;
        public String addressState;
        public String[] businessName;
        public String entityName;
        public String entityTypeCode;
        public String entityTypeName;
        public String gst;
        public String message;
    }
    
    public class NZBNsearchResultWrapper{
        public String entityStatusCode;
        public String entityName;
        public String nzbn;
        public String entityTypeCode;
        public String entityTypeDescription;
        public String entityStatusDescription;
        public String registrationDate;
        public String startDate;
        public String sourceRegister;
        public String sourceRegisterUniqueIdentifier;
        public String gstStatus;
        public String gstEffectiveDate;
        public String lastUpdatedDate;
        public String locationIdentifier;
        public String australianBusinessNumber;
        public String australianCompanyNumber;
        public String australianServiceAddress;
        public String privacySettings;
        public String supportingInformation;
        public String errorMessage;
    }
    
    public class ABNNameWrapper {
        public String Abn;
        public String AbnStatus;
        public String IsCurrent;
        public String Name;
        public String NameType;
        public String Postcode;
        public String Score;
        public String State;
    }
    
    public class ABNNameSearchResultWrapper {
        public String Message;
        public List<ABNNameWrapper> Names;
    }
    
    public class NZBNItemNamesWrapper {
        public String nzbn;
        public String entityName;
        public NZBNIdNameWrapper entityType;
        public NZBNIdNameWrapper entityStatus;
    }
    
    public class NZBNIdNameWrapper {
        public String id;
        public String name;
    }
    
    public class NZBNNameSearchResultWrapper {
        public String pageSize;
        public List<NZBNItemNamesWrapper> items;
    }
    
    public class nzbnTableColumn {
        public String nzbn;
        public String entityName;
        public String entityType;
    }
    
    /**
    * @author:              Yana Navarro
    * @desc:                @future method for ABN search callout
    **/
    /*
    @future(callout=true)
    public static void updateAccountABNStatus(String accountJSON) {
        String service;
        String searchValue;
        Integer counter = 0;
        ABNsearchResultWrapper abnWrapper;
        NZBNsearchResultWrapper nzbnWrapper;
        List<Account> accountList;
        List<Account> updatedAccountList = new List<Account>();
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(ABNLookupHelper.class.getName());
        
        try {
            if(String.isNotEmpty(accountJSON)){
                accountList = (List<Account>) JSON.deserialize(accountJSON, List<Account>.class);
            }
        } catch (Exception e) {
            accountList = NULL;
        }
        
        if(accountList!=NULL && accountList.size()>0) {
            for(Account acc : accountList){
                service = Constants.EMPTY;
                searchValue = Constants.EMPTY;
                
                if(String.isNotEmpty(acc.ABNNZBN__c)){
                    searchValue = acc.ABNNZBN__c;
                    service = Constants.ABN;
                    
                    if(Constants.NEW_ZEALAND.equalsIgnoreCase(acc.BillingCountry)){
                        service = Constants.NZBN;
                    }
                } else if(String.isNotEmpty(acc.ACN__c)){
                    service = Constants.ACN;
                    searchValue = acc.ACN__c;
                }
                
                if(service == Constants.ABN) {
                    abnWrapper = getABNSearchResult(service, searchValue);
                    if(String.isNotEmpty(abnWrapper.message)){
                        acc.ABNNZBNStatus__c = Constants.INVALID;
                    } else if(String.isNotEmpty(abnWrapper.abnStatus)){
                        acc.ABNNZBNStatus__c = Constants.VALID;
                    }
                } else if(service == Constants.NZBN) {
                    nzbnWrapper = getNZBNSearchResult(searchValue);
                    if(String.isNotEmpty(nzbnWrapper.errorMessage)){
                        acc.ABNNZBNStatus__c = Constants.INVALID;
                    } else if(String.isNotEmpty(nzbnWrapper.nzbn)){
                        acc.ABNNZBNStatus__c = Constants.VALID;
                    }
                }
                updatedAccountList.add(acc);
            }
        }
 
        TriggerHandler.bypass(AccountTriggerHandler.class.getName());
        List<Database.SaveResult> sResultList = Database.update(updatedAccountList, false);
        
        for(Database.SaveResult sResult : sResultList){
            if(!sResult.isSuccess()){
                errorHandler.createError(sResult, updatedAccountList[counter].Id);
            }
            counter++;
        }
        errorHandler.save();
    }
    */
    /**
    * @author:              Kyle Tan
    * @desc:                convert web service response to wrapper record
    **/
    public static ABNsearchResultWrapper getABNSearchResult(String service, String searchValue) {
        ABNsearchResultWrapper abnWrapper = new ABNsearchResultWrapper();
        HttpResponse httpResponse = new HttpResponse();
        
        if(String.isNotEmpty(searchValue)) {
            String endPoint = buildEndPoint(service, searchValue);
            
            if(String.isNotEmpty(endPoint)) {
                try {
                    httpResponse = webCallOut(endPoint, Constants.GET, Constants.EMPTY);
                } catch(Exception e) {
                    httpResponse = null;
                }
            }
            if(httpResponse != null) {
                String jsonBody = httpResponse.getBody();
                jsonBody = jsonBody.substring(
                    jsonBody.indexOf(Constants.OPEN_BRACKET), 
                    jsonBody.lastIndexOf(Constants.CLOSE_BRACKET) + 1
                );
                try {
                    abnWrapper = (ABNsearchResultWrapper) JSON.deserialize(jsonBody, ABNsearchResultWrapper.class);
                } catch (Exception e) {
                    abnWrapper = NULL;
                }
            }
        }
        
        return abnWrapper;
    }
    
    /**
    * @author:              Kyle Tan
    * @desc:                convert web service response to wrapper record
    **/
    public static NZBNsearchResultWrapper getNZBNSearchResult(String searchValue) {
        NZBNsearchResultWrapper nzbnWrapper = new NZBNsearchResultWrapper();
        HttpResponse httpResponse = new HttpResponse();
        
        if(String.isNotEmpty(searchValue)) {
            String endPoint = Label.NZBNURL + searchValue;
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod(Constants.GET);
            req.setHeader(Constants.NZBN_HEADER_ACCEPT, Constants.NZBN_HEADER_APP_JSON);
            req.setHeader(Constants.NZBN_HEADER_AUTH, Constants.NZBN_HEADER_BEARER + Label.NZBNAccessToken);
            try {
                httpResponse = http.send(req);
            } catch (Exception e) {
                httpResponse = NULL;
            }
            if(httpResponse != null) {
                String jsonBody = httpResponse.getBody();
                jsonBody = jsonBody.substring(
                    jsonBody.indexOf(Constants.OPEN_BRACKET), 
                    jsonBody.lastIndexOf(Constants.CLOSE_BRACKET) + 1
                );
                nzbnWrapper = (NZBNsearchResultWrapper) JSON.deserialize(jsonBody, NZBNsearchResultWrapper.class);
            }
        }
        return nzbnWrapper;
    }
    
    /**
    * @author:              Kyle Tan
    * @desc:                construct end points URL
    **/
    public static String buildEndPoint(String service, String searchString) {
        String endPoint = null;
        if(String.isNotEmpty(service) && String.isNotEmpty(searchString)) {
            if(Constants.ABN.equalsIgnoreCase(service)){
                endPoint = Label.ABNURL;
                endPoint += Constants.URL_ABN + searchString;
            } else if(Constants.ACN.equalsIgnoreCase(service)){
                endPoint = Label.ACNURL;
                endPoint += Constants.URL_ACN + searchString;
            }
            endPoint += Constants.AMP + Label.ABNGUID;
        }
        
        return endPoint;
    }
    
    /**
    * @author:              Kyle Tan
    * @desc:                HTTP call out
    **/
    public static HttpResponse webCallOut(String endPoint, String method, String body){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(method);
        System.debug('ENDPOINT REQUEST: '+req);
        return http.send(req);
    }
    
    /**
    * @author:				Kyle Tan
    * @desc:				ABN search by Entity
    **/
    @AuraEnabled
    public static ABNNameSearchResultWrapper getABNNameSearchResult(String searchString) {
        ABNNameSearchResultWrapper abnNameWrapper = new ABNNameSearchResultWrapper();
        if(String.isNotEmpty(searchString)) {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse httpResponse = new HttpResponse();
            String trimmedString = searchString.trim().replace(' ', '%20');
            String endPoint = Label.ABNNameSearch + trimmedString + Constants.AMP + Constants.MAX_RESULTS + Constants.AMP + Label.ABNGUID;
            //String endPoint='https://abr.business.gov.au/json/MatchingNames.aspx?name=Super%20Great%20Jeans%20Group&guid=ed19f77e-8587-4292-a9cf-4c00ad377150&tradingName=true&legalName=false';
            req.setEndpoint(endPoint);
            req.setMethod(Constants.GET);
            
            try {
                httpResponse = http.send(req);
            } catch (Exception e) {
                httpResponse = NULL;
            }
            system.debug(req+' RESARCH RESPONSE: '+httpResponse);
            if(httpResponse != null) {
                String jsonBody = httpResponse.getBody();
                system.debug('jsonBody1-->' + jsonBody);
                jsonBody = jsonBody.substring(
                    jsonBody.indexOf(Constants.OPEN_BRACKET), 
                    jsonBody.lastIndexOf(Constants.CLOSE_BRACKET) + 1
                );
                system.debug('jsonBody2-->' + jsonBody);
                abnNameWrapper = (ABNNameSearchResultWrapper) JSON.deserialize(jsonBody, ABNNameSearchResultWrapper.class);
            }
        }
        return abnNameWrapper;
    }
    
    /**
    * @author:              Kyle Tan
    * @desc:                NZBN Name Search
    **/
    public static NZBNNameSearchResultWrapper getNZBNNameSearchResult(String searchValue) {
        NZBNNameSearchResultWrapper nzbnNameWrapper = new NZBNNameSearchResultWrapper();
        HttpResponse httpResponse = new HttpResponse();
        
        if(String.isNotEmpty(searchValue)) {
            String trimmedString = searchValue.trim().replace(' ', '%20');
            String endPoint = Label.NZBNNameSearch + trimmedString;
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            system.debug('endPoint-->' + endPoint);
            req.setMethod(Constants.GET);
            req.setHeader(Constants.NZBN_HEADER_ACCEPT, Constants.NZBN_HEADER_APP_JSON);
            req.setHeader(Constants.NZBN_HEADER_AUTH, Constants.NZBN_HEADER_BEARER + Label.NZBNAccessToken);
            system.debug('req-->' + req);
            try {
                httpResponse = http.send(req);
            } catch (Exception e) {
                httpResponse = NULL;
            }
            if(httpResponse != null) {
                String jsonBody = httpResponse.getBody();
                jsonBody = jsonBody.substring(
                    jsonBody.indexOf(Constants.OPEN_BRACKET), 
                    jsonBody.lastIndexOf(Constants.CLOSE_BRACKET) + 1
                );
                nzbnNameWrapper = (NZBNNameSearchResultWrapper) JSON.deserialize(jsonBody, NZBNNameSearchResultWrapper.class);
            }
        }
        system.debug('nzbnNameWrapper-->' + nzbnNameWrapper);
        return nzbnNameWrapper;
    }
}