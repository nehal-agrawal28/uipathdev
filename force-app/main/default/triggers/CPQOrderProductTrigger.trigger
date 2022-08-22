/**
* @author Slalom
* @date 24/08/2020
* @description Delegates all events on Order Products to the handler class.
*/

trigger CPQOrderProductTrigger on OrderItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new CPQOrderProductTriggerHandler().run();
}