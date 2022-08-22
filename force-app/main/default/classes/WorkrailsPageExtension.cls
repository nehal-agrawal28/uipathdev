public with sharing class WorkrailsPageExtension {
    public SBQQ__Quote__c quote { get; set; }
    public Boolean hasPermission { get; set; }
    public Boolean showWorkrail { get; set; }

    public WorkrailsPageExtension(ApexPages.StandardController stdController) {
        SBQQ__Quote__c stdCtrlRecord = (SBQQ__Quote__c) stdController.getRecord();
        
        if(stdCtrlRecord != null && stdCtrlRecord.Id != null){
            this.quote = [SELECT Id, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE Id = :stdCtrlRecord.Id];
    
            this.showWorkrail = false;
    
            // Check primary quote
            if (this.quote.SBQQ__Primary__c == false) {
                ApexPages.Message msg = new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Please update this quote as Primary and try again.'
                );
                ApexPages.addMessage(msg);
            } else {
                // Check SCOPE permission
                this.hasPermission = FeatureManagement.checkPermission('CPQ_SCOPE_Admin');
                if (this.hasPermission == false) {
                    ApexPages.Message msg = new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        'You do not have CPQ SCOPE permission.'
                    );
                    ApexPages.addMessage(msg);
                }
            }
        } else {
            // No quote Id present
            this.showWorkrail = true;
        }
    }

    public Pagereference scopeAttachQuote() {
        try {
            SBQQ__Quote__c attachQuote = new SBQQ__Quote__c(Id = this.quote.Id, SCOPEQuote__c = true);
            update attachQuote;

            // Show Workrail VF page
            this.showWorkrail = true;
        } catch (Exception ex) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage());
            ApexPages.addMessage(msg);
        }
        return null;
    }
}