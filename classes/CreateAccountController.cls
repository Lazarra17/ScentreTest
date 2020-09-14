public class CreateAccountController {
    //Below method is created to implement RPP-9740
	@auraEnabled
    public static Contact searchContact(String accId){
        List<Contact> contactList = [SELECT Id 
                                     FROM Contact 
                                     WHERE AccountId =: accId 
                                     ORDER BY CreatedDate DESC
                                     LIMIT 1];
        
        if(!contactList.isEmpty()){
            return contactList[0];
        }
        return null;
    } 
}