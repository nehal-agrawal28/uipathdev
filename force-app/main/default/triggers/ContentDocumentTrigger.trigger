trigger ContentDocumentTrigger on ContentDocument (before delete) {

    ContentDocumentTriggerHandler handler = new ContentDocumentTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isDelete) {
        
        if(Trigger.isBefore) {
            
            handler.onBeforeDelete(Trigger.old);
        }
    }
}