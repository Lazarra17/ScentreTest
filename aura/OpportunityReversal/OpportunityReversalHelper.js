({
	showToast : function(component, type, title, message){
        let self = this;
        let toast = component.find("toastRent");
        
        toast.set("v.title", title);
        toast.set("v.state", type);
        toast.set("v.message", message);
        
        toast.showToast();
    }
})