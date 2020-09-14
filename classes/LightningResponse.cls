public class LightningResponse{
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String returnValue;
    
    public LightningResponse(){
        this.status = Constants.SUCCESS;
        this.message = Constants.EMPTY;
        this.returnValue = Constants.EMPTY;
    }
}