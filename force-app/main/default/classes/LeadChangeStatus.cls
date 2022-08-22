/********************************************************************************************************
*    Name:  LeadChangeStatus.cls
*    Author: Mirela Chituc
*    Date:  9/13/2019
*    
*    Test class: LeadChangeStatusTest.cls
*
*    // Update status to Disqualified/Recycled and complete Reason for all selected leads      
********************************************************************************************************/

public class LeadChangeStatus {
    
    ApexPages.StandardSetController setCon;
    
    public String leadStatus { get; set; }
    public String noOfSelectedLeads { get; set; }
    public String leadDisqualifiedReason { get; set; }
    public String leadRecycledReason { get; set; }
    public String errorMessage { get; set; }
    public String successMessage { get; set; }
    
    public LeadChangeStatus(ApexPages.StandardSetController controller)
    {
        setCon = controller;
        noOfSelectedLeads = '0';
        if(((Lead[])setCon.getSelected()).size() > 0)
            noOfSelectedLeads = String.valueOf(((Lead[])setCon.getSelected()).size());
        
        errorMessage = '';
        successMessage = '';
        if(((Lead[])setCon.getSelected()).size()>100)
            errorMessage = 'Total number of selected records is ' + ((Lead[])setCon.getSelected()).size() + '. Please select maximum 100 records at a time.';
    }
    
    
    
    public List<SelectOption> getStatusPickListValues() {
        List<SelectOption> selectOptions = new List<SelectOption>();
        
        Map<String, String> StatusValueLabels = picklistValues('Lead', 'Status');
        selectOptions.add(new SelectOption('', '-- Select Status --'));
        for (String value : StatusValueLabels.keySet()) {
            if(StatusValueLabels.get(value) == 'Disqualified' || StatusValueLabels.get(value) == 'Recycle')
                selectOptions.add(new SelectOption(value, StatusValueLabels.get(value)));
        }

        return selectOptions;
    }
    
    public List<SelectOption> getDisqualifiedPickListValues() {
        List<SelectOption> selectOptions = new List<SelectOption>();

        Map<String, String> DisqualifiedValueLabels = picklistValues('Lead', 'Disqualified_Reason__c');
        selectOptions.add(new SelectOption('', '-- Select Disqualified Reason --'));
        for (String value : DisqualifiedValueLabels.keySet()) {
            
            selectOptions.add(new SelectOption(value, DisqualifiedValueLabels.get(value)));
        }

        return selectOptions;
    }
    
    public List<SelectOption> getRecycledPickListValues() {
        List<SelectOption> selectOptions = new List<SelectOption>();

        Map<String, String> RecycledValueLabels = picklistValues('Lead', 'Recycled_Reason__c');
        selectOptions.add(new SelectOption('', '-- Select Recycled Reason --'));
        for (String value : RecycledValueLabels.keySet()) {
            selectOptions.add(new SelectOption(value, RecycledValueLabels.get(value)));
        }

        return selectOptions;
    }
    
    
    public static Map<String, String> picklistValues(String objectName, String fieldName) {
        Map<String, String> values = new Map<String, String>{};

        List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.put(entry.getValue(), entry.getLabel());
                }
            }
        }

        return values;
    }

    public pageReference ChangeStatus()
    {
        
        successMessage = '';        
        
        List<Lead> allSelectedLeads = new List<Lead>();
        
        // do something with the selected records
        for ( Lead ld : (Lead[])setCon.getSelected() )
        {
              
              ld.Status = leadStatus;
              if(leadStatus == 'Disqualified') 
              {
                  ld.Disqualified_Reason__c = leadDisqualifiedReason;
                  ld.Recycled_Reason__c = '';
              }
              if(leadStatus == 'Recycle')
              {
                  ld.Recycled_Reason__c = leadRecycledReason;
                  ld.Disqualified_Reason__c = '';
              } 
              allSelectedLeads.add(ld);
        }
        
        if(allSelectedLeads.size() > 0)  
        {
            try {
                update allSelectedLeads;
                errorMessage = '';
                successMessage = 'Status successfully changed.';
            } catch(DmlException e) {
                successMessage = '';
                errorMessage = 'The following exception has occurred: ' + e.getMessage();
            }  
        }    
        return null;
    }
    
    public PageReference redirectToList() { 
        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe(); 
        PageReference pageRef = new PageReference('/' + result.getKeyPrefix()); 
        pageRef.setRedirect(true); 
       return pageRef; 
    }
}