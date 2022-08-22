/**
*
* Author:       Daniel Sarchiz
* Date:         20/11/2017
* Description:  Main trigger for Content Document Link
*
**/

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert, after delete) {
    
    ContentDocumentLinkTriggerHandler handler = new ContentDocumentLinkTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert) {
        
        if(Trigger.isBefore) {
            
            handler.onBeforeInsert(Trigger.new);
        }
        else if(Trigger.isAfter) {
            
            handler.onAfterInsert(Trigger.new);
        }
    }
    else if(Trigger.isDelete) {
        
        if(Trigger.isAfter) {
            
            handler.onAfterDelete(Trigger.old);
        }
    }
}