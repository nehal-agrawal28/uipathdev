trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after insert, after update, before delete) {

    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) {
    	//OpportunityLineItemHelper.setType(Trigger.new);
        //OpportunityLineItemHelper.setPeriod(Trigger.new);
        //OpportunityLineItemAssetAssociation.setAssetAssignment(Trigger.new);
    }
    
    if (Trigger.isUpdate && Trigger.isAfter) {
    	//OpportunityLineItemHelper.newDiscounts(Trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isInsert && Trigger.isAfter){ 
        
    }

    if (Trigger.isDelete && Trigger.isBefore) {
        //OpportunityLineItemHelper.checkForLinkedAssetBeforeDeleting(Trigger.old);
    }
}