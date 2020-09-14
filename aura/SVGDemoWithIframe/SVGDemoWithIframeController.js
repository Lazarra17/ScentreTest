({
	doInit : function(component, event, helper) {
        var imageLocation = "https://s.cdpn.io/3/kiwi.svg";
        //var imageLocation = "https://scentre.lightning.force.com/resource/SVG/BelconnenSVG/Belconnen_4.svg"; //test.svg
        component.set("v.imageLocation", imageLocation);
		window.addEventListener("message", function(event) {
            console.log('lightning received data' + event.data);
            if (event !== null && event.data !== null) {
             	var compEvent = component.getEvent("spaceDetails");
                compEvent.setParams({"spaceId" : event.data });
                compEvent.fire();   
            }
        }, false);
	}
})