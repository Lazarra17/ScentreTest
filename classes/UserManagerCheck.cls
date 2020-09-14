public class UserManagerCheck {
    @InvocableMethod 
    public static void userManagerFulfill(List<Id> userIds) {
        List<User> usrs = [select id, ManagerId, ManagerEmployeeID__c from user where Id in:userIds];
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(UserManagerCheck.class.getName());
        List<String> managerIds = new List<String>();
        for (User usr : usrs) {
            managerIds.add(usr.ManagerEmployeeID__c);
        }
        if (managerIds.size() > 0) {
            List<User> managers = [select id, EmployeeNumber from user where EmployeeNumber in:managerIds];
            for (User user : usrs) {
                for (User manager : managers) {
                    if (manager.EmployeeNumber == user.ManagerEmployeeID__c) {
                        user.ManagerId = manager.Id;
                    }
                }  
            }
             try{
                update usrs;
            } catch(Exception e) {
                errorHandler.createError(e);
            }
            
        }
        errorHandler.save();
    } 
}