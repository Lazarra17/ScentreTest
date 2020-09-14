global with sharing class UpdateTaskOwnerController{
    public string taskIdsstring{get;set;}
    public List<String> validuserProfiles{get;set;}
    public Boolean isValiduser{get;set;}
    public static Task taskRecord{get;set;}
    public UpdateTaskOwnerController(){
        
        
    }
    public UpdateTaskOwnerController(ApexPages.StandardSetController controller){
        
    }
    public void validate(){
        isValiduser=false;
        taskRecord=new Task();
        taskRecord.ownerID=Userinfo.getUserId();
        system.debug('taskRecord'+taskRecord);
        validuserProfiles=System.Label.TaskOwnerUpdateProfiles.split(';');
        User userinfo=[select id,Profile.Name from User where id  =: Userinfo.getUserId()];
        if(validuserProfiles.contains(userinfo.Profile.Name)){
            isValiduser=true;
        }
    }
    @RemoteAction
    global static string UpdateTaskOwner(string ownerId,String taskIdsstring){              
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(UpdateTaskOwnerController.class.getName());
        System.debug('INSIDE');
        try{
            if(String.isNotBlank(taskIdsstring)){
                taskIdsstring = taskIdsstring.remove(']').remove('[').remove(' ');    
                List<String> taskIdList = taskIdsstring.split(',');
                List<Task> taskList = [Select id,OwnerId from Task where Id IN: taskIdList LIMIT 500];                                                    
                for(Task taskRecord: taskList){                    
                    taskRecord.ownerid = ownerId;
                }
                database.update(taskList,false);       
            }
            return 'Task Owner Updated';
        }
        catch(exception ex){
            errorHandler.createError(ex);
             System.debug('INSIDE'+ex);
            return ex.getMessage();
        }        
    }
}