trigger QuoteLineItemAll on QuoteLineItem (before insert) {

    if (Trigger.isBefore && Trigger.isInsert) {
        QuoteLineItemHandler.PrePopulateEndDate(Trigger.new);
    }
    
}