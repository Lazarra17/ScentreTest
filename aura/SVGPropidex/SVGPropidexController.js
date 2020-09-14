({
	doInit  : function(component, event, helper) {
        // Extract the width and height that was computed by CSS.
    	var chartDiv = document.getElementById("vis");
        // load the external svg from a file
        // load the external svg from a file
      d3.xml("/resource/SVG/BelconnenSVG/Belconnen_4.svg").mimeType("image/svg+xml").get(function(error, xml) {
        if (error) throw error;
       	//var listDOM = document.getElementById("vis");
        //listDOM.innerHTML = "<?xml version='1.0' encoding='UTF-8'?><!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1000' height='1000' viewBox='0 0 10000 10000'>" + xml.documentElement.innerHTML + "</<svg>";
        var importedNode = document.importNode(xml.documentElement, true);
        d3.select("div#vis")
        .each(function() {
          this.appendChild(importedNode);
        })
        // inside of our d3.xml callback, call another function
        // that styles individual paths inside of our imported svg
        //styleImportedSVG()
        helper.onPathClick(component, event, helper);
      });
	}
})