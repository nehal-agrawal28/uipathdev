trigger EmailMessageTrigger on EmailMessage (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) {

    EmailMessageTriggerHandler handler = new EmailMessageTriggerHandler(Trigger.isExecuting, Trigger.size);
        SYStem.debug('****************TEST************EMAIL**');
        if (Trigger.isBefore) {
            //call your handler.before method
            if(Trigger.isInsert || Trigger.isUpdate){
                System.debug('inside before insert email trigger');
                handler.onBeforInsert(Trigger.new);

            }   
        }
    }