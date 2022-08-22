/**
*
* Author:       Daniel Sarchiz
* Date:         22/11/2017
* Description:  Main trigger for Attachement object
*
**/

trigger AttachmentTrigger on Attachment (after insert) {
    
    AttachmentTriggerHandler handler = new AttachmentTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert) {
        
        if(Trigger.isAfter) {
            
            handler.onAfterInsert(Trigger.New);
        }
    }
}