trigger WrikeCSMTask on CSM_PS_Engagement__c (after insert, before update) {
    for(CSM_PS_Engagement__c task : Trigger.New) {
        string jsonTask = System.JSON.serializePretty(task, false);
        WrikeService.requestAddCSMTask(jsonTask);
        //WebhookService.request(jsonTask);
    }
}