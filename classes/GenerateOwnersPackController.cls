public class GenerateOwnersPackController {
    public class Response {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String concatenatedSpaces;   
        @AuraEnabled
        public String TECHReconfigSpaceIDs;  
        @AuraEnabled
        public String SpaceId;  
        @AuraEnabled
        public String PropertyId;  
        @AuraEnabled
        public String Id;  
        @AuraEnabled
        public String Name;  
        @AuraEnabled
        public String sessionId;  
        @AuraEnabled
        public String partnerServer;  
        @AuraEnabled
        public String PrimaryContactId;    
        @AuraEnabled
        public String TemplateOwnerPack;   
        @AuraEnabled
        public String SpaceandProperty;   
        @AuraEnabled
        public String CappedOccClause;   
        @AuraEnabled
        public String PromotionLevy;   
        @AuraEnabled
        public String EstimatedOutgoings;   
        @AuraEnabled
        public String ExistingSpace;   
        @AuraEnabled
        public String Dexus;   
        @AuraEnabled
        public String SUMforOwnerPack;   
        @AuraEnabled
        public String SpaceGroup;   
        @AuraEnabled
        public String ReconfiguredSpace;   
        @AuraEnabled
        public String SUMofReconfigured; 
		
		@AuraEnabled
        public String SpecialCondi;
		@AuraEnabled
        public String GuarantorNames;
		@AuraEnabled
        public String OpptyClause;
        @AuraEnabled
        public String OpportunityLineItems;
        
        public Response(){
            this.message = CONSTANTS.EMPTY;
            this.returnValue = CONSTANTS.EMPTY;
            this.status = CONSTANTS.SUCCESS;

        }
    }
    @AuraEnabled
    public static Response getOpp(Id opportunityId, String buttonName) {
        List<Id> opportunityIdLst = new List<Id> {opportunityId};
        Response res = new Response();
        

        CongaComposerTemplateValues__c cct = CongaComposerTemplateValues__c.getInstance();
        

        Map<Id,String> oppIdConcatStr = OpportunityBl.getConcatenatedSpaces(opportunityIdLst);
        List<Opportunity> oppLst = [select TECH_APIPartnerServer__c,TECH_APISessionID__c,TECH_ReconfigSpaceIDs__c,Space__c,Property__c,Id,Name,PrimaryContact__c from Opportunity where id =: opportunityId];
        system.debug('oppLst-->' + oppLst);
        res.TECHReconfigSpaceIDs = oppLst[0].TECH_ReconfigSpaceIDs__c;
        res.SpaceId = oppLst[0].Space__c;
        res.PropertyId = oppLst[0].Property__c;
        res.Id = oppLst[0].Id;
        res.Name = oppLst[0].Name;
        res.PrimaryContactId = oppLst[0].PrimaryContact__c;
        res.sessionId = oppLst[0].TECH_APISessionID__c;
        res.partnerServer = oppLst[0].TECH_APIPartnerServer__c;
        if(buttonName != null) {
            res.TemplateOwnerPack = cct.InternalOwnersPack__c;
        } else {
            res.TemplateOwnerPack = cct.TemplateOwnerPack__c;
        }
        res.SpaceandProperty = cct.SpaceandProperty__c;
        res.CappedOccClause = cct.CappedOccClause__c;
        res.PromotionLevy = cct.PromotionLevy__c;
        res.EstimatedOutgoings = cct.EstimatedOutgoings__c;
        res.ExistingSpace = cct.Existing_Space__c ;
        res.Dexus = cct.Dexus__c;
        res.SUMforOwnerPack = cct.SUMforOwnerPack__c;
        res.SpaceGroup = cct.SpaceGroup__c;
        res.ReconfiguredSpace = cct.ReconfiguredSpace__c;
        res.SUMofReconfigured = cct.SUMofReconfigured__c;
		res.SpecialCondi = cct.SpecialCondi__c;
		res.GuarantorNames=cct.GuarantorNames__c;
		res.OpptyClause=cct.OpptyClause__c;
		res.OpportunityLineItems=cct.OpportunityLineItems__c;
        
        if(oppidConcatStr.containskey(opportunityId)){
            res.concatenatedSpaces = oppidConcatStr.get(opportunityId); 
        }
        
        return res;
    }
}