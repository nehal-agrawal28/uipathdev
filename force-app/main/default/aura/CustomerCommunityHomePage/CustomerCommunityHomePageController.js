({
	onGetStartedClick : function(component, event, helper) {
		location.href='/customer/s/contactsupport';
	},
    onMyCasesClick : function(component, event, helper) {
        var navEvent = $A.get("e.force:navigateToList");
        let listViewId = $A.get ('$Label.c.CommunityDeafultListViewId');
        if (listViewId.trim().length == 15) {
            var s="";
            for(var i=0;i<3; i++) {
                var f=0;
                for(var j=0;j<5;j++) {
                    var c=listViewId.charAt(i*5+j);
                    if(c>="A" && c<="Z")
                        f+=1<<j;
                }
                s+="ABCDEFGHIJKLMNOPQRSTUVWXYZ012345".charAt(f);
            } 
            listViewId = listViewId + s;
        }
        
        navEvent.setParams({
            "listViewId": listViewId,
            "listViewName": "All_Cases",
            "scope": "Case"
        });
        navEvent.fire();
	},
    onCreateNewCaseClick : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "contactsupport",
        });
        urlEvent.fire();
        
	},
    onKnowledgeBaseClick : function(component, event, helper) {
			
	},
	onDashBoardClick : function(component, event, helper) {
			
	},
    onQuickHelpClick : function(component, event, helper) {
			
	},
})