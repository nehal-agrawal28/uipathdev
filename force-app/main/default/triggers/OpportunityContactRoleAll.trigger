trigger OpportunityContactRoleAll on OpportunityContactRole (before insert, before update, after insert, after update, after delete) {
    
    if (Trigger.isBefore) {
        OppContactRoleQueueable_SL.deriveRole(Trigger.new);
    }
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            //OpportunityContactRoleHandlerAll.setOppPrimaryContact(Trigger.new, null);
            // OpportunityContactRoleHandlerAll.setContactStatus(Trigger.new, null);
            OpportunityContactRoleHandlerAll.setOutreachFirstPrimaryContact(Trigger.new, null);
            OpportunityContactRoleHandlerAll.setMarketingSourced(Trigger.new);
            OppContactRoleQueueable_SL.setPrimaryContactOnOpportunities(Trigger.new);
        }
        if(trigger.isUpdate) {
            //OpportunityContactRoleHandlerAll.setOppPrimaryContact(Trigger.new, Trigger.oldMap);
            // OpportunityContactRoleHandlerAll.setContactStatus(Trigger.new, Trigger.oldMap);
            OpportunityContactRoleHandlerAll.setOutreachFirstPrimaryContact(Trigger.new, Trigger.oldMap);
            OppContactRoleQueueable_SL.setPrimaryContactOnOpportunities(Trigger.new, Trigger.oldMap);
        }
        if(trigger.isDelete) {
            // OpportunityContactRoleHandlerAll.setContactStatus(null, Trigger.oldMap);
            OppContactRoleQueueable_SL.setPrimaryContactOnOpportunities(Trigger.old);
        }
    }
}