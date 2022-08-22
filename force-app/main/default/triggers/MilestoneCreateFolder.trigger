trigger MilestoneCreateFolder on pse__Milestone__c (after insert) {
    for(pse__Milestone__c ms : Trigger.New) {
        string jsonMS = System.JSON.serializePretty(ms, false);
        WrikeService.requestAddMilestone(jsonMS);
    }
}