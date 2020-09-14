public with sharing class AddDeleteController {
    /***
    * @Author chen, need to correct class name to capital letter, please change it asap
    */
   /*@AuraEnabled
    public static void saveContacts(List<Contact> ListContact){
        Insert ListContact;
    }
   
    @AuraEnabled
    public static void saveNonStandardOppoLineItems(List<OpportunityLineItem> listOppoLineItem, Id oppoId, String cpiType, String reviewCode, String reviewDescription){
        // POC, later to decide how to select product and productEntryItem
        List<OpportunityLineItem> updatedListItem = new List<OpportunityLineItem>();
        for (Integer i=0; i<listOppoLineItem.size(); i++) {           
            OpportunityLineItem item = listOppoLineItem.get(i);
            item.Product2Id = '01t7F000003bQbhQAE';
            item.OpportunityId = oppoId;
            item.PricebookEntryId = '01u7F000003NgyIQAS';
            item.ReviewCode__c = reviewCode;
            item.CPIType__c = cpiType;
            //item.Year__c = i + 2;
            item.RentReviewDescription__c = reviewDescription;
            updatedListItem.add(item);
        }
        insert updatedListItem;
    }
    
    @AuraEnabled
    public static Integer checkYears(Id opportunityId){
        Integer years = calyears(opportunityId);
        return years;
    }
    
    
    private static Integer calYears(Id opportunityId) {
        Opportunity oppo = [select ProposedStartDate__c, ProposedEndDate__c from Opportunity where id =:opportunityId];
        Date startDate = oppo.ProposedStartDate__c;
        Date endDate = oppo.ProposedEndDate__c;
        Integer year = endDate.year() - startDate.year() - 1;
        return year;
    }
    
    @AuraEnabled
    public static void saveStandardRentReviewItems(Id opportunityId, String reviewType, String reviewDescription) {
        Integer years = calyears(opportunityId);
        List<OpportunityLineItem> listItem = new List<OpportunityLineItem>();
        for (Integer i=0; i < years; i++) {
            if (reviewType == 'CPI1.5') {
                OpportunityLineItem item = new OpportunityLineItem();
                item.Product2Id = '01t7F000003bQbhQAE';
                item.OpportunityId = opportunityId;
                item.PricebookEntryId = '01u7F000003NgyIQAS';
                item.ReviewType__c = 'CPI+';
                //item.RentReviewValue__c = 1.5;
                // what is the review code?
                //item.Year__c = i + 2;
                item.RentReviewDescription__c = reviewDescription;
                listItem.add(item);
            }
        }
        insert listItem;
    }    */
}