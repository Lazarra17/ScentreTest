({
	onPathClick : function(component, event, helper) {
                d3.selectAll("path").on('click', function(){
        //document.getElementsByTagName("path").addEventListener('click', function(){
          if (typeof this.attributes.id != 'undefined') {
            //alert('space id ' + this.attributes.id.value);
          	this.setAttribute('fill',"#ff0000");
            var compEvent = component.getEvent("spaceDetails");
            compEvent.setParams({"spaceId" : this.attributes.id.value });
			compEvent.fire();
          }
        })
    }
})