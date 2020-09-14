({
	isValidInput : function(component, event) {
		var actionType = component.get("v.actionType");
        if(actionType == 'Reassign'){
            if(component.get("v.reassignedUser") == null){
                alert('Please enter the User details to reassign the Approval Request');
                return false;
            }
        }
        return true;
	}
})