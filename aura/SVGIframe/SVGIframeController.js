({
	doInit : function(component, event, helper) {
        //var imageLocation = "https://s.cdpn.io/3/kiwi.svg";
        var imageLocation = component.get("v.imageLocation");
        console.log('imageLocation', imageLocation);
		window.addEventListener("message", function(event) {
            console.log('lightning received data' + event.data);
            if (event !== null && event.data !== null) {
             	//var compEvent = component.getEvent("spaceDetails");
                //compEvent.setParams({"spaceId" : event.data });
                //compEvent.fire();   
            }
        }, false);
	}
})