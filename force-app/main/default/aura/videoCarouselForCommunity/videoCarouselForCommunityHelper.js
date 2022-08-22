({
	sendToVF : function(component, message) {
        var vfOrigin = window.location.href;
        var vfWindow = component.find("videoPlayer").getElement().contentWindow;
        vfWindow.postMessage(message, vfOrigin);
    },
    generateURL : function (component, src) {
		let resUrl = $A.get('$Resource.videoPlayer') + '#' + src;
		component.set('v.srcUrl',resUrl);   
        return resUrl;
    }
})