trigger WrikePSTaskTMTrigger on Pre_Sales_Team__c (after insert, before delete) {
    if (Trigger.isDelete) {
        for(Pre_Sales_Team__c teamMember : Trigger.Old) {
            string jsonTeamMember = System.JSON.serializePretty(teamMember, false);
            WrikeService.requestDeleteTeamMember(jsonTeamMember);
            //WebhookService.request(jsonTeamMember);
        }
    }
    if (Trigger.isInsert) {
        for(Pre_Sales_Team__c teamMember : Trigger.New) {
            string jsonTeamMember = System.JSON.serializePretty(teamMember, false);
            WrikeService.requestAddTeamMember(jsonTeamMember);
            //WebhookService.request(jsonTeamMember);
        }
    }
}