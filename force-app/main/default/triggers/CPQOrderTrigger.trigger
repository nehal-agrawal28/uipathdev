/**
* @author Gen Estrada
* @date 07/08/2020
* @description Simply Delegates all events to the handler.
*/

trigger CPQOrderTrigger on Order (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new CPQOrderTriggerHandler().run();
}