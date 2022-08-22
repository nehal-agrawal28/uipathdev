/**
*
* Author:       Daniel Sarchiz
* Date:         16/11/2017
* Description:  Main trigger for Case object
*
**/
trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
    //CaseTriggerHandler handler = new CaseTriggerHandler(Trigger.isExecuting, Trigger.size);
    /*CaseTriggerHelper  helper = new CaseTriggerHelper(Trigger.isExecuting, Trigger.size);
    if(Trigger.isInsert) 
    {    
        if(Trigger.isBefore) 
        {
            //handler.onBeforeInsert(Trigger.New);
            System.debug('onBeforeInsert' + Trigger.New[0]);
            helper.onBeforeInsert(Trigger.New);
            CaseTriggerHelper.insertBusinessHours(Trigger.new);   
            CaseTriggerHelper.createContactUpdateCase(Trigger.new);
            CaseTriggerHelper.checkContactWithCaseEmail (Trigger.new);
           
        }
        if(Trigger.isAfter) {
            //handler.onAfterInsert(Trigger.New);
        
            //helper.onAfterInsert(Trigger.New, Trigger.NewMap);
            try{
                //helper.updateCounter(Trigger.new);
                 CaseTriggerHelper.omniChannelRouter(Trigger.new); //OMNI Channel
                 CaseTriggerHelper.sendUrgentCaseNotification(Trigger.new);//SLTECH-7979
            }
            catch(Exception e){
                trigger.new[0].addError('Error while creating case : '+e.getDMLMEssage(0));
            }
        }
        
    }
    else if(Trigger.isUpdate) {
        
        if(Trigger.isBefore) {
            
            //handler.onBeforeUpdate(Trigger.New, Trigger.OldMap);
            helper.onBeforeUpdate(Trigger.New, Trigger.OldMap);
            CaseTriggerHelper.showErrodOnOpenER(Trigger.new);
            CaseTriggerHelper.updateBusinessHours(Trigger.new, Trigger.OldMap);
            CaseTriggerHelper.mergedCaseOperations(Trigger.new);//SLTECH-6493
        }
        if(Trigger.isAfter) {
            
            //handler.onAfterUpdate(Trigger.NewMap, Trigger.OldMap);
            //helper.onAfterUpdate(Trigger.NewMap, Trigger.OldMap);
            CaseTriggerHelper.deletePSRs(Trigger.new,  Trigger.OldMap);
        }
    }*/
}