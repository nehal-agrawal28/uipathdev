public class ApprovalURL {

    public String recID { get; set; }  
    
    public String urlStr {  
    	get {  
    		String url = '';  
        
            List<ProcessInstanceWorkitem> workItemLst = [SELECT id FROM ProcessInstanceWorkitem WHERE processInstance.TargetObjectId = :recID];   
            
            if(workItemLst.size() > 0)  
            {  
                url='https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItemLst[0].id;      
            }  
            return url;
   		}
    }
    
}