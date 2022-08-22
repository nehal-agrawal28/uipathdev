/**
* @author Girish Lakshmanan
* @date 18/03/2019
* @description Simply Delegates all events to the handler.
*/

trigger CPQOpportunityTrigger on Opportunity (before delete, after insert, after update, after delete, after undelete) {
    new CPQOptyTriggerHandler().run();
}