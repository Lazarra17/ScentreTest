public class CreateContactController {
    //Below method is created to implement RPP-9740
	@auraEnabled
    public static Contact searchContact(String conId){
        List<Contact> contactList = [SELECT Id, AccountId
                                     FROM Contact 
                                     WHERE Id =: conId 
                                     LIMIT 1];
        
        if(!contactList.isEmpty()){
            return contactList[0];
        }
        return null;
    } 
}