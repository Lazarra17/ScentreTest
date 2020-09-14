public without sharing class UpdateOpportunityObjectivesController {
    
    public class OpportunityWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Boolean lockedOpp;
    }    
    
    @AuraEnabled
    public static LightningResponse unLockOpportunity(Id oppId){    
        LightningResponse response =new LightningResponse(); 
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityUnlockUpdateController.class.getName());
        OpportunityWrapper wrapper = new OpportunityWrapper();
        
        wrapper.lockedOpp = Approval.isLocked(oppId);
        
        if (wrapper.lockedOpp) {
            try{
                Approval.UnlockResult unlockRes = Approval.Unlock(oppId);
                wrapper.isSuccess = unlockRes.isSuccess();
                
            } catch (System.Exception e) {
                response.status = Constants.FAILED;
                response.message = e.getMessage();
                errorHandler.createError(e);
            }          
        }
        
        response.returnValue = JSON.serialize(wrapper);
        errorHandler.save();
        return response;
    }
    
    @AuraEnabled
    public static LightningResponse lockOpportunity(Id oppId){
        
        LightningResponse response =new LightningResponse(); 
        ErrorHandlerUtil errorHandler = new ErrorHandlerUtil(OpportunityUnlockUpdateController.class.getName());
        OpportunityWrapper wrapper = new OpportunityWrapper();
        
        try{
            Approval.LockResult lockRes = Approval.lock(oppId);
            
            wrapper.lockedOpp = Approval.isLocked(oppId);
            wrapper.isSuccess = lockRes.isSuccess();
        }
        catch(System.Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        
        response.returnValue = JSON.serialize(wrapper);
        errorHandler.save();
        return response;

    }
}