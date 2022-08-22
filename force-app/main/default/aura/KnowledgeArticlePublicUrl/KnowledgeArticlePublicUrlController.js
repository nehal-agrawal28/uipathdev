({
	handleClick : function(component, event, helper) {
		component.set("v.isCopied",true);
        window.setTimeout(function(){
            component.set("v.isCopied",false);
        },5000);
         var hiddenInput = document.createElement("input");
        // passed text into the input
        hiddenInput.setAttribute("value", $A.get("$Label.c.CaseViewUrl")+component.get("v.knowledgeRecord.UrlName"));
        // Append the hiddenInput input to the body
        document.body.appendChild(hiddenInput);
        // select the content
        hiddenInput.select();
        // Execute the copy command
        document.execCommand("copy");
        // Remove the input from the body after copy text
        document.body.removeChild(hiddenInput); 
	}
})