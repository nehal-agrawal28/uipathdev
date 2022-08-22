/**
    * @DESCRIPTION: Product Trigger Handle will hold all the trigger logic on the ProductTrigger
    * @AUTHOR: Slalom Consulting
*/
public with sharing class ProductTriggerHandler extends TriggerHandler {

    public override void beforeUpdate( ) {

        //Call the Sync Status Automation process. This method should always be called last in the "beforeUpdate" trigger
        IntegrationHandler.syncStatusAutomationProcess(trigger.oldMap, trigger.new);
    }
}