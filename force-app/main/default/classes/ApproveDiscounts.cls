public class ApproveDiscounts {

    public Id oppId { get; set; }
    public Opportunity opp { get; set; }
    private boolean updateOpp { get; set; }
    public boolean errors { get; set; }
    
    public ApproveDiscounts(ApexPages.StandardController ctrl) {
        
        oppId = ctrl.getId();
        opp = [SELECT Id, Minimum_Period_in_Products__c, Discount_Approval_Status__c, Max_Discount__c, Approval_Reason__c FROM Opportunity WHERE Id = :oppId];
        
        errors = false;
        updateOpp = false;
        
		if (opp.Max_Discount__c < 30 && (opp.Minimum_Period_in_Products__c == null || opp.Minimum_Period_in_Products__c >= 365)) 
        {
            if (opp.Discount_Approval_Status__c != 'Approved') 
            {
                opp.Discount_Approval_Status__c = 'Approved';
                updateOpp = true;
            }

            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'This opportunity is approved by default'));
            errors = true;
        } 
        else 
        {
            if (opp.Discount_Approval_Status__c == 'Approved') 
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'This opportunity is already approved'));
                errors = true;
            }

            if (opp.Discount_Approval_Status__c == 'In Approval') 
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'This opportunity is already waiting for approval'));
                errors = true;
            }
        }
        
    }
    
    public PageReference GoBack() 
    {
        if (updateOpp) 
        {
            update opp;
        }

        return new PageReference('/' + oppId);
    }
    
    public PageReference StartApprovalProcess() 
    {        
        update opp;
        
        // Try the first approval request
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(opp.Approval_Reason__c);
        req1.setObjectId(oppId);
        req1.setProcessDefinitionNameOrId('Discount_50_100');
	    req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result1;
        boolean failed = false;
        try {
            result1 = Approval.process(req1);
            if (!result1.isSuccess())
                failed = true;
        } catch (Exception ex) {
            if (ex.getMessage().contains('NO_APPLICABLE_PROCESS')) {
            	failed = true;
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Error submitting for approval:' + ex.getMessage()));
            	return null;
            }
        }
        if (!failed) {
            return new PageReference('/' + oppId);
        } else {
            // Try the second approval request
            Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();
            req2.setComments(opp.Approval_Reason__c);
            req2.setObjectId(oppId);
            req2.setProcessDefinitionNameOrId('Discount_30_50');
            req2.setSkipEntryCriteria(false);
            Approval.ProcessResult result2;
            try {
            	result2 = Approval.process(req2);
            } catch (Exception ex) {
                if (ex.getMessage().contains('NO_APPLICABLE_PROCESS')) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'This opportunity does not require discount approval'));
                    return null;
                } else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Error submitting for approval:' + ex.getMessage()));
                    return null;
                }
            }
            if (result2.isSuccess()) {
                return new PageReference('/' + oppId);
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'Error submitting for approval:' + result2.getErrors()[0].getMessage()));
            	return null;
            }
        }      
    }    
}