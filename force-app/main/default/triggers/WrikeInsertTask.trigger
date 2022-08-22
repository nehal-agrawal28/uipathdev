trigger WrikeInsertTask on Pre_Sales_Tasks__c (after insert, before update) {
    for(Pre_Sales_Tasks__c task : Trigger.New) {
        if (task.Opportunity__c != NULL) {
            string jsonTask = System.JSON.serializePretty(task, false);
        	WrikeService.requestAddOpportunityTask(jsonTask);
            //WebhookService.request(jsonTask);
        } else {
            string jsonTask = System.JSON.serializePretty(task, false);
            WrikeService.requestAddAccountTask(jsonTask);
            //WebhookService.request(jsonTask);
        }
    }
}